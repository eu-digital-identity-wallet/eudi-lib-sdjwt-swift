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
  func salt() throws -> Data
  func saltString() throws -> Salt
}

final class DefaultSaltProvider: SaltProvider {

  // MARK: - Methods

  func saltString() throws -> Salt {
    try salt().base64URLEncode()
  }

  func salt() throws -> Data {
    try generateRandomSalt()
  }

  // Reject a silent all-zero salt when the CSPRNG fails.
  func generateRandomSalt(length: Int = 16) throws -> Data {
    var randomBytes = [UInt8](repeating: 0, count: length)
    let result = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)
    guard result == errSecSuccess else {
      throw SDJWTError.randomGenerationFailed
    }
    return Data(randomBytes)
  }
}
