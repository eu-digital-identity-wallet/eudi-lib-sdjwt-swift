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

public protocol X509CertificateTrust {
  func isTrusted(chain: [Certificate]) async -> Bool
}

struct X509CertificateTrustNone: X509CertificateTrust {
  func isTrusted(chain: [Certificate]) async -> Bool {
    return false
  }
}

public struct X509CertificateTrustFactory {
  public static let none: X509CertificateTrust = X509CertificateTrustNone()
}

/**
 * A protocol to look up public keys from DIDs/DID URLs.
 */
public protocol LookupPublicKeysFromDIDDocument {
  func lookup(did: String, didUrl: String?) async -> [JWK]?
}

protocol SdJwtVcVerifierType {
  func verifyIssuance(
    unverifiedSdJwt: String
  ) async throws -> Result<SignedSDJWT, any Error>
  func verifyIssuance(
    unverifiedSdJwt: JSON
  ) async throws -> Result<SignedSDJWT, any Error>
}

public class SDJWTVCVerifier: SdJwtVcVerifierType {
  
  private let trust: X509CertificateTrust
  private let lookup: LookupPublicKeysFromDIDDocument?
  private let fetcher: any SdJwtVcIssuerMetaDataFetching
  
  public init(
    fetcher: SdJwtVcIssuerMetaDataFetching = SdJwtVcIssuerMetaDataFetcher(
      urlSession: .shared
    ),
    trust: X509CertificateTrust = X509CertificateTrustFactory.none,
    lookup: LookupPublicKeysFromDIDDocument? = nil
  ) {
    self.fetcher = fetcher
    self.trust = trust
    self.lookup = lookup
  }
  
  func verifyIssuance(
    unverifiedSdJwt: String
  ) async throws -> Result<SignedSDJWT, any Error> {
    let parser = CompactParser(serialisedString: unverifiedSdJwt)
    let jws = try parser.getSignedSdJwt().jwt
    let jwk = try await issuerJwsKeySelector(
      jws: jws,
      trust: trust,
      lookup: lookup
    )
    
    switch jwk {
    case .success(let jwk):
      return try SDJWTVerifier(
        parser: CompactParser(
          serialisedString: unverifiedSdJwt
        )
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
}

private extension SDJWTVCVerifier {
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
        return .failure(SDJWTVerifierError.invalidJwt)
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
      guard let key = await lookup?.lookup(
        did: iss,
        didUrl: kid
      )?.first(where: { $0.keyID == kid }) else {
        return .failure(SDJWTVerifierError.invalidJwt)
      }
      return .success(key)
    }
  }
  
  func keySource(jws: JWS) throws -> SdJwtVcIssuerPublicKeySource? {
    let kid = jws.protectedHeader.keyID
    let certChain = try [Certificate(pemEncoded: jws.protectedHeader.x509CertificateChain!)]
    let payload = jws.payload
    let json = try JSON(data: payload)
    
    guard let iss = json["iss"].string else {
      throw SDJWTVerifierError.invalidIssuer
    }
    
    let issUrl = URL(string: iss)
    let issScheme = issUrl?.scheme
    
    if issScheme == HTTPS_URI_SCHEME && certChain.isEmpty {
      guard let issUrl = issUrl else {
        return nil
      }
      return .metadata(
        iss: issUrl,
        kid: kid
      )
    } else if issScheme == HTTPS_URI_SCHEME {
      guard let issUrl = issUrl else {
        return nil
      }
      return .x509CertChain(
        iss: issUrl,
        chain: certChain
      )
    } else if issScheme == DID_URI_SCHEME && certChain.isEmpty {
      return .didUrl(
        iss: iss,
        kid: kid
      )
    }
    return nil
  }
}
