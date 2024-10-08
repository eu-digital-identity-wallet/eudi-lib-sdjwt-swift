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
import JSONWebKey
import JSONWebSignature
import SwiftyJSON

public final class KeyBindingVerifier: VerifierProtocol {
  
  static let kbJwt = "kb+jwt"
  
  public init() {
  }
  
  public func verify(
    iatOffset: TimeRange,
    expectedAudience: String,
    challenge: JWS,
    extractedKey: JWK
  ) throws {
    guard challenge.protectedHeader.type == Self.kbJwt else {
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
    
    let signatureVerifier = try SignatureVerifier(signedJWT: challenge, publicKey: extractedKey)
    _ = try signatureVerifier.verify()
    
    try verifyIat(iatOffset: iatOffset, iat: Date(timeIntervalSince1970: TimeInterval(timeInterval)))
    try verifyAud(aud: aud, expectedAudience: expectedAudience)
  }
  
  public func verify(
    challenge: JWS,
    extractedKey: JWK
  ) throws {
    guard challenge.protectedHeader.type == Self.kbJwt else {
      throw SDJWTVerifierError.keyBindingFailed(description: "no kb+jwt as typ claim")
    }
    
    let challengePayloadJson = try challenge.payloadJSON()
    
    guard challengePayloadJson[Keys.nonce].exists() else {
      throw SDJWTVerifierError.keyBindingFailed(description: "No Nonce Provided")
    }
    
    let signatureVerifier = try SignatureVerifier(signedJWT: challenge, publicKey: extractedKey)
    _ = try signatureVerifier.verify()
  }
  
  @discardableResult
  public func verify() throws -> JWS {
    throw SDJWTVerifierError.keyBindingFailed(description: "Invalid signature verifier")
  }
}

private extension KeyBindingVerifier {
  
  func verifyIat(iatOffset: TimeRange, iat: Date) throws {
    guard iatOffset.contains(date: iat) else {
      throw SDJWTVerifierError.keyBindingFailed(description: "iat not in valid time window")
    }
  }
  
  func verifyAud(aud: JSON, expectedAudience: String) throws {
    if let array = aud.array {
      guard array
        .compactMap({$0.stringValue})
        .contains(where: { $0 == expectedAudience})
      else {
        throw SDJWTVerifierError.keyBindingFailed(description: "Expected Audience Missmatch")
      }
    } else if let string = aud.string {
      guard string == expectedAudience else {
        throw SDJWTVerifierError.keyBindingFailed(description: "Expected Audience Missmatch")
      }
    }
  }
}
