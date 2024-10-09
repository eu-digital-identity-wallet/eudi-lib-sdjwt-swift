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

/// A struct that implements JSON Pointer (RFC 6901) to navigate and extract values from JSON documents.
/// JSON Pointer defines a string syntax for identifying a specific value within a JSON document.
///
/// More details about JSON Pointer can be found in the RFC specification: https://datatracker.ietf.org/doc/html/rfc6901
public struct JSONPointer {
  
  /// The pointer string that represents the path in the JSON document.
  public let pointer: String
  
  /// Initializes a `JSONPointer` instance with a pointer string.
  ///
  /// - Parameter pointer: A JSON Pointer string (must start with a `/`).
  public init(pointer: String) {
    self.pointer = pointer
  }
  
  /// Applies the JSON Pointer to a given JSON object to retrieve the value at the specified path.
  ///
  /// - Parameter json: The `JSON` object to traverse.
  /// - Returns: The `JSON` value found at the specified path, or `nil` if the path is invalid.
  public func evaluate(on json: JSON) -> JSON? {
    // Split the pointer into path components, ignoring the first empty token (because of leading `/`)
    let components = pointer.split(separator: "/").map { component -> String in
      // Unescape tokens according to RFC 6901
      return component.replacingOccurrences(of: "~1", with: "/").replacingOccurrences(of: "~0", with: "~")
    }
    
    var currentJSON = json
    
    // Traverse through the components
    for component in components {
      // If the current part is an array index, convert it to Int
      if let index = Int(component), currentJSON.type == .array {
        currentJSON = currentJSON[index]
      } else {
        currentJSON = currentJSON[component]
      }
      
      // If we encounter an invalid path, return nil
      if currentJSON == JSON.null {
        return nil
      }
    }
    
    return currentJSON
  }
}
