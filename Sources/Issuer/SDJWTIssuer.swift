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

  var claimSet: ClaimSet
  var kbJwt: JSON?

//  let key = SecKey.representing(rsaPublicKeyComponents: RSAPublicKeyComponents)
//  let signer = Signer(signingAlgorithm: .ES256, key: .init(base64URLEncoded: ""))

  init(claimSet: ClaimSet) {
    self.claimSet = claimSet
  }

  func createSignedJWT() throws {
    let header = JWSHeader(algorithm: .ES256)

    guard let payloadData = self.serialize(kbJwt: kbJwt) else {
      throw SDJWTError.serializationError
    }
    let payload = Payload(payloadData)
  }

  func serialize(kbJwt: JSON?) -> Data? {
    let output =
    claimSet.value.stringValue + "~" +
    claimSet.disclosures.reduce(into: "", { partialResult, disclosure in
      partialResult += disclosure + "~"
    })
    return output.data(using: .utf8)
  }
}
