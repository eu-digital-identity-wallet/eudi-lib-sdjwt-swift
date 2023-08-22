//
//  Claim.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 17/8/23.
//

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
  mutating func base64Encode(saltProvider: SaltProvider) throws -> Self?
  
  
  mutating func build(key: String, @SDJWTArrayBuilder arrayBuilder builder: () -> [ClaimValue]) -> Self
  mutating func build(key: String, @SDJWTObjectBuilder objectBuilder builder: () -> SDObject) -> Self
  mutating func build(key: String, base builder: () -> AnyCodable) -> Self
}

extension Claim {
  var pair: (String, ClaimValue) {
    (self.key, self.value)
  }
  
  var flatString: String {
    return (try? self.value.toJSONString(outputFormatting: .withoutEscapingSlashes)) ?? ""
  }

  func asElement() -> Claim {
    return self
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
