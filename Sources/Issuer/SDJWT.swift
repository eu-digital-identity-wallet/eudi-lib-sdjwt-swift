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
import JOSESwift

typealias KBJWTContent = (header: KBJWTHeader, payload: KBJWTPayload)
typealias KBJWTHeader = JWSHeader
typealias KBJWTPayload = JSON

struct SDJWT {

  var jwt: JWT
  var disclosures: [Disclosure]
  var kbJwt: JWT?

  init(header: JWSHeader, claimSet: ClaimSet) throws {
    self.jwt = try .init(header: header, payload: claimSet.value.rawData())
    self.disclosures = claimSet.disclosures
  }

  init(header: JWSHeader, claimSet: ClaimSet, kbJwtHeader: KBJWTHeader, KBJWTBody: KBJWTPayload) throws {
    try self.init(header: header, claimSet: claimSet)
    self.kbJwt = try JWT.KBJWT(header: kbJwtHeader, KBJWTBody: KBJWTBody)
  }

}

struct SignedSDJWT {

  var jwt: JWS
  var disclosures: [Disclosure]
  var kbJwt: JWS?
  
  // MARK: - Lifecycle

  private init?<KeyType>(sdJwt: SDJWT, issuersPrivateKey: KeyType) {
    // Create a Signed SDJWT with no key binding
    guard let signingAlgorithm = sdJwt.jwt.header.algorithm,
          let signedJwt = try? SignedSDJWT.createSignedJWT(jwsController: .init(signingAlgorithm: signingAlgorithm, privateKey: issuersPrivateKey), jwt: sdJwt.jwt)
    else {
      return nil
    }

    self.jwt = signedJwt
    self.disclosures = sdJwt.disclosures
    self.kbJwt = nil
  }

  private init?<KeyType>(signedSDJWT: SignedSDJWT, kbJWT: JWT, holdersPrivateKey: KeyType) {
    // Assume that we have a valid signed jwt from the issuer
    // And key exchange has been established
    // signed SDJWT might contain or not the cnf claim
    self.jwt = signedSDJWT.jwt
    self.disclosures = signedSDJWT.disclosures

    guard let signingAlgorithm = kbJWT.header.algorithm,
          let signedKBJwt = try? SignedSDJWT.createSignedJWT(jwsController: .init(signingAlgorithm: signingAlgorithm, privateKey: holdersPrivateKey), jwt: kbJWT)
    else {
      return nil
    }
    self.kbJwt = signedKBJwt
  }

  // MARK: - Methods

  // expose static func initializers to distinguish between 2 cases of
  // signed SDJWT creation

  static func nonKeyBondedSDJWT<KeyType>(sdJwt: SDJWT, issuersPrivateKey: KeyType) throws -> SignedSDJWT {
    try .init(sdJwt: sdJwt, issuersPrivateKey: issuersPrivateKey) ?? {
      throw SDJWTError.serializationError
    }()
  }

  static func keyBondedSDJWT<KeyType>(signedSDJWT: SignedSDJWT, kbJWT: JWT, holdersPrivateKey: KeyType) throws -> SignedSDJWT {
    try .init(signedSDJWT: signedSDJWT, kbJWT: kbJWT, holdersPrivateKey: holdersPrivateKey) ?? {
      throw SDJWTError.serializationError
    }()
  }

  private static func createSignedJWT<KeyType>(jwsController: JWSController<KeyType>, jwt: JWT) throws -> JWS {
    try jwt.sign(signer: jwsController.signer)
  }
}
