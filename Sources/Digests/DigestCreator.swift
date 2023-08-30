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

class DigestCreator {

  // MARK: - Properties

  var hashingAlgorithm: HashingAlgorithm

  let saltProvider = DefaultSaltProvider()
  // MARK: - LifeCycle

  init(hashingAlgorithm: HashingAlgorithm = SHA256Hashing()) {
    self.hashingAlgorithm = hashingAlgorithm
  }

  // MARK: - Methods

  func hashAndBase64Encode(input: Disclosure) -> DisclosureDigest? {
    guard let disclosureDigest = self.hashingAlgorithm.hash(disclosure: input) else {
      return nil
    }
    // Encode hash data in base64
    let base64Hash = disclosureDigest.base64URLEncode()

    return base64Hash
  }

  func decoy() -> DisclosureDigest? {
    return self.hashAndBase64Encode(input: saltProvider.saltString)
  }

}