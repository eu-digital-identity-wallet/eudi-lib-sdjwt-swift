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
import SwiftyJSON
import JSONWebSignature
import JSONWebKey

typealias DisclosuresPerClaim = Dictionary<JSONPointer, [Disclosure]>

public struct SignedSDJWT {
  
  // MARK: - Properties
  
  public let jwt: JWS
  public internal(set) var disclosures: [Disclosure]
  public internal(set) var kbJwt: JWS?
  public internal(set) var claimSet: JSON
  
  var delineatedCompactSerialisation: String {
    let separator = "~"
    let input = ([jwt.compactSerialization] + disclosures).reduce("") { $0.isEmpty ? $1 : $0 + separator + $1 } + separator
    return DigestCreator()
      .hashAndBase64Encode(
        input: input
      ) ?? ""
  }
  
  // MARK: - Lifecycle
  
  init(
    serializedJwt: String,
    disclosures: [Disclosure],
    serializedKbJwt: String? = nil
  ) throws {
    self.jwt = try JWS(jwsString: serializedJwt)
    self.disclosures = disclosures
    self.kbJwt = try? JWS(jwsString: serializedKbJwt ?? "")
    self.claimSet = try jwt.payloadJSON()
  }
  
  init?(json: JSON) throws {
    let triple = try JwsJsonSupport.parseJWSJson(unverifiedSdJwt: json)
    self.jwt = triple.jwt
    self.disclosures = triple.disclosures
    self.kbJwt = triple.kbJwt
    self.claimSet = try jwt.payloadJSON()
  }
  
  private init?<KeyType>(
    sdJwt: SDJWT,
    issuersPrivateKey: KeyType
  ) throws {
    // Create a Signed SDJWT with no key binding
    guard let signedJwt = try? SignedSDJWT.createSignedJWT(key: issuersPrivateKey, jwt: sdJwt.jwt) else {
      return nil
    }
    self.jwt = signedJwt
    self.disclosures = sdJwt.disclosures
    self.kbJwt = nil
    self.claimSet = try jwt.payloadJSON()
  }
  
  private init?<KeyType>(
    signedSDJWT: SignedSDJWT,
    kbJWT: JWT,
    holdersPrivateKey: KeyType
  ) throws {
    // Assume that we have a valid signed jwt from the issuer
    // And key exchange has been established
    // signed SDJWT might contain or not the cnf claim
    
    self.jwt = signedSDJWT.jwt
    self.disclosures = signedSDJWT.disclosures
    let signedKBJwt = try? SignedSDJWT.createSignedJWT(key: holdersPrivateKey, jwt: kbJWT)
    self.kbJwt = signedKBJwt
    self.claimSet = try jwt.payloadJSON()
  }
  
  // MARK: - Methods
  
  // expose static func initializers to distinguish between 2 cases of
  // signed SDJWT creation
  
  static func nonKeyBondedSDJWT<KeyType>(sdJwt: SDJWT, issuersPrivateKey: KeyType) throws -> SignedSDJWT {
    try .init(sdJwt: sdJwt, issuersPrivateKey: issuersPrivateKey) ?? {
      throw SDJWTVerifierError.invalidJwt
    }()
  }
  
  static func keyBondedSDJWT<KeyType>(signedSDJWT: SignedSDJWT, kbJWT: JWT, holdersPrivateKey: KeyType) throws -> SignedSDJWT {
    try .init(signedSDJWT: signedSDJWT, kbJWT: kbJWT, holdersPrivateKey: holdersPrivateKey) ?? {
      throw SDJWTVerifierError.invalidJwt
    }()
  }
  
  private static func createSignedJWT<KeyType>(key: KeyType, jwt: JWT) throws -> JWS {
    try jwt.sign(key: key)
  }
  
  func disclosuresToPresent(disclosures: [Disclosure]) -> Self {
    var updated = self
    updated.disclosures = disclosures
    return updated
  }
  
  func toSDJWT() throws -> SDJWT {
    if let kbJwtHeader = kbJwt?.protectedHeader,
       let kbJWtPayload = try? kbJwt?.payloadJSON() {
      return try SDJWT(
        jwt: JWT(header: jwt.protectedHeader, payload: jwt.payloadJSON()),
        disclosures: disclosures,
        kbJWT: JWT(header: kbJwtHeader, kbJwtPayload: kbJWtPayload))
    }
    
    return try SDJWT(
      jwt: JWT(header: jwt.protectedHeader, payload: jwt.payloadJSON()),
      disclosures: disclosures,
      kbJWT: nil)
  }
  
  func extractHoldersPublicKey() throws -> JWK {
    let payloadJson = try self.jwt.payloadJSON()
    let jwk = payloadJson[Keys.cnf]["jwk"]
    
    guard jwk.exists() else {
      throw SDJWTVerifierError.keyBindingFailed(description: "Failled to find holders public key")
    }
    
    guard let jwkObject = try? JSONDecoder.jwt.decode(JWK.self, from: jwk.rawData()) else {
      throw SDJWTVerifierError.keyBindingFailed(description: "failled to extract key type")
    }
    
    return jwkObject
  }
}

public extension SignedSDJWT {
  
  func serialised(serialiser: (SignedSDJWT) -> (SerialiserProtocol)) throws -> Data {
    serialiser(self).data
  }
  
  func serialised(serialiser: (SignedSDJWT) -> (SerialiserProtocol)) throws -> String {
    serialiser(self).serialised
  }
  
  func recreateClaims() throws -> ClaimExtractorResult {
    return try self.toSDJWT().recreateClaims()
  }
  
  func asJwsJsonObject(
    option: JwsJsonSupportOption = .flattened,
    kbJwt: JWTString?,
    getParts: (JWTString) throws -> (String, String, String)
  ) throws -> JSON {
    let (protected, payload, signature) = try getParts(jwt.compactSerialization)
    return option.buildJwsJson(
      protected: protected,
      payload: payload,
      signature: signature,
      disclosures: Set(disclosures),
      kbJwt: kbJwt
    )
  }
  
  func present(query: Set<JSONPointer>) async throws -> SignedSDJWT? {
    return try await present(
      query: { jsonPointer in
        return query.contains(jsonPointer)
      }
    )
  }
  
  func present(
    query: (JSONPointer) -> Bool
  ) async throws -> SignedSDJWT? {
    let (_, disclosuresPerClaim) = try recreateClaimsAndDisclosuresPerClaim()
    let keys = disclosuresPerClaim.keys.filter(query)
    if keys.isEmpty {
      return nil
    } else {
      let disclosures = Set(
        disclosuresPerClaim
          .filter {
            keys.contains($0.key)
          }
          .values
          .flatMap { $0 }
      )
      return try SignedSDJWT(
        serializedJwt: jwt.compactSerialization,
        disclosures: Array(disclosures)
      )
    }
  }
}

private extension SignedSDJWT {
  func recreateClaimsAndDisclosuresPerClaim() throws -> (JSON, DisclosuresPerClaim) {
    
    let claims = try recreateClaims()
    print(claims)
    
    return (JSON.empty, [:])
  }
}

public protocol ClaimVisitor {
  func call(pointer: JSONPointer, disclosure: Disclosure?)
  func call(key: String, disclosure: Disclosure?)
}

public class Visitor: ClaimVisitor {
  
  public init() {
  }
  
  public func call(pointer: JSONPointer, disclosure: Disclosure?) {
    print("Visitor")
  }
  
  public func call(key: String, disclosure: Disclosure?) {
    print("Visitor: \(key) \(disclosure ?? "N/A")")
  }
}
