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

@resultBuilder
internal struct JSONBuilder {
  
  // Handle key-value pairs
  static func buildBlock(_ components: [String: JSON?]...) -> [String: JSON?] {
    var result: [String: JSON?] = [:]
    for component in components {
      result.merge(component) { (_, new) in new }
    }
    return result
  }
  
  // Handle individual expressions
  static func buildExpression(_ expression: [String: JSON?]) -> [String: JSON?] {
    return expression
  }
  
  static func buildExpression(_ expression: [JSON]) -> [String: JSON?] {
    // This expression now returns empty dictionary, as array should be handled in JSON context
    return [:]
  }
  
  // Handle inline JSON objects
  static func buildExpression(_ expression: JSON) -> [String: JSON?] {
    // Assuming this JSON is a dictionary, we merge it
    guard let dictionary = expression.dictionary else {
      return [:] // Ignore if it's not an object (could handle arrays differently)
    }
    return dictionary.mapValues { $0 }
  }
  
  // Handle building arrays of JSON objects
  static func buildArray(_ components: [[String: JSON?]]) -> [String: JSON?] {
    var result: [String: JSON?] = [:]
    for component in components {
      result.merge(component) { (_, new) in new }
    }
    return result
  }
}

// Function to create JSON objects
internal func JSONObject(@JSONBuilder _ content: () -> [String: JSON?]) -> JSON {
  var result: [String: JSON] = [:]
  for (key, value) in content() {
    if let unwrappedValue = value {
      result[key] = unwrappedValue
    }
  }
  return JSON(result)
}

// DSL for JSON array construction
internal func JSONArray(_ build: () -> [JSON]) -> JSON {
  return JSON(build())
}
