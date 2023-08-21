//
//  DisclosedClaim.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 17/8/23.
//

import Foundation
import Codability

struct DisclosedClaim: SDElement {

    // MARK: - Properties

    var key: String
    var value: SDElementValue

    // MARK: - LifeCycle

    init(_ key: String, _ value: SDElementValue) {
        self.key = key
        self.value = value
    }
    
    // MARK: - Methods

    mutating func base64Encode(saltProvider: SaltProvider) throws -> Self? {
        do {
            switch self.value {
            case .base(let base):
                self.value = try base64encodeBaseValue(base, saltProvider: saltProvider)
            case .array(let array):
                self.value = try base64encodeArray(array, saltProvider: saltProvider)
            case .object(let object):
                self.value = try base64encodeObject(object, saltProvider: saltProvider)
            }
        } catch {
            print("failed to disclose")
        }

        return self
    }

    fileprivate func base64encodeBaseValue(_ baseValue: AnyCodable, saltProvider: SaltProvider) throws -> SDElementValue {
        let saltString = saltProvider.saltString
        let stringToEncode = "[\"\(saltString)\", \"\(key)\", \"\(baseValue.value)\"]"

        let base64data = stringToEncode.data(using: .utf8)
        guard let base64EncodedString = base64data?.base64URLEncode() else {
            throw SDJWTError.discloseError
        }

        return .base(AnyCodable(base64EncodedString))
    }

    fileprivate func base64encodeArray(_ values: [SDElementValue], saltProvider: SaltProvider) throws -> SDElementValue {
        var encodedArray: [SDElementValue] = []
        for value in values {
            let string = try value.toJSONString()
            let saltString = saltProvider.saltString
            let stringToEncode = "[\"\(saltString)\", \(string)]"

            let base64data = stringToEncode.data(using: .utf8)
            guard let base64EncodedString = base64data?.base64URLEncode() else {
                throw SDJWTError.discloseError
            }
            encodedArray.append(.base(AnyCodable(base64EncodedString)))
        }

        return .array(encodedArray)
    }

    fileprivate func base64encodeObject(_ object: (SDObject), saltProvider: SaltProvider) throws -> SDElementValue {
        var encodedObjects: SDObject = []
        try object.forEach { element in
            var encodedElement = element
            guard let encodedElement = try encodedElement.base64Encode(saltProvider: saltProvider) else {
                throw SDJWTError.discloseError
            }
            encodedObjects.append(encodedElement)
        }
        return .object(encodedObjects)
    }

}
