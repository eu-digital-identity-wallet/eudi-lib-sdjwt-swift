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
import CryptoKit
import Security

public typealias JWTString = String
public typealias Nonce = String

class JWSController {

  var signatureAlgorithm: SignatureAlgorithm
  let signer: Signer<SecKey>

  init?(signingAlgorithm: SignatureAlgorithm, privateKey: SecKey) throws {
    self.signatureAlgorithm = signingAlgorithm
    guard let signer = Signer(signingAlgorithm: signingAlgorithm, key: privateKey) else {
      throw JOSESwiftError.signingFailed(description: "Failed To Create Signing Algorith \(signingAlgorithm) with key \(privateKey)")
    }
    self.signer = signer
  }
}

// public extension JWSController {
//
//  func generateHardcodedRSAPrivateKey() throws -> SecKey? {
//    let privateKey = Curve25519.Signing.PrivateKey()
//    // Convert PEM key to Data
//    guard
//      let contents = String.loadStringFileFromBundle(
//        named: "sample_derfile",
//        withExtension: "der"
//      )?.replacingOccurrences(of: "\n", with: ""),
//      let data = Data(base64Encoded: contents)
//    else {
//      return nil
//    }
//
//    // Define the key attributes
//    let attributes: [CFString: Any] = [
//      kSecAttrKeyType: kSecAttrKeyTypeRSA,
//      kSecAttrKeyClass: kSecAttrKeyClassPrivate
//    ]
//
//    // Create the SecKey object
//    var error: Unmanaged<CFError>?
//    guard let secKey = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) else {
//      if let error = error?.takeRetainedValue() {
//        print("Failed to create SecKey:", error)
//      }
//      return nil
//    }
//    return secKey
//  }
//
//  func generateRSAPrivateKey() throws -> SecKey {
//    let attributes: [String: Any] = [
//      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
//      kSecAttrKeySizeInBits as String: 2048
//    ]
//
//    var error: Unmanaged<CFError>?
//    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
//      throw error!.takeRetainedValue() as Error
//    }
//    return privateKey
//  }
//
//  func generateRSAPublicKey(from privateKey: SecKey) throws -> SecKey {
//    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
//      throw SDJWTError.keyCreation
//    }
//    return publicKey
//  }
//

// }
