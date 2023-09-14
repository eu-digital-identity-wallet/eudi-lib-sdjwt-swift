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

class KeyBindingVerifier: VerifierProtocol {

  let signatureVerifier: SignatureVerifier

  init(iatOffset: TimeRange,
       expectedAudience: String,
       challenge: JWS,
       extractedKey: JWK) throws {

    guard challenge.header.typ == "kb+jwt" else {
      throw SDJWTVerifierError.keyBindingFailed(description: "no kb+jwt as typ claim")
    }

    let challengePayloadJson = try challenge.payloadJSON()

    guard let timeInterval = challengePayloadJson[Keys.iat].int else {
      throw SDJWTVerifierError.keyBindingFailed(description: "No iat claim Provided")
    }

    let aud = challengePayloadJson[Keys.aud]

    guard challengePayloadJson[Keys.nonce].exists() else {
      throw SDJWTVerifierError.keyBindingFailed(description: "No Nonce Provided")
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

    try checkIat(iatOffset: iatOffset, iat: Date(timeIntervalSince1970: TimeInterval(timeInterval)))
    try checkAud(aud: aud, expectedAudience: expectedAudience)
  }

  func checkIat(iatOffset: TimeRange, iat: Date) throws {
    guard iatOffset.contains(date: iat) else {
      throw SDJWTVerifierError.keyBindingFailed(description: "iat not in valid time window")
    }
  }

  func checkAud(aud: JSON, expectedAudience: String) throws {
    if let array = aud.array {
      guard array
        .compactMap({$0.stringValue})
        .contains(expectedAudience)
      else {
        throw SDJWTVerifierError.keyBindingFailed(description: "Expected Audience Missmatch")
      }
    } else if let string = aud.string {
      guard string.contains(expectedAudience) else {
        throw SDJWTVerifierError.keyBindingFailed(description: "Expected Audience Missmatch")
      }
    }
  }

  @discardableResult
  func verify() throws -> JWS {
    return try signatureVerifier.verify()
  }
}
