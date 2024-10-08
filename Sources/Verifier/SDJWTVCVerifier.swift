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
@preconcurrency import JSONWebKey
@preconcurrency import SwiftyJSON
import JSONWebSignature
import JSONWebToken

private let HTTPS_URI_SCHEME = "https"
private let DID_URI_SCHEME = "did"
private let SD_JWT_VC_TYPE = "vc+sd-jwt"

extension JSON: @unchecked @retroactive Sendable { }

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
  @MainActor func lookup(did: String, didUrl: String?) async throws -> [JWK]?
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
  
  func verifyPresentation(
    unverifiedSdJwt: String,
    claimsVerifier: ClaimsVerifier,
    keyBindingVerifier: KeyBindingVerifier?
  ) async throws -> Result<SignedSDJWT, any Error>
  
  func verifyPresentation(
    unverifiedSdJwt: JSON,
    claimsVerifier: ClaimsVerifier,
    keyBindingVerifier: KeyBindingVerifier?
  ) async throws -> Result<SignedSDJWT, any Error>
}

/**
 * A class for verifying SD-JWT Verifiable Credentials.
 * This class verifies SD-JWT VCs by validating the JWT's signatures and
 * using trust chains and metadata fetching.
 */
public class SDJWTVCVerifier: SdJwtVcVerifierType {
  
  /// X.509 certificate trust configuration used for verifying certificates.
  private let trust: X509CertificateTrust
  
  /// Optional service for fetching public keys from DID documents.
  private let lookup: LookupPublicKeysFromDIDDocument?
  
  /// Service for fetching issuer metadata such as public keys.
  private let fetcher: any SdJwtVcIssuerMetaDataFetching
  
  /// A parser conforming to `ParserProtocol`, responsible for parsing SD-JWTs.
  private let parser: ParserProtocol
  
  /**
   * Initializes the `SDJWTVCVerifier` with dependencies for metadata fetching, certificate trust, and public key lookup.
   *
   * - Parameters:
   *   - parser: A parser responsible for parsing SD-JWTs.
   *   - fetcher: A service responsible for fetching issuer metadata.
   *   - trust: The X.509 trust configuration.
   *   - lookup: Optional service for looking up public keys from DIDs or DID URLs.
   */
  public init(
    parser: ParserProtocol = CompactParser(),
    fetcher: SdJwtVcIssuerMetaDataFetching = SdJwtVcIssuerMetaDataFetcher(
      session: URLSession.shared
    ),
    trust: X509CertificateTrust,// = X509CertificateTrustFactory.none,
    lookup: LookupPublicKeysFromDIDDocument? = nil
  ) {
    self.parser = parser
    self.fetcher = fetcher
    self.trust = trust
    self.lookup = lookup
  }
  
  /**
   * Verifies the issuance of an SD-JWT VC.
   *
   * - Parameter unverifiedSdJwt: The unverified SD-JWT in string format.
   * - Returns: A `Result` containing either the verified `SignedSDJWT` or an error.
   */
  @MainActor
  func verifyIssuance(
    unverifiedSdJwt: String
  ) async throws -> Result<SignedSDJWT, any Error> {
    let jws = try parser.getSignedSdJwt(serialisedString: unverifiedSdJwt).jwt
    let jwk = try await issuerJwsKeySelector(
      jws: jws,
      trust: trust,
      lookup: lookup
    )
    
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
  
  /**
   * Verifies the issuance of an SD-JWT VC.
   *
   * - Parameter unverifiedSdJwt: The unverified SD-JWT in `JSON` format.
   * - Returns: A `Result` containing either the verified `SignedSDJWT` or an error.
   */
  @MainActor
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
    let lookup = self.lookup
    
    let jwk = try await issuerJwsKeySelector(
      jws: jws,
      trust: trust,
      lookup: lookup
    )
    
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
  
  @MainActor
  func verifyPresentation(
    unverifiedSdJwt: String,
    claimsVerifier: ClaimsVerifier,
    keyBindingVerifier: KeyBindingVerifier? = nil
  ) async throws -> Result<SignedSDJWT, any Error> {
    let jws = try parser.getSignedSdJwt(serialisedString: unverifiedSdJwt).jwt
    let jwk = try await issuerJwsKeySelector(
      jws: jws,
      trust: trust,
      lookup: lookup
    )
    
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
  
  @MainActor
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
    let jwk = try await issuerJwsKeySelector(
      jws: jws,
      trust: trust,
      lookup: lookup
    )
    
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
   *   - trust: The X.509 trust configuration.
   *   - lookup: Optional service for looking up public keys from DID documents.
   * - Returns: A `Result` containing either the selected `JWK` or an error.
   */
  @MainActor
  func issuerJwsKeySelector(
    jws: JWS,
    trust: X509CertificateTrust,
    lookup: LookupPublicKeysFromDIDDocument?
  ) async throws -> Result<JWK, any Error> {
    
    guard jws.protectedHeader.algorithm != nil else {
      throw SDJWTVerifierError.noAlgorithmProvided
    }
    
    guard let source = try keySource(jws: jws) else {
      return .failure(SDJWTVerifierError.invalidJwt)
    }
    
    switch source {
    case .metadata(let iss, let kid):
      guard let jwk = try await fetcher.fetchIssuerMetaData(
        issuer: iss
      )?.jwks.first(where: { $0.keyID == kid }) else {
        return .failure(SDJWTVerifierError.invalidJwk)
      }
      return .success(jwk)
      
    case .x509CertChain(_, let chain):
      if await trust.isTrusted(chain: chain) {
        guard let jwk = try chain
          .first?
          .publicKey
          .serializeAsPEM()
          .pemString
          .pemToSecKey()?
          .jwk else {
          return .failure(SDJWTVerifierError.invalidJwt)
        }
        return .success(jwk)
      }
      return .failure(SDJWTVerifierError.invalidJwt)
    case .didUrl(let iss, let kid):
      guard let key = try await lookup?.lookup(
        did: iss,
        didUrl: kid
      )?.first(where: { $0.keyID == kid }) else {
        return .failure(SDJWTVerifierError.invalidJwt)
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
  func keySource(jws: JWS) throws -> SdJwtVcIssuerPublicKeySource? {
    
    guard let iss = try? jws.iss() else {
      throw SDJWTVerifierError.invalidIssuer
    }
    
    let certChain = parseCertificates(from: jws.protectedHeaderData)
    let leaf = certChain.first
    
    let issUrl = URL(string: iss)
    let issScheme = issUrl?.scheme
    
    if issScheme == HTTPS_URI_SCHEME && certChain.isEmpty {
      guard let issUrl = issUrl else {
        return nil
      }
      return .metadata(
        iss: issUrl,
        kid: jws.protectedHeader.keyID
      )
    } else if issScheme == HTTPS_URI_SCHEME {
      guard
        let issUrl = issUrl,
        isIssuerFQDNContained(in: leaf, issuerUrl: issUrl) || isIssuerURIContained(in: leaf, iss: iss)
      else {
        return nil
      }
      
      return .x509CertChain(
        iss: issUrl,
        chain: certChain
      )
    } else if issScheme == DID_URI_SCHEME && certChain.isEmpty {
      return .didUrl(
        iss: iss,
        kid: jws.protectedHeader.keyID
      )
    }
    return nil
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
