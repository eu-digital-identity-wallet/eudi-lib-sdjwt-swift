//
//  SDJWTBuilder.swift
//
//
//  Created by SALAMPASIS Nikolaos on 13/8/23.
//

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
