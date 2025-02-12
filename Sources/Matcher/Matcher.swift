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

/// A class that provides matching functionality for ClaimPath and JSON structures.
public final class Matcher {
  
  /// The JSON structure against which matching is performed.
  private let json: JSON
  
  /// Initializes the Matcher with a given JSON object.
  /// - Parameter json: The JSON object to match against.
  public init(json: JSON) {
    self.json = json
  }
  
  /// Checks if a given `ClaimPath` exists in the JSON structure.
  /// - Parameter path: The `ClaimPath` to check.
  /// - Returns: `true` if the path matches, `false` otherwise.
  public func matches(_ path: ClaimPath) -> Bool {
    return json.match(path) != nil
  }
  
  /// Matches a `ClaimPath` against the JSON structure and returns the matched value.
  /// - Parameter path: The `ClaimPath` to match.
  /// - Returns: The matched `JSON` element if the path exists, `nil` otherwise.
  public func match(_ path: ClaimPath) -> JSON? {
    return json.match(path)
  }
}

private extension JSON {
  /// Matches a `ClaimPath` against the JSON and returns the matched value.
  /// - Parameter path: The `ClaimPath` to match.
  /// - Returns: The matched `JSON` element if the path exists, `nil` otherwise.
  func match(_ path: ClaimPath) -> JSON? {
    var currentJson: JSON = self
    
    for (index, element) in path.value.enumerated() {
      switch element {
      case .allArrayElements:
        guard let array = currentJson.array, !array.isEmpty else {
          return nil
        }

        // If there are more elements in the claim path, apply the remaining path to each element.
        if index + 1 < path.value.count {
          let remainingPath = ClaimPath(Array(path.value.dropFirst(index + 1)))
          let results = array.compactMap { $0.match(remainingPath) }
          
          return JSON(results) // Return an array of matched elements
        }

        return currentJson // If no further path, return the entire array.

      case .arrayElement(let index):
        guard let arrayElement = currentJson.array?[safe: index] else {
          return nil
        }
        currentJson = arrayElement

      case .claim(let name):
        guard currentJson[name].exists() else {
          return nil
        }
        currentJson = currentJson[name]
      }
    }

    return currentJson
  }
}


