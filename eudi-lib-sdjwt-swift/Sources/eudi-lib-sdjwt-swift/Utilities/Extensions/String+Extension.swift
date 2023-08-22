//
//  String+Extension.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 21/8/23.
//

import Foundation

extension String {
  func base64ToUTF8() -> String? {
    guard let data = Data(base64Encoded: self) else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }
  
  func convertURLEncodedBase64ToData() -> Data? {
    // Decode URL-encoded string
    guard let decodedURLString = self.removingPercentEncoding else {
      return nil
    }
    
    // Convert base64 string to Data
    guard let data = Data(base64Encoded: decodedURLString) else {
      return nil
    }
    
    return data
  }
}
