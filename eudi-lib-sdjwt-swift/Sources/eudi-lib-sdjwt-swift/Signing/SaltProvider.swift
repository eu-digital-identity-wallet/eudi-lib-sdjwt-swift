//
//  SaltProvider.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 21/8/23.
//

import Foundation

typealias Salt = String

protocol SaltProvider {
  var salt: Data { get }
  var saltString: Salt { get }
}

class DefaultSaltProvider: SaltProvider {
  
  var saltString: Salt {
    return String(data: self.salt, encoding: .utf8) ?? ""
  }
  
  var salt: Data {
    self.generateRandomSalt()
  }
  
  func generateRandomSalt(length: Int = 16) -> Data {
    var randomBytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)
    return Data(randomBytes)
  }
}

class MockSaltProvider: SaltProvider {
  
  var saltString: Salt {
    return salt.base64EncodedString().base64ToUTF8() ?? ""
  }
  
  var salt: Data
  
  init(saltString: String) {
    self.salt = Data(saltString.utf8)
  }
  
}
