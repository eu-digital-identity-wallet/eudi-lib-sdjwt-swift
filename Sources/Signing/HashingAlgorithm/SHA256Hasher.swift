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
import CryptoKit

class SHA256Hasher: HashingAlgorithm {
  func hash(disclosure: Disclosure) -> Data? {
    // Convert input string to Data
    guard let inputData = disclosure.data(using: .utf8) else {
      return nil
    }

    // Calculate SHA-256 hash
    let hashedData = SHA256.hash(data: inputData)

    // Convert hash to Data
    return Data(hashedData)
  }
}
