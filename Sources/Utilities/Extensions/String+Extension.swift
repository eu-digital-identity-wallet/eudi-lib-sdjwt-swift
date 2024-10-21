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

extension String {
  func base64ToUTF8() -> String? {
    guard let data = Data(base64Encoded: self) else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  func toBase64URLEncoded() -> String? {
    let data = self.data(using: .utf8)
    return data?.base64URLEncode()
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

  func base64URLDecode() -> String? {
    var base64 = self
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")

    // Padding the string with '=' characters to make its length a multiple of 4
    let paddingLength = 4 - base64.count % 4
    if paddingLength < 4 {
      base64.append(contentsOf: String(repeating: "=", count: paddingLength))
    }

    if let data = Data(base64Encoded: base64) {
      return String(data: data, encoding: .utf8)
    }

    return nil
  }
}

extension String {
  
  func removeCertificateDelimiters() -> String {
    return self.replacingOccurrences(of: "-----BEGIN CERTIFICATE-----\n", with: "")
      .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
      .replacingOccurrences(of: "\n", with: "")
  }
  
  /// Converts a PEM encoded public key to `SecKey`.
  /// - Returns: The corresponding `SecKey` if successful, otherwise `nil`.
  func pemToSecKey() -> SecKey? {
    // Remove the PEM header and footer
    let keyString = self
      .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
      .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
      .replacingOccurrences(of: "\n", with: "")
      .replacingOccurrences(of: "\r", with: "")
    
    // Decode the Base64-encoded string
    guard let keyData = Data(base64Encoded: keyString) else {
      return nil
    }
    
    // First, try RSA
    if let secKey = String.createSecKey(from: keyData, keyType: kSecAttrKeyTypeRSA) {
      return secKey
    }
    
    // If RSA fails, try EC
    if let secKey = String.createSecKey(from: keyData, keyType: kSecAttrKeyTypeEC) {
      return secKey
    }
    
    // Add more key types if needed (e.g., DSA, etc.)
    
    // If neither RSA nor EC works, return nil
    return nil
  }
  
  /// Creates a `SecKey` from the provided key data.
  /// - Parameters:
  ///   - keyData: The raw key data.
  ///   - keyType: The key type (e.g., RSA or EC).
  /// - Returns: The `SecKey` if successful, otherwise `nil`.
  private static func createSecKey(from keyData: Data, keyType: CFString) -> SecKey? {
    // Define the attributes for creating the SecKey
    let attributes: [CFString: Any] = [
      kSecAttrKeyType: keyType,
      kSecAttrKeyClass: kSecAttrKeyClassPublic,
      kSecAttrKeySizeInBits: keyData.count * 8
    ]
    
    // Try to create the SecKey
    var error: Unmanaged<CFError>?
    if let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) {
      return secKey
    } else {
      return nil
    }
  }
}

