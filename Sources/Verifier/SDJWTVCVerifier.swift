/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Foundation
import X509
import JSONWebKey
import SwiftyJSON
import JSONWebSignature
import JSONWebToken

private let HTTPS_URI_SCHEME = "https"
private let DID_URI_SCHEME = "did"
private let SD_JWT_VC_TYPE = "vc+sd-jwt"

/**
 * A protocol to look up public keys from DIDs/DID URLs.
 */
public protocol LookupPublicKeysFromDIDDocument {
  /**
   * Asynchronously looks up public keys from a DID document based on a DID or DID URL.
   *
   * - Parameters:
   *   - did: The DID identifier.
   *   - didUrl: The DID URL (optional).
   * - Returns: An array of JWKs (public keys) or `nil` if the lookup fails.
   */
  func lookup(did: String, didUrl: String?) async throws -> [JWK]?
}


/**
 * A protocol defining methods for verifying SD-JWTs
 */
protocol SdJwtVcVerifierType {
  
  /**
   * Verifies the issuance of an SD-JWT from a serialized string.
   *
   * - Parameter unverifiedSdJwt: The unverified SD-JWT in string format.
   * - Returns: A `Result` containing either the verified `SignedSDJWT` or an error.
   */
  func verifyIssuance(
    unverifiedSdJwt: String
  ) async throws -> Result<SignedSDJWT, any Error>
  
  
  /**
   * Verifies the issuance of an SD-JWT from a `JSON` object.
   *
   * - Parameter unverifiedSdJwt: The unverified SD-JWT in `JSON` format.
   * - Returns: A `Result` containing either the verified `SignedSDJWT` or an error.
   */
  func verifyIssuance(
    unverifiedSdJwt: JSON
  ) async throws -> Result<SignedSDJWT, any Error>
  
  
  /**
   * Verifies the presentation of an SD-JWT from a serialized string.
   *
   * - Parameters:
   *   - unverifiedSdJwt: The unverified SD-JWT in string format.
   *   - claimsVerifier: The claims verifier to validate the claims.
   *   - keyBindingVerifier: An optional key binding verifier.
   * - Returns: A `Result` containing either the verified `SignedSDJWT` or an error.
   */
  func verifyPresentation(
    unverifiedSdJwt: String,
    claimsVerifier: ClaimsVerifier,
    keyBindingVerifier: KeyBindingVerifier?
  ) async throws -> Result<SignedSDJWT, any Error>
  
  
  /**
   * Verifies the presentation of an SD-JWT from a `JSON` object.
   * - Parameters:
   *   - unverifiedSdJwt: The unverified SD-JWT in `JSON` format.
   *   - claimsVerifier: The claims verifier to validate the claims.
   *   - keyBindingVerifier: An optional key binding verifier.
   * - Returns: A `Result` containing either the verified `SignedSDJWT` or an error.
   */
  func verifyPresentation(
    unverifiedSdJwt: JSON,
    claimsVerifier: ClaimsVerifier,
    keyBindingVerifier: KeyBindingVerifier?
  ) async throws -> Result<SignedSDJWT, any Error>
}

/**
  * Enum to represent the source of issuer keys for verification.
  * It can be one of the following:
  * - metadata: Fetch issuer metadata to get keys.
  * - x509: Use X.509 certificates for verification.
  * - did: Use DID URLs to look up keys.
 */
public enum VerificationMethod {
  case metadata(fetcher: SdJwtVcIssuerMetaDataFetching)
  case x509(trust: X509CertificateTrust)
  case did(lookup: LookupPublicKeysFromDIDDocument)
}

/**
 * A class for verifying SD-JWT Verifiable Credentials.
 * This class verifies SD-JWT VCs by validating the JWT's signatures and
 * using trust chains and metadata fetching.
 */
public class SDJWTVCVerifier: SdJwtVcVerifierType {
  
  /// Single property handling the source of issuer keys.
  private let verificationMethod: VerificationMethod
  
  /// A parser conforming to `ParserProtocol`, responsible for parsing SD-JWTs.
  private let parser: ParserProtocol
  
  /**
   * Initializes the `SDJWTVCVerifier` with dependencies for metadata fetching, certificate trust, and public key lookup.
   *
   * - Parameters:
   *   - parser: A parser responsible for parsing SD-JWTs.
   *   - verificationMethod: Enum to handle issuer key sources.
   *
   */
  public init(
    parser: ParserProtocol = CompactParser(),
    verificationMethod: VerificationMethod
  ) {
    self.parser = parser
    self.verificationMethod = verificationMethod
  }
  
  
  func verifyIssuance(
    unverifiedSdJwt: String
  ) async throws -> Result<SignedSDJWT, any Error> {
    let jws = try parser.getSignedSdJwt(serialisedString: unverifiedSdJwt).jwt
    let jwk = try await issuerJwsKeySelector(jws: jws)
    
    switch jwk {
    case .success(let jwk):
      return try SDJWTVerifier(
        parser: parser,
        serialisedString: unverifiedSdJwt
      ).verifyIssuance { jws in
        try SignatureVerifier(
          signedJWT: jws,
          publicKey: jwk
        )
      }
    case .failure(let error):
      throw error
    }
  }
  
  func verifyIssuance(
    unverifiedSdJwt: JSON
  ) async throws -> Result<SignedSDJWT, any Error> {
    
    guard
      let sdJwt = try SignedSDJWT(
        json: unverifiedSdJwt
      )
    else {
      throw SDJWTVerifierError.invalidJwt
    }
    
    let jws = sdJwt.jwt
    let jwk = try await issuerJwsKeySelector(jws: jws)
    
    switch jwk {
    case .success(let jwk):
      return try SDJWTVerifier(
        sdJwt: sdJwt
      ).verifyIssuance { jws in
        try SignatureVerifier(
          signedJWT: jws,
          publicKey: jwk
        )
      }
    case .failure(let error):
      throw error
    }
  }
  
  func verifyPresentation(
    unverifiedSdJwt: String,
    claimsVerifier: ClaimsVerifier,
    keyBindingVerifier: KeyBindingVerifier? = nil
  ) async throws -> Result<SignedSDJWT, any Error> {
    let jws = try parser.getSignedSdJwt(serialisedString: unverifiedSdJwt).jwt
    let jwk = try await issuerJwsKeySelector(jws: jws)
    
    switch jwk {
    case .success(let jwk):
      return try SDJWTVerifier(
        parser: parser,
        serialisedString: unverifiedSdJwt
      ).verifyPresentation { jws in
        try SignatureVerifier(
          signedJWT: jws,
          publicKey: jwk
        )
      } claimVerifier: { _, _ in
        claimsVerifier
      } keyBindingVerifier: { jws, jwk in
        try keyBindingVerifier?.verify(
          challenge: jws,
          extractedKey: jwk
        )
        return keyBindingVerifier
      }
    case .failure(let error):
      throw error
    }
  }
  
  func verifyPresentation(
    unverifiedSdJwt: JSON,
    claimsVerifier: ClaimsVerifier,
    keyBindingVerifier: KeyBindingVerifier?
  ) async throws -> Result<SignedSDJWT, any Error> {
    guard
      let sdJwt = try SignedSDJWT(
        json: unverifiedSdJwt
      )
    else {
      throw SDJWTVerifierError.invalidJwt
    }
    
    let jws = sdJwt.jwt
    let jwk = try await issuerJwsKeySelector(jws: jws)
    
    switch jwk {
    case .success(let jwk):
      return SDJWTVerifier(
        sdJwt: sdJwt
      ).verifyPresentation { jws in
        try SignatureVerifier(
          signedJWT: jws,
          publicKey: jwk
        )
      } claimVerifier: { _, _ in
        claimsVerifier
      } keyBindingVerifier: { jws, jwk in
        try keyBindingVerifier?.verify(
          challenge: jws,
          extractedKey: jwk
        )
        return keyBindingVerifier
      }
    case .failure(let error):
      throw error
    }
  }
}


private extension SDJWTVCVerifier {
  
  /**
   * Selects the issuer's public key from the JWS object based on metadata, X.509 certificates, or DID URLs.
   *
   * - Parameters:
   *   - jws: The JSON Web Signature object.
   * - Returns: A `Result` containing either the selected `JWK` or an error.
   */
  func issuerJwsKeySelector(
    jws: JWS
  ) async throws -> Result<JWK, any Error> {
    
    guard jws.protectedHeader.algorithm != nil else {
      return .failure(SDJWTVerifierError.noAlgorithmProvided)
    }
    
    guard let source = try keySource(
      jws: jws,
      verificationMethod: verificationMethod) else {
      return .failure(SDJWTVerifierError.invalidJwt)
    }
    
    switch source {
    case .metadata(let iss, let kid, let fetcher):
      guard let jwk = try await fetcher.fetchIssuerMetaData(
        issuer: iss
      )?.jwks.first(where: { $0.keyID == kid }) else {
        return .failure(SDJWTVerifierError.invalidJwk)
      }
      return .success(jwk)
      
    case .x509CertChain(_, let chain, let trust):
      if await trust.isTrusted(chain: chain) {
        guard let jwk = try chain
          .first?
          .publicKey
          .serializeAsPEM()
          .pemString
          .pemToSecKey()?
          .jwk else {
          return .failure(
            SDJWTVerifierError.invalidJwt
          )
        }
        return .success(jwk)
      }
      return .failure(
        SDJWTVerifierError.invalidJwt
      )
      
    case .didUrl(let iss, let kid, let lookup):
      guard let key = try await lookup.lookup(
        did: iss,
        didUrl: kid
      )?.first(where: { $0.keyID == kid }) else {
        return .failure(
          SDJWTVerifierError.invalidJwt
        )
      }
      return .success(key)
    }
  }
  
  /**
   * Determines the source of the issuer's public key from the JWS object.
   *
   * - Parameter jws: The JSON Web Signature object.
   * - Returns: An optional `SdJwtVcIssuerPublicKeySource` object.
   */
  func keySource(jws: JWS, verificationMethod: VerificationMethod) throws -> SdJwtVcIssuerPublicKeySource? {
    
    guard let iss = try? jws.iss() else {
      throw SDJWTVerifierError.invalidIssuer
    }
    
    guard let issUrl = URL(string: iss) else {
      return nil
    }
    
    switch verificationMethod {
    case .metadata(let fetcher):
      return .metadata(
        iss: issUrl,
        kid: jws.protectedHeader.keyID,
        fetcher: fetcher
      )
    case .x509(let trust):
      let certChain = parseCertificates(from: jws.protectedHeaderData)
      let leaf = certChain.first
      
      guard isIssuerFQDNContained(in: leaf, issuerUrl: issUrl) || isIssuerURIContained(in: leaf, iss: iss)
      else {
        return nil
      }
      return .x509CertChain(
        iss: issUrl,
        chain: certChain,
        trust: trust
      )
      
    case .did(lookup: let lookup):
      return .didUrl(
        iss: iss,
        kid: jws.protectedHeader.keyID,
        loukup: lookup
      )
    }
  }
  
  private func isIssuerFQDNContained(in leaf: Certificate?, issuerUrl: URL) -> Bool {
    // Get the host from the issuer URL
    guard let issuerFQDN = issuerUrl.host else {
      return false
    }
    
    // Extract the DNS names from the certificate's subject alternative names
    let dnsNames = try? leaf?.extensions
      .subjectAlternativeNames?
      .rawSubjectAlternativeNames()
    
    // Check if any of the DNS names match the issuer FQDN
    let contains = dnsNames?.contains(where: { $0 == issuerFQDN }) ?? false
    
    return contains
  }
  
  func isIssuerURIContained(in leaf: Certificate?, iss: String) -> Bool {
    // Extract the URIs from the certificate's subject alternative names
    let uris = try? leaf?
      .extensions
      .subjectAlternativeNames?
      .rawUniformResourceIdentifiers()
    
    // Check if any of the URIs match the 'iss' string
    let contains = uris?.contains(where: { $0 == iss }) ?? false
    
    return contains
  }
}
