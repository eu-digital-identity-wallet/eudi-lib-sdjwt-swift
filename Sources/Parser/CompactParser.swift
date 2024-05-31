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

public enum SerialisationFormat {
  case serialised
  case envelope
}

public class CompactParser: ParserProtocol {

  // MARK: - Properties

  var serialisedString: String
  var serialisationFormat: SerialisationFormat = .serialised
  // MARK: - Lifecycle

  public required init(serialiserProtocol: SerialiserProtocol) {
    self.serialisedString = serialiserProtocol.serialised
  }

  public init(serialisedString: String) {
    self.serialisedString = serialisedString
  }

  // MARK: - Methods

  public func getSignedSdJwt() throws -> SignedSDJWT {
    let (serialisedJWT, disclosuresInBase64, serialisedKBJWT) = try self.parseCombined()
    return try SignedSDJWT(serializedJwt: serialisedJWT, disclosures: disclosuresInBase64, serializedKbJwt: serialisedKBJWT)
  }

  private func parseCombined() throws -> (String, [Disclosure], String?) {
    let parts = self.serialisedString
      .split(separator: "~")
      .map {String($0)}
    guard parts.count > 1 else {
      throw SDJWTVerifierError.parsingError
    }
    let jwt = String(parts[0])
      if serialisedString.hasSuffix("~") == true {
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
