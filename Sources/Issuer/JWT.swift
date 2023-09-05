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


struct JWT: JWTRepresentable {

  // MARK: - Properties
  var header: JWSHeader
  var payload: ClaimSet

  // MARK: - Lifecycle
  init(header: JWSHeader, payload: ClaimSet) throws {
    guard header.algorithm?.rawValue != Keys.none.rawValue else {
      throw SDJWTError.noneAsAlgorithm
    }

    guard SignatureAlgorithm.allCases.map({$0.rawValue}).contains(header.algorithm?.rawValue) else {
      throw SDJWTError.macAsAlgorithm
    }

    self.header = header
    self.payload = payload
  }

  init(header: JWSHeader, kbJwtPayload: JSON) throws {
    guard header.algorithm?.rawValue != Keys.none.rawValue else {
      throw SDJWTError.noneAsAlgorithm
    }

    guard SignatureAlgorithm.allCases.map({$0.rawValue}).contains(header.algorithm?.rawValue) else {
      throw SDJWTError.macAsAlgorithm
    }
    self.header = header
    self.payload = (value: kbJwtPayload, [])
  }

  // MARK: - Methods

  func sign<KeyType>(signer: Signer<KeyType>) throws -> JWS {
    let unsignedJWT = try self.asUnsignedJWT()
    return try JWS(header: unsignedJWT.header, payload: unsignedJWT.payload, signer: signer)
  }
}
