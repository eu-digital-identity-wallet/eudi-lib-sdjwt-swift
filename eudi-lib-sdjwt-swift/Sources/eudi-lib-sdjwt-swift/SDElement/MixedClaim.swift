//
//  MixedClaim.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 18/8/23.
//

import Foundation

struct MixedClaim: SDElement {
  
  // MARK: - Properties
  
  var key: String
  var value: SDElementValue
  
  mutating func base64Encode(saltProvider: SaltProvider) throws -> Self? {
    return self
  }
  
  init?(plainClaim: PlainClaim, disclosedClaim: DisclosedClaim) {
    self.key = plainClaim.key
    self.value = .base(.init(arrayLiteral: [SDElementValue]()))
    
    switch (plainClaim.value, disclosedClaim.value) {
    case (.array(let array), .array(let disclosedArray)):
      self.value = .array(array + disclosedArray)
    default:
      return nil
    }
  }
  
}
