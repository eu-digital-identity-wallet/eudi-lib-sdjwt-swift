//
//  PlainClaim.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 16/8/23.
//

import Foundation

struct PlainClaim: SDElement {
  
  // MARK: - Properties
  
  var key: String
  var value: SDElementValue
  
  // MARK: - LifeCycle
  
  init(_ key: String, _ value: SDElementValue) {
    self.key = key
    self.value = value
  }
  
  // MARK: - Methods
  
  mutating func base64Encode(saltProvider: SaltProvider) throws -> Self? {
    return self
  }
}
