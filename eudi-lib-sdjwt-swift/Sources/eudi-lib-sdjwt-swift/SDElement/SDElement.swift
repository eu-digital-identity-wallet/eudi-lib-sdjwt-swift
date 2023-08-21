//
//  SDElement.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 17/8/23.
//

import Foundation
import Codability

/// Building block for the SD-JWT
protocol SDElement: Encodable {

    var key: String { get set }
    var value: SDElementValue { get set }
    var pair: (String, SDElementValue) { get }
    
    /// Disclose applied when needed in order to create the
    /// Element that we want to selectively disclose
    /// - Parameter signer: The signer used in order to hash the values
    /// - Returns: The modified element
    ///
    mutating func base64Encode(saltProvider: SaltProvider) throws -> Self?

    mutating func build(key: String, @SDJWTArrayBuilder arrayBuilder builder: () -> [SDElementValue]) -> Self
    mutating func build(key: String, @SDJWTObjectBuilder objectBuilder builder: () -> SDObject) -> Self
    mutating func build(key: String, base builder: () -> AnyCodable) -> Self
}

extension SDElement {
    var pair: (String, SDElementValue) {
        (self.key, self.value)
    }

    var flatString: String {
        return (try? self.value.toJSONString()) ?? ""
    }

    mutating func build(key: String, @SDJWTArrayBuilder arrayBuilder builder: () -> [SDElementValue]) -> Self {
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

extension SDElement {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RawCodingKey.self)
        try container.encode(self.value, forKey: .init(string: self.key))
    }
}

extension Array {
    func toSDElementValue() -> SDElementValue {
        return .array(map({ element in
                .base(AnyCodable(element))
        }))
    }
}

extension Array where Element == SDObject {
    func toSDElementValue() -> SDElementValue {
        return .array(map({ element in
                .object(element)
        }))
    }
}

extension Array where Element == SDElement {
    func toDict() -> [String: SDElement] {
        self.reduce(into: [String: SDElement]()) { partialResult, element in
            partialResult[element.key] = element
        }
    }
}

extension Array where Element == SDElement {

    subscript<Key: Hashable>(key: Key) -> Element? {
        return self.first { $0.key == key as? String }
    }
}
