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

public typealias KeyPair = (public: SecKey, private: SecKey)

enum SDJWTError: Error {
  case sdAsKey
  case nullJSONValue
  case encodingError
  case discloseError
  case serializationError
  case nonObjectFormat(ofElement: Any)
  case keyCreation
  case algorithmMissMatch
  case noneAsAlgorithm
  case macAsAlgorithm
}

/// Static Keys Used by the JWT
enum Keys: String {
  case sd = "_sd"
  case dots = "..."
  case sdAlg = "_sd_alg"
  case sdJwt = "_sd_jwt"
  case iss
  case iat
  case sub
  case exp
  case jti
  case nbe
  case aud
  case cnf
  case jwk
  case nonce
  case none
}
