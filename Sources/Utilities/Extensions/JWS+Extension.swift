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

import JOSESwift
import SwiftyJSON

extension JWS {
  func payloadJSON() throws -> JSON {
    try JSON(data: self.payload.data())
  }

  func iat() throws -> Int? {
    return try payloadJSON()[Keys.iat.rawValue].int
  }

  func aud() throws -> String? {
    return try payloadJSON()[Keys.aud.rawValue].array?.toJSONString() ?? payloadJSON()[Keys.aud.rawValue].string
  }
}
