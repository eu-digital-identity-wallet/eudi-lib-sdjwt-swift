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

typealias Salt = String

protocol SaltProvider {
  var salt: Data { get }
  var saltString: Salt { get }
}

class DefaultSaltProvider: SaltProvider {

  // MARK: - Properties

  var saltString: Salt {
    return salt.base64EncodedString()
  }

  var salt: Data {
    self.generateRandomSalt()
  }

  func generateRandomSalt(length: Int = 16) -> Data {
    var randomBytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)
    return Data(randomBytes)
  }
}

class MockSaltProvider: SaltProvider {

  var saltString: Salt {
    return salt.base64EncodedString().base64ToUTF8() ?? ""
  }

  var salt: Data = Data()

  init(saltString: String) {
    self.salt = Data(saltString.utf8)
  }

  func updateSalt(string: Salt) {
    self.salt = Data(saltString.utf8)
  }
}
