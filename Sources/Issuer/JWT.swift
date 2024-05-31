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
import JSONWebAlgorithms
import JSONWebSignature
import SwiftyJSON

public struct JWT: JWTRepresentable {

  // MARK: - Properties

  var header: JWSRegisteredFieldsHeader
  var payload: JSON

  // MARK: - Lifecycle

  public init(header: JWSRegisteredFieldsHeader, payload: JSON) throws {
    guard header.algorithm?.rawValue != Keys.none.rawValue else {
      throw SDJWTError.noneAsAlgorithm
    }

    guard SigningAlgorithm.allCases.map({$0.rawValue}).contains(header.algorithm?.rawValue) else {
      throw SDJWTError.macAsAlgorithm
    }

    self.header = header
    self.payload = payload
  }

  public init(header: JWSRegisteredFieldsHeader, kbJwtPayload: JSON) throws {
    guard header.algorithm?.rawValue != Keys.none.rawValue else {
      throw SDJWTError.noneAsAlgorithm
    }

    guard SigningAlgorithm.allCases.map({$0.rawValue}).contains(header.algorithm?.rawValue) else {
      throw SDJWTError.macAsAlgorithm
    }
    self.header = header
    self.payload = kbJwtPayload
    self.addKBTyp()
  }

  // MARK: - Methods

  func sign<KeyType>(key: KeyType) throws -> JWS {
    let unsignedJWT = try self.asUnsignedJWT()
      return try JWS.init(payload: unsignedJWT.payload, protectedHeader: unsignedJWT.header, key: key)
  }

  mutating func addKBTyp() {
    self.header.type = "kb+jwt"
  }
}

struct JWTBody: Codable {
  var json: JSON {
    return JSON([
      Keys.nonce.rawValue: nonce,
      Keys.aud.rawValue: aud,
      Keys.iat.rawValue: iat
    ] as [String: Any])
  }

  var nonce: String
  var aud: String
  var iat: Int

}
