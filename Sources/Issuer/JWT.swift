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
  var payload: Data

  // MARK: - Lifecycle
  init(header: JWSHeader, payload: Data) throws {
    self.header = header
    self.payload = payload
  }

  // MARK: - Methods

  func sign<KeyType>(signer: Signer<KeyType>) throws -> JWS {
    try JWS(header: header, payload: Payload(payload), signer: signer)
  }

  static func KBJWT(header: JWSHeader, KBJWTBody: JSON) throws -> JWT {
    return try JWT(header: header, payload: KBJWTBody.rawData())
  }
}
