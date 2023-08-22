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
  
  static func buildBlock(elements: [ClaimConvertible]) -> [String: ClaimValue] {
    elements.reduce(into: [:]) { partialResult, claimConvertible in
      let element = claimConvertible.asElement()
      partialResult[element.key] = element.value
    }
  }

  static func buildBlock(_ elements: ClaimConvertible?...) -> [String: ClaimValue] {
    buildBlock(elements: elements.compactMap({$0}))
  }

  static func buildBlock(_ elements: ClaimConvertible...) -> [String : ClaimValue] {
    buildBlock(elements: elements.map({$0}))
  }

}

@resultBuilder
enum SDJWTObjectBuilder {
  static func buildBlock(_ elements: Claim...) -> [Claim] {
    elements
  }
}

@resultBuilder
enum SDJWTArrayBuilder {
  static func buildBlock(_ elements: ClaimValue...) -> [ClaimValue] {
    elements
  }
}

func makeSDJWT(@SDJWTBuilder _ content: () -> [String: ClaimValue]) -> [String: ClaimValue] {
  content()
}

func makeDisclosed(@SDJWTBuilder _ content: (SaltProvider) -> [String: ClaimValue], saltProvider: SaltProvider) -> [String: ClaimValue] {
  content(saltProvider)
}

func makeSDJWTObject(key: String, @SDJWTObjectBuilder _ content: () -> [Claim]) -> (String, [Claim]) {
  return (key, content())
}

class Builder {
  
  // MARK: - Properties
  
  let digestCreator: DigestCreator
  
  // MARK: - LifeCycle
  
  init(digestCreator: DigestCreator = DigestCreator()) {
    self.digestCreator = digestCreator
  }
  
  func encode(sdjwtRepresentation: [String: ClaimValue]) throws {
    try print(sdjwtRepresentation.toJSONString(outputFormatting: .prettyPrinted))
  }
  
  func encodeDisclosed(sdjwtRepresentation: [String: ClaimValue]) {
    sdjwtRepresentation.forEach { key, value in
      
    }
  }
  
}
