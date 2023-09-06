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

enum SerialisationFormat {
  case serialised
}

class Parser {
  // MARK: - Properties

  var serialisedString: String
  var serialisationFormat: SerialisationFormat
  // MARK: - Lifecycle

  init(serialisedString: String, serialisationFormat: SerialisationFormat) {
    self.serialisedString = serialisedString
    self.serialisationFormat = serialisationFormat
  }
  // MARK: - Methods

  func getSdJwt() throws -> SDJWT {
    let (serialisedJWT, dislosuresInBase64, serialisedKBJWT) = self.parseCombined()
    return try parseSDJWT(serialisedJWT: serialisedJWT, dislosuresInBase64: dislosuresInBase64, serialisedKBJWT: serialisedKBJWT)
  }

  func getSignedSdJwt() throws -> SignedSDJWT {
    let (serialisedJWT, dislosuresInBase64, serialisedKBJWT) = self.parseCombined()
    return try SignedSDJWT(serializedJwt: serialisedJWT, disclosures: dislosuresInBase64, serializedKbJwt: serialisedKBJWT)
  }

  private func parseSDJWT(serialisedJWT: String, dislosuresInBase64: [Disclosure], serialisedKBJWT: String?) throws -> SDJWT {
    let jws = try JWS(compactSerialization: serialisedJWT)

    let disclosures = dislosuresInBase64
      .compactMap({$0.base64URLDecode()})

    let jwt = try JWT(header: jws.header, payload: jws.payloadJSON())

    guard let serialisedKBJWT, let kbJWS = try? JWS(compactSerialization: serialisedKBJWT) else {
      return try SDJWT(jwt: jwt, disclosures: disclosures, kbJWT: nil)
    }

    let kbJWT = try JWT(header: kbJWS.header, kbJwtPayload: kbJWS.payloadJSON())

    return try SDJWT(jwt: jwt, disclosures: disclosures, kbJWT: kbJWT)
  }

  private func parseCombined() -> (String, [Disclosure], String?) {
    let parts = self.serialisedString.split(separator: "~")
    let jwt = String(parts[0])

    switch self.serialisationFormat {
    case .serialised:
      if parts.last?.hasSuffix("~") == true {
        // means no key binding is present
        let disclosures = parts[safe: 1..<parts.count]?.compactMap({String($0)})

        return (jwt, disclosures ?? [], nil)
      } else {
        // means we have key binding jwt
        let disclosures = parts[safe: 1..<parts.count-1]?.compactMap({String($0)})
        let kbJwt = String(parts[parts.count - 1])
        return (jwt, disclosures ?? [], kbJwt)
      }

    }

  }
}

