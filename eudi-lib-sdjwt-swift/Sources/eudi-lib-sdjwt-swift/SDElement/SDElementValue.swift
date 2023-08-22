//
//  SDElementValue.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 17/8/23.
//

import Foundation
import Codability

typealias SDObject = [SDElement]

enum SDElementValue: Encodable {
  
  static func mergeArrays(value: SDElementValue, elementsToAdd: SDElementValue) -> SDElementValue? {
    switch (value, elementsToAdd) {
    case (.array(let array), .array(let arrayToAdd)):
      return .array(array + arrayToAdd)
    default:
      return nil
    }
  }
  
  case base(AnyCodable)
  case array([SDElementValue])
  case object(SDObject)
  
  // MARK: - Lifecycle
  
  init<T>(_ base: T) {
    self = .base(AnyCodable(base))
  }
  
  init(_ array: [SDElementValue]) {
    self = .array(array)
  }
  
  init(_ object: SDObject) {
    self = .object(object)
  }
  
  init(@SDJWTObjectBuilder builder: () -> SDObject) {
    self = .object(builder())
  }
  
  // MARK: - Methods - Encodable
  
  func encode(to encoder: Encoder) {
    print(encoder.codingPath)
    switch self {
    case .base(let base):
      try? base.encode(to: encoder)
    case .array(let array):
      try? array.encode(to: encoder)
    case .object(let object):
      object.forEach({try? $0.encode(to: encoder)})
    }
  }
  
}
