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
import Codability

/// Building block for the SD-JWT
protocol Claim: Encodable, ClaimConvertible {
  
  var key: String { get set }
  var value: ClaimValue { get set }
  var pair: (String, ClaimValue) { get }
  
  /// Disclose applied when needed in order to create the
  /// Element that we want to selectively disclose
  /// - Parameter saltProvider: The SaltProvider used in order to hash the values
  /// - Returns: The modified element
  ///
  func base64Encode(saltProvider: SaltProvider) -> Self
  mutating func base64Encode(saltProvider: SaltProvider) throws -> Self?
  func hashValue(digestCreator: DigestCreator, base64EncodedValue: ClaimValue) throws -> ClaimValue
  
  mutating func build(key: String, @SDJWTArrayBuilder arrayBuilder builder: () -> [ClaimValue]) -> Self
  mutating func build(key: String, @SDJWTObjectBuilder objectBuilder builder: () -> SDObject) -> Self
  mutating func build(key: String, base builder: () -> AnyCodable) -> Self
}

extension Claim {
  var pair: (String, ClaimValue) {
    (self.key, self.value)
  }
  
  var flatString: String {
    guard let string = try? self.value.toJSONString(outputFormatting: .withoutEscapingSlashes) else {
      return ""
    }
    return string
  }
  
  mutating func build(key: String, @SDJWTArrayBuilder arrayBuilder builder: () -> [ClaimValue]) -> Self {
    self.key = key
    self.value = .array(builder())
    return self
  }
  
  mutating func build(key: String, @SDJWTObjectBuilder objectBuilder builder: () -> SDObject) -> Self {
    self.key = key
    self.value = .object(builder())
    return self
  }
  
  mutating func build(key: String, base builder: () -> AnyCodable) -> Self {
    self.key = key
    self.value = .base(builder())
    return self
  }

  func hashValue(digestCreator: DigestCreator, base64EncodedValue: ClaimValue) throws -> ClaimValue {
    return self.value
  }
}

extension Claim {
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: RawCodingKey.self)
    try container.encode(self.value, forKey: .init(string: self.key))
  }
}

extension Array {
  func toSDElementValue() -> ClaimValue {
    return .array(map({ element in
        .base(AnyCodable(element))
    }))
  }
}

extension Array where Element == SDObject {
  func toSDElementValue() -> ClaimValue {
    return .array(map({ element in
        .object(element)
    }))
  }
}

extension Array where Element == Claim {
  func toDict() -> [String: Claim] {
    self.reduce(into: [String: Claim]()) { partialResult, element in
      partialResult[element.key] = element
    }
  }
}

extension Array where Element == Claim {
  
  subscript<Key: Hashable>(key: Key) -> Element? {
    return self.first { $0.key == key as? String }
  }
}
