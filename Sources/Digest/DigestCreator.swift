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

final class DigestCreator: Sendable {

  // MARK: - Properties

  let hashingAlgorithm: HashingAlgorithm
  let saltProvider: SaltProvider

  // MARK: - LifeCycle

  init(
    hashingAlgorithm: HashingAlgorithm = SHA256Hashing(),
    saltProvider: SaltProvider = DefaultSaltProvider()
  ) {
    self.hashingAlgorithm = hashingAlgorithm
    self.saltProvider = saltProvider
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

public enum DigestType: RawRepresentable, Hashable, Sendable {

  public typealias RawValue = DisclosureDigest

  case array(DisclosureDigest)
  case object(DisclosureDigest)

  // MARK: - Properties

  var components: Int {
    switch self {
    case .array:
      return 2
    case .object:
      return 3
    }
  }

  public var rawValue: DisclosureDigest {
    switch self {
    case .array(let disclosureDigest), .object(let disclosureDigest):
      return disclosureDigest
    }
  }

  // MARK: - Lifecycle

  public init?(rawValue: DisclosureDigest) {
    let cleanRawValue = rawValue
      .replacingOccurrences(of: "\"", with: "")
      .replacingOccurrences(of: "[", with: "")
      .replacingOccurrences(of: "]", with: "")
    let components = cleanRawValue.components(separatedBy: ",")

    switch components.count {
    case 2:
      self = .array(rawValue)
    case 3:
      self = .object(rawValue)
    default:
      return nil
    }
  }

}
