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

typealias SDObject = [Claim]

enum ClaimValue: Encodable {
  
  static func mergeArrays(value: ClaimValue, elementsToAdd: ClaimValue) -> ClaimValue? {
    switch (value, elementsToAdd) {
    case (.array(let array), .array(let arrayToAdd)):
      return .array(array + arrayToAdd)
    default:
      return nil
    }
  }
  
  case base(AnyCodable)
  case array([ClaimValue])
  case object(SDObject)

  // MARK: - Lifecycle
  
  init<T>(_ base: T) {
    self = .base(AnyCodable(base))
  }
  
  init(_ array: [ClaimValue]) {
    self = .array(array)
  }
  
  init(_ object: SDObject) {
    self = .object(object)
  }
  
  init(@SDJWTObjectBuilder builder: () -> SDObject) {
    self = .object(builder())
  }
  
  // MARK: - Methods - Encodable
  
  func encode(to encoder: Encoder) {
    print(encoder.codingPath)
    switch self {
    case .base(let base):
      try? base.encode(to: encoder)
    case .array(let array):
      try? array.encode(to: encoder)
    case .object(let object):
      object.forEach({try? $0.encode(to: encoder)})
    }
  }
}

extension ClaimValue {
  var value: Any {
    switch self {
    case .array(let array):
      return array.map({$0.value})
    case .base(let anyCodable):
      return anyCodable.value
    case .object(let object):
      return object.toSDElementValue()
    }
  }
}
