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
public typealias JWTString = String
public typealias Nonce = String

public enum SDJWTError: Error {
  case sdAsKey
  case nullJSONValue
  case encodingError
  case discloseError
  case serializationError
  case nonObjectFormat(ofElement: String)
  case keyCreation
  case algorithmMissMatch
  case noneAsAlgorithm
  case macAsAlgorithm
}

public enum SDJWTVerifierError: Error {
  case parsingError
  case invalidJwt
  case invalidJwk
  case invalidIssuer
  case keyBindingFailed(description: String)
  case invalidDisclosure(disclosures: [Disclosure])
  case missingOrUnknownHashingAlgorithm
  case nonUniqueDisclosures
  case nonUniqueDisclosureDigests
  case missingDigests(disclosures: [Disclosure])
  case noAlgorithmProvided
  case failedToCreateVerifier
  case expiredJwt
  case notValidYetJwt
}

/// Static Keys Used by the JWT
enum Keys: String {
  case sd = "_sd"
  case dots = "..."
  case sdAlg = "_sd_alg"
  case sdJwt = "_sd_jwt"
  case sdHash = "sd_hash"
  case iss
  case iat
  case sub
  case exp
  case jti
  case nbf
  case aud
  case cnf
  case jwk
  case nonce
  case none
}
