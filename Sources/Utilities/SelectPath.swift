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
import SwiftyJSON

/// Protocol for selecting a JSON path.
protocol SelectPath {
  /// Matches the given path to the JSON.
  /// - Parameters:
  ///   - json: The JSON to match against.
  ///   - path: The claim path to match.
  /// - Returns: A JSON element if found, otherwise an error.
  func select(json: JSON, path: ClaimPath) -> Result<JSON?, Error>
}

/// Default implementation of `SelectPath`.
struct DefaultSelectPath: SelectPath {
  func select(json: JSON, path: ClaimPath) -> Result<JSON?, Error> {
    do {
      return .success(try selectPath(json: json, path: path))
    } catch {
      return .failure(error)
    }
  }
  
  /// Helper function to recursively traverse the JSON structure.
  private func selectPath(json: JSON, path: ClaimPath) throws -> JSON? {
    guard let head = path.value.first else { return nil }
    let tail = path.tail()
    
    switch head {
    case .claim(let name):
      guard json.dictionary != nil else {
        throw NSError(domain: "SelectPath", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected JSON object, found \(json)"])
      }
      let selectedElement = json[name]
      return tail == nil ? selectedElement : try selectPath(json: selectedElement, path: tail!)
      
    case .arrayElement(let index):
      guard json.array != nil else {
        throw NSError(domain: "SelectPath", code: 2, userInfo: [NSLocalizedDescriptionKey: "Expected JSON array, found \(json)"])
      }
      let selectedElement = json.arrayValue[safe: index]
      return tail == nil ? selectedElement : try selectPath(json: selectedElement ?? JSON.null, path: tail!)
      
    case .allArrayElements:
      guard let jsonArray = json.array else {
        throw NSError(domain: "SelectPath", code: 3, userInfo: [NSLocalizedDescriptionKey: "Expected JSON array, found \(json)"])
      }
      let selectedElements = jsonArray.compactMap { try? selectPath(json: $0, path: tail!) }
      return JSON(selectedElements)
    }
  }
}
