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

extension JSON {
  subscript(key: Keys) -> JSON {
    return self[[key]]
  }
}

extension Keys: JSONSubscriptType {
  var jsonKey: SwiftyJSON.JSONKey {
    return .key(self.rawValue)
  }
}

extension JSON {

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
}

extension JSON {
  static let empty = JSON()
}
