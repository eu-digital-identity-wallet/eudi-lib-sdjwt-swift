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
import SwiftyJSON

public enum SerialisationFormat {
  case serialised
  case envelope
}

public class CompactParser: ParserProtocol {
  
  // MARK: - Properties
  
  private static let TILDE = "~"
  
  var serialisationFormat: SerialisationFormat = .serialised
  
  // MARK: - Lifecycle
  
  public init() {
  }
  
  // MARK: - Methods
  
  public func getSignedSdJwt(using serialiserProtocol: SerialiserProtocol) throws -> SignedSDJWT {
    let serialisedString = serialiserProtocol.serialised
    return try getSignedSdJwt(serialisedString: serialisedString)
  }
  
  public func getSignedSdJwt(serialisedString: String) throws -> SignedSDJWT {
    let (serialisedJWT, disclosuresInBase64, serialisedKBJWT) = try self.parseCombined(serialisedString)
    return try SignedSDJWT(serializedJwt: serialisedJWT, disclosures: disclosuresInBase64, serializedKbJwt: serialisedKBJWT)
  }
  
  func extractJWTParts(_ jwt: String) throws -> (String, String, String) {
    // Split the JWT string into its components: header, payload, signature
    let parts = jwt.split(separator: ".")
    
    // Ensure that we have exactly 3 parts (header, payload, signature)
    guard parts.count == 3 else {
      throw SDJWTVerifierError.parsingError
    }
    
    var header: Substring?
    var payload: Substring?
    var signature: Substring?
    
    // Iterate over the components and assign them to respective variables
    for (index, part) in parts.enumerated() {
      switch index {
      case 0:
        header = part  // Assigning Substring
      case 1:
        payload = part  // Assigning Substring
      case 2:
        signature = part  // Assigning Substring
      default:
        break
      }
    }
    
    // Ensure that all components are properly assigned
    guard
      let unwrappedHeader = header,
      let unwrappedPayload = payload,
      let unwrappedSignature = signature
    else {
      throw SDJWTVerifierError.parsingError
    }
    
    // Convert Substring to String just before returning
    return (String(unwrappedHeader), String(unwrappedPayload), String(unwrappedSignature))
    
  }
  
  
  /**
   Parses a combined SD-JWT string into its components.
   - Parameter serialisedString: The combined SD-JWT string to parse.
   - Returns: A tuple containing the JWT, an array of disclosures, and an optional key binding JWT.
   - Note:
   - The serialization format is a tilde ('~') separated string:
   `<Issuer-signed JWT>~<Disclosure 1>~<Disclosure 2>~...~<Disclosure N>~[<KB-JWT>]`
   */
  private func parseCombined(_ serialisedString: String) throws -> (String, [Disclosure], String?) {
    let parts = serialisedString
      .split(
        separator: "~",
        omittingEmptySubsequences: false)
      .map {String($0)}
    
    guard parts.count > 1 else {
      throw SDJWTVerifierError.parsingError
    }
    
    let jwt = String(parts[0])
    if serialisedString.hasSuffix("~") {
      // means no key binding is present
      let disclosures = parts.count > 2 ? Array(parts[1..<(parts.count - 1)]) : []
      return (jwt, disclosures, nil)
    } else {
      // means we have key binding jwt
      let disclosures = parts.count > 2 ? Array(parts[1..<(parts.count - 1)]) : []
      let kbJwt = parts.count > 1 ? parts.last : nil
      return (jwt, disclosures, kbJwt)
    }
  }
}
