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

let saltProviderString = "lklxF5jMYlGTPUovMNIvCA"

enum SDJWTError: Error {
  case encodingError
  case discloseError
  case nonObjectFormat(ofElement: Any)
}

enum Keys: String {
  case _sd
  case dots = "..."
  case iss
  case iat
  case sub
  case exp
  case jti
  case nbe
  case aud
  case cnf
  case jwk
}
