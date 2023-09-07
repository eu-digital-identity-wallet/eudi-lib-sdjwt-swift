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

import XCTest
import Security
import Foundation

@testable import eudi_lib_sdjwt_swift

extension SdElement {
  var expectedDigests: Int {
    var output = 0
    switch self {
    case .object(let object):
      output = object.reduce(into: 0) { partialResult, element in
        partialResult += element.value.expectedDigests
      }
    case .plain:
      ()
    case .flat:
      output += 1
    case .array(let array):
      output = array.reduce(into: 0, { partialResult, element in
        partialResult += element.expectedDigests
      })
    case .recursiveObject(let object):
      output = object.reduce(into: 0) { partialResult, element in
        partialResult += element.value.expectedDigests
      }
      output += 1
    case .recursiveArray(let array):
      output = array.reduce(into: 0, { partialResult, element in
        partialResult += element.expectedDigests
      })
      output += 1
    }

    return output
  }
}

@discardableResult
func validateObjectResults(factoryResult result: Result<ClaimSet, Error>, expectedDigests: Int, numberOfDecoys: Int = 0, decoysLimit: Int = 0) -> ClaimSet {
  switch result {
  case .success((let json, let disclosures)):
    XCTAssertNoThrow(try json.toJSONString(outputFormatting: .prettyPrinted))
    TestLogger.log("JSON Value of sdjwt")
    TestLogger.log("==============================")
    TestLogger.log(try! json.toJSONString(outputFormatting: .prettyPrinted))
    TestLogger.log("==============================")
    TestLogger.log("With Disclosures")
    TestLogger.log("==============================")
    disclosures
      .compactMap { $0.base64URLDecode()}
      .forEach {print($0)}
    print("==============================")
    if numberOfDecoys == 0 && decoysLimit == 0 {
      XCTAssert(disclosures.count == expectedDigests)
    }
    XCTAssert(expectedDigests + numberOfDecoys <= expectedDigests + decoysLimit)
    return (json, disclosures)
  case .failure(let err):
    XCTFail("Failed to Create SDJWT")
    return(.empty, [])
  }
}

func generateES256KeyPair() -> KeyPair {
  func generateECDHPrivateKey() throws -> SecKey {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256
    ]

    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      throw error!.takeRetainedValue() as Error
    }
    return privateKey
  }

  func generateECDHPublicKey(from privateKey: SecKey) throws -> SecKey {
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
      throw SDJWTError.keyCreation
    }
    return publicKey
  }

  let privateKey = try! generateECDHPrivateKey()
  let publicKey = try! generateECDHPublicKey(from: privateKey)

  return KeyPair(publicKey, privateKey)
}

class MockSaltProvider: SaltProvider {

  // MARK: - Properties

  var saltString: Salt {
    return salt.base64EncodedString().base64ToUTF8() ?? ""
  }

  var salt: Data = Data()

  // MARK: - LifeCycle

  init(saltString: String) {
    self.salt = Data(saltString.utf8)
  }

  // MARK: - Methods

  func updateSalt(string: Salt) {
    self.salt = Data(saltString.utf8)
  }
}

class TestLogger {
    static func log(_ message: String) {
        #if DEBUG
//        if isRunningTests() {
            print(message)
//        }
        #endif
    }

    private static func isRunningTests() -> Bool {
        let environment = ProcessInfo.processInfo.environment
        if let injectBundle = environment["XCInjectBundleInto"] {
            return NSString(string: injectBundle).pathExtension == "xctest"
        }
        return false
    }
}
