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

enum SDJWTVerifierError: Error {
  case noAlgorithmProvided
  case failedToCreateVerifier
}

class SDJWTVerifier<Key> {

  // MARK: - Properties

  let verifier: Verifier
  let jws: JWS

  // MARK: - Lifecycle

  init(signedJWT: JWS, publicKey: Key) throws {
    guard let algorithm = signedJWT.header.algorithm else {
      throw SDJWTVerifierError.noAlgorithmProvided
    }

    guard let verifier = Verifier(verifyingAlgorithm: algorithm, key: publicKey) else {
      throw SDJWTVerifierError.failedToCreateVerifier
    }

    self.verifier = verifier
    self.jws = signedJWT
  }
  
  // MARK: - Methods

  func verify() throws -> JWS {
    let verifiedJws = try jws.validate(using: verifier)
    return verifiedJws
  }
}
