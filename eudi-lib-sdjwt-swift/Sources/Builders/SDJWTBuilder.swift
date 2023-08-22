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

@resultBuilder
enum SDJWTBuilder {
  static func buildBlock() -> [String: SDElementValue] { [:] }
  
  static func buildBlock(_ elements: [SDElement]) -> [String: SDElementValue] {
    elements.reduce(into: [:]) { partialResult, element in
      
      if let value = partialResult["_sd"] {
        if case SDElementValue.array(let array) = element.value {
          partialResult[element.key] = SDElementValue.mergeArrays(value: value, elementsToAdd: element.value)
        } else {
          partialResult[element.key] = element.value
        }
      } else {
        partialResult[element.key] = element.value
      }
      
    }
  }
  
  static func buildBlock(_ elements: SDElement...) -> [String: SDElementValue] {
    self.buildBlock(elements.compactMap({$0}))
  }
  
  static func buildBlock(_ elements: SDElement?...) -> [String: SDElementValue] {
    self.buildBlock(elements.compactMap{$0})
  }
  
  static func buildOptional(_ elements: SDElement?...) -> [String : SDElementValue] {
    elements.reduce(into: [:]) { partialResult, element in
      if let key = element?.key {
        partialResult[key] = element?.value
      }
    }
  }
}

@resultBuilder
enum SDJWTObjectBuilder {
  static func buildBlock(_ elements: SDElement...) -> [SDElement] {
    elements
  }
}

@resultBuilder
enum SDJWTArrayBuilder {
  static func buildBlock(_ elements: SDElementValue...) -> [SDElementValue] {
    elements
  }
}

func makeSDJWT(@SDJWTBuilder _ content: () -> [String: SDElementValue]) -> [String: SDElementValue] {
  content()
}

func makeDisclosed(@SDJWTBuilder _ content: (SaltProvider) -> [String: SDElementValue], saltProvider: SaltProvider) -> [String: SDElementValue] {
  content(saltProvider)
}

func makeSDJWTObject(key: String, @SDJWTObjectBuilder _ content: () -> [SDElement]) -> (String, [SDElement]) {
  return (key, content())
}

class Builder {
  
  // MARK: - Properties
  
  let signer: Signer
  
  // MARK: - LifeCycle
  
  init(signer: Signer = Signer()) {
    self.signer = signer
  }
  
  func encode(sdjwtRepresentation: [String: SDElementValue]) throws {
    try print(sdjwtRepresentation.toJSONString())
  }
  
  func encodeDisclosed(sdjwtRepresentation: [String: SDElementValue]) {
    sdjwtRepresentation.forEach { key, value in
      
    }
  }
  
}
