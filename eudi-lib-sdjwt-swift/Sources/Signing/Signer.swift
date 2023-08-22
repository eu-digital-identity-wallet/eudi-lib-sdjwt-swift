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

class Signer {
  
  // MARK: - Properties
  
  var saltProvider: SaltProvider
  
  // MARK: - LifeCycle
  
  init(saltProvider: SaltProvider = DefaultSaltProvider()) {
    self.saltProvider = saltProvider
  }
  
  // MARK: - Methods
  
  func hashAndBase64Encode(input: String) -> String? {
    // Convert input string to Data
    guard let inputData = input.data(using: .utf8) else {
      return nil
    }
    
    // Calculate SHA-256 hash
    let hashedData = SHA256.hash(data: inputData)
    
    // Convert hash to Data
    let hashData = Data(hashedData)
    
    // Encode hash data in base64
    let base64Hash = hashData.base64URLEncode()
    
    return base64Hash
  }
  
}

enum DiscloseObjectStrategy {
  case flat
}
