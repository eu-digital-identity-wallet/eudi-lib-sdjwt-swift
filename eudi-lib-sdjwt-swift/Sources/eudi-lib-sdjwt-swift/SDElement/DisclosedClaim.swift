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

    func base64Encode(saltProvider: SaltProvider) -> Self {
        do {
            switch self.value {
            case .base(let base):
                return try DisclosedClaim(self.key, base64encodeBaseValue(base, saltProvider: saltProvider))
            case .array(let array):
                return try DisclosedClaim(self.key, base64encodeArray(array, saltProvider: saltProvider))
            case .object(let object):
                return try DisclosedClaim(self.key, base64encodeObject(object, saltProvider: saltProvider))
            }
        } catch {
            print("failed to disclose")
            return DisclosedClaim("", .base(""))
        }
    }

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

extension DisclosedClaim {
    func flatDisclose(signer: Signer) -> Self? {
        var base64encoded = self.base64Encode(saltProvider: signer.saltProvider)
        base64encoded.key = "_sd"
        guard let base64encodedValue = try? self.base64encodeBaseValue(AnyCodable(self.flatString), saltProvider: signer.saltProvider) else {
            return nil
        }
        base64encoded.value = .array([base64encodedValue])
//        switch self.value {
//        case .base(let base):
////            base64encoded.value = base
//            print("hash it")
//        case .array(let array):
//            print("hash it")
//        case .object(let object):
//
//        }
        return base64encoded
    }
}
