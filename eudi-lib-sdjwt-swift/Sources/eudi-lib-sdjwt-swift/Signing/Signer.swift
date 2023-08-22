//
//  Signer.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 21/8/23.
//

import Foundation
import CryptoKit

class Signer {
  
  // MARK: - Properties
  
  var saltProvider: SaltProvider
  
  // MARK: - LifeCycle
  
  init(saltProvider: SaltProvider = DefaultSaltProvider()) {
    self.saltProvider = saltProvider
  }
  
  // MARK: - Methods
  
  func hashAndBase64Encode(input: String) -> String? {
    // Convert input string to Data
    guard let inputData = input.data(using: .utf8) else {
      return nil
    }
    
    // Calculate SHA-256 hash
    let hashedData = SHA256.hash(data: inputData)
    
    // Convert hash to Data
    let hashData = Data(hashedData)
    
    // Encode hash data in base64
    let base64Hash = hashData.base64URLEncode()
    
    return base64Hash
  }
  
}

enum DiscloseObjectStrategy {
  case flat
}
