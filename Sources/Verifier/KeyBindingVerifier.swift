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

class KeyBindingVerifier: VerifierProtocol {

  let signatureVerifier: SignatureVerifier

  init(challenge: JWS, extractedKey: JWK) throws {
    guard challenge.header.typ == "kb+jwt" else {
      throw SDJWTVerifierError.keyBindingFailed(description: "no kb+jwt as typ")
    }

    switch extractedKey.keyType {
    case .EC:
      guard let secKey = try? (extractedKey as? ECPublicKey)?.converted(to: SecKey.self) else {
        throw SDJWTVerifierError.keyBindingFailed(description: "Key Type Missmatch")
      }
      self.signatureVerifier = try SignatureVerifier(signedJWT: challenge, publicKey: secKey)
    case .RSA:
      guard let secKey = try? (extractedKey as? RSAPublicKey)?.converted(to: SecKey.self) else {
        throw SDJWTVerifierError.keyBindingFailed(description: "Key Type Missmatch")
      }
      self.signatureVerifier = try SignatureVerifier(signedJWT: challenge, publicKey: secKey)
    case .OCT:
      guard let secKey = try? (extractedKey as? SymmetricKey)?.converted(to: Data.self) else {
        throw SDJWTVerifierError.keyBindingFailed(description: "Key Type Missmatch")
      }
      self.signatureVerifier = try SignatureVerifier(signedJWT: challenge, publicKey: secKey)
    }
  }

  func verify() throws -> SDJWT? {
    try signatureVerifier.verify()
    return nil
  }
}
