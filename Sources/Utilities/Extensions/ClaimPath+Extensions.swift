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
import SwiftyJSON

extension ClaimPath {
  /// Checks if the `ClaimPath` exists in the JSON structure.
  /// - Parameter json: The JSON element to check.
  /// - Returns: `true` if the path matches, `false` otherwise.
  func matches(json: JSON) -> Bool {
    return match(json: json) != nil
  }
  
  /// Matches the `ClaimPath` against a JSON element and returns the matched value.
  /// - Parameter json: The JSON element to match against.
  /// - Returns: The matched `JSON` element if the path exists, `nil` otherwise.
  func match(json: JSON) -> JSON? {
    var currentJson: JSON = json
    
    for element in value {
      switch element {
      case .allArrayElements:
        // If it's an array, return it. Otherwise, return nil.
        return currentJson.arrayValue.isEmpty ? nil : currentJson
        
      case .arrayElement(let index):
        // If it's an array and index exists, continue. Otherwise, return nil.
        guard let arrayElement = currentJson.array?[safe: index] else {
          return nil
        }
        currentJson = arrayElement
        
      case .claim(let name):
        // If it's a dictionary and key exists, continue. Otherwise, return nil.
        if currentJson[name].exists() {
          currentJson = currentJson[name]
        } else {
          return nil
        }
      }
    }
    
    return currentJson // Return the matched JSON element
  }
}


