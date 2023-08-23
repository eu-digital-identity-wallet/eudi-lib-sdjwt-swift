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

struct DisclosedClaim: Claim {
  
  // MARK: - Properties
  
  var key: String
  var value: ClaimValue
  
  // MARK: - LifeCycle
  
  init(_ key: String, _ value: ClaimValue) {
    self.key = key
    self.value = value
  }

  init(_ key: String, _ value: String) {
    self.key = key
    self.value = .init(value)
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
      return nil
    }
    
    return self
  }
  
  func hashValue(digestCreator: DigestCreator, base64EncodedValue: ClaimValue) throws -> ClaimValue {
    guard case ClaimValue.base(let base64EncodedValue) = base64EncodedValue else {
      throw SDJWTError.encodingError
    }

    guard let hashedString = digestCreator.hashAndBase64Encode(input: base64EncodedValue.description) else {
      throw SDJWTError.encodingError
    }
    
    return .init(hashedString)
  }
  
  fileprivate func base64encodeBaseValue(_ baseValue: AnyCodable, saltProvider: SaltProvider) throws -> ClaimValue {
    let saltString = saltProvider.saltString
    let stringToEncode = "[\"\(saltString)\", \"\(key)\", \(baseValue.value)]"
    let base64data = stringToEncode.data(using: .utf8)
    guard let base64EncodedString = base64data?.base64URLEncode() else {
      throw SDJWTError.discloseError
    }
    
    return .base(AnyCodable(base64EncodedString))
  }
  
  fileprivate func base64encodeArray(_ values: [ClaimValue], saltProvider: SaltProvider) throws -> ClaimValue {
    var encodedArray: [ClaimValue] = []
    for value in values {
      let string = try value.toJSONString(outputFormatting: .withoutEscapingSlashes)
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
  
  fileprivate func base64encodeObject(_ object: (SDObject), saltProvider: SaltProvider) throws -> ClaimValue {
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
  
  func asJWTElement() -> SDJWTElement {
    guard let disclosed = try? DisclosedClaim("_sd", self.hashValue(digestCreator: DigestCreator(), base64EncodedValue: self.value)) else {
      return (self, self.flatString)
    }

    return (disclosed, disclosed.flatString)
  }
}
