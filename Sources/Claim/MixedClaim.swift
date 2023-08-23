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

struct MixedClaim: Claim {
  
  // MARK: - Properties
  
  var key: String
  var value: ClaimValue

  func base64Encode(saltProvider: SaltProvider) -> Self {
    return self
  }

  mutating func base64Encode(saltProvider: SaltProvider) throws -> Self? {
    return self
  }
  
  init?(plainClaim: PlainClaim, disclosedClaim: DisclosedClaim) {
    self.key = plainClaim.key
    self.value = .base(.init(arrayLiteral: [ClaimValue]()))
    
    switch (plainClaim.value, disclosedClaim.value) {
    case (.array(let array), .array(let disclosedArray)):
      self.value = .array(array + disclosedArray)
    default:
      return nil
    }
  }
  
}
