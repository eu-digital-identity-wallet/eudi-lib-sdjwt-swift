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
import JOSESwift
import SwiftyJSON

class SDJWTIssuer {

  enum Purpose {
    case issuance(JWSHeader, ClaimSet)
    case presentation(SignedSDJWT, KBJWTContent?)
  }

  // MARK: - Lifecycle

  private init() {}

  // MARK: - Methods

  static func createSDJWT<KeyType>(purpose: Purpose, signingKey: KeyType) throws -> SignedSDJWT {
    switch purpose {
    case .issuance(let JWSHeader, let claimSet):
      let ungsingedSDJWT = try SDJWT(header: JWSHeader, claimSet: claimSet)
      return try createSignedSDJWT(sdJwt: ungsingedSDJWT, issuersPrivateKey: signingKey)
      // ..........
    case .presentation(let signedJWT, let kbJWTContent):
      if let kbJWTContent {

        let payload = try kbJWTContent.payload.rawData()
        let kbJwt = try JWT(header: kbJWTContent.header, payload: payload)
        return try createKeyBondedSDJWT(signedSDJWT: signedJWT, kbJWT: kbJwt, holdersPrivateKey: signingKey)
      }
      return signedJWT
      // ..........
    }

  }

  private static func createSignedSDJWT<KeyType>(sdJwt: SDJWT, issuersPrivateKey: KeyType) throws -> SignedSDJWT {
    try SignedSDJWT.nonKeyBondedSDJWT(sdJwt: sdJwt, issuersPrivateKey: issuersPrivateKey)
  }

  private static func createKeyBondedSDJWT<KeyType>(signedSDJWT: SignedSDJWT, kbJWT: JWT, holdersPrivateKey: KeyType) throws -> SignedSDJWT {
    try SignedSDJWT.keyBondedSDJWT(signedSDJWT: signedSDJWT, kbJWT: kbJWT, holdersPrivateKey: holdersPrivateKey)
  }

}
