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
@preconcurrency import SwiftyJSON

extension Keys: JSONSubscriptType {
  public var jsonKey: SwiftyJSON.JSONKey {
    return .key(self.rawValue)
  }
}

extension JSON {
  
  static let empty = JSON()
  
  /// Returns true if the JSON is a primitive (string, number, bool)
  var isPrimitive: Bool {
    switch self.type {
    case .string, .number, .bool:
      return true
    default:
      return false
    }
  }
  
  subscript(key: Keys) -> JSON {
    return self[[key]]
  }
  
  func findDigestCount() -> Int {
    var foundValues = 0
    
    if !self[Keys.sd.rawValue].arrayValue.isEmpty {
      foundValues = self[Keys.sd.rawValue].arrayValue.count
    }
    
    // Loop through the JSON data
    for (_, subJson): (String, JSON) in self {
      if !subJson.dictionaryValue.isEmpty {
        foundValues += subJson.findDigestCount()
      } else if !subJson.arrayValue.isEmpty {
        for object in subJson.arrayValue {
          foundValues += object[Keys.dots.rawValue].exists() == true ? 1 : 0
        }
      }
    }
    
    return foundValues
  }
  
  
  /// Converts the JSON object to a UTF-8 encoded String.
  var stringified: String? {
    guard let data = try? self.rawData(),
          let string = String(data: data, encoding: .utf8) else {
      return nil
    }
    return string
  }
}
