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

typealias KBJWT = JWT

struct SDJWT {

  // MARK: - Properties

  var jwt: JWT
  var disclosures: [Disclosure]
  var kbJwt: JWT?

  // MARK: - Lifecycle

  init(jwt: JWT, disclosures: [Disclosure], kbJWT: KBJWT?) throws {
    self.jwt = jwt
    self.disclosures = disclosures
    self.kbJwt = kbJWT
  }
}

struct SignedSDJWT {

  // MARK: - Properties

  var jwt: JWS
  var disclosures: [Disclosure]
  var kbJwt: JWS?

  // MARK: - Lifecycle

  init(serializedJwt: String,
       disclosures: [Disclosure],
       serializedKbJwt: String?) throws {
    self.jwt = try JWS(compactSerialization: serializedJwt)
    self.disclosures = disclosures
    self.kbJwt = try? JWS(compactSerialization: serializedKbJwt ?? "")
  }

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
      throw SDJWTVerifierError.invalidJwt
    }()
  }

  static func keyBondedSDJWT<KeyType>(signedSDJWT: SignedSDJWT, kbJWT: JWT, holdersPrivateKey: KeyType) throws -> SignedSDJWT {
    try .init(signedSDJWT: signedSDJWT, kbJWT: kbJWT, holdersPrivateKey: holdersPrivateKey) ?? {
      throw SDJWTVerifierError.invalidJwt
    }()
  }

  private static func createSignedJWT<KeyType>(jwsController: JWSController<KeyType>, jwt: JWT) throws -> JWS {
    try jwt.sign(signer: jwsController.signer)
  }

  func disclosuresToPresent(disclosures: [Disclosure]) -> Self {
    var updated = self
    updated.disclosures = disclosures
    return updated
  }

  func toSDJWT() throws -> SDJWT {
    if let kbJwtHeader = kbJwt?.header,
       let kbJWtPayload = try? kbJwt?.payloadJSON() {
      return try SDJWT(
        jwt: JWT(header: jwt.header, payload: jwt.payloadJSON()),
        disclosures: disclosures,
        kbJWT: JWT(header: kbJwtHeader, kbJwtPayload: kbJWtPayload))
    }

    return try SDJWT(
      jwt: JWT(header: jwt.header, payload: jwt.payloadJSON()),
      disclosures: disclosures,
      kbJWT: nil)
  }

}

extension SignedSDJWT {
  func serialised(serialiser: (SignedSDJWT) -> (SerialiserProtocol)) throws -> Data {
    serialiser(self).data
  }

  func serialised(serialiser: (SignedSDJWT) -> (SerialiserProtocol)) throws -> String {
    serialiser(self).serialised
  }
}
