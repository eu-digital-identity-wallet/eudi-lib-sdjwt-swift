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

class SDJWTIssuer<SecKey> {

  // MARK: - Properties

  var claimSet: ClaimSet
  var kbJwt: KBJWT?

  let jwsController: JWSController<SecKey>

  enum Purpose {
    case issuance(ClaimSet)
    case presentation(ClaimSet, KBJWT?)
  }

  // MARK: - Lifecycle

  init(purpose: Purpose, jwsController: JWSController<SecKey>) {
    switch purpose {
    case .issuance(let claimSet):
      self.claimSet = claimSet
      self.kbJwt = nil
      // ..........
    case .presentation(let claimSet, let kbJwt):
      self.claimSet = claimSet
      self.kbJwt = kbJwt
      // ..........
    }

    self.jwsController = jwsController
  }

  // MARK: - Methods

  func createSignedJWT() throws -> JWS {
    let header = JWSHeader(algorithm: jwsController.signatureAlgorithm)
    let payload = try Payload(claimSet.value.rawData())
    let signer = jwsController.signer

    guard let jws = try? JWS(header: header, payload: payload, signer: signer) else {
      throw SDJWTError.serializationError
    }

    return jws
  }

  func serialize(jws: JWS) -> Data? {
    let jwsString = jws.compactSerializedString
    let disclosures = claimSet.disclosures.reduce(into: "") { partialResult, disclosure in
      partialResult += "~\(disclosure)"
    }

    let kbJwtString = "~" + (self.kbJwt?.compactSerializedString ?? "")

    let output = jwsString + disclosures + kbJwtString
    return output.data(using: .utf8)
  }

  // TODO: Revisit Logic of who handles the signing 
  func createKBJWT() throws -> KBJWT {
    let header = JWSHeader(algorithm: .ES256)
    let payload = Payload(Data())
    let signer = jwsController.signer
    let jws = try JWS(header: header, payload: payload, signer: signer)

    return jws
  }
}
