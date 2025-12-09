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
import SwiftyJSON

public typealias ClaimExtractorResult = (
  digestsFoundOnPayload: [DigestType],
  recreatedClaims: JSON,
  disclosuresPerClaim: DisclosuresPerClaim?,
  disclosuresPerClaimPath: DisclosuresPerClaimPath?
)

public class ClaimExtractor {
  
  // MARK: - Properties
  
  var digestsOfDisclosures: [DisclosureDigest: Disclosure]
  
  // MARK: - Lifecycle
  
  public init(digestsOfDisclosuresDict: [DisclosureDigest: Disclosure]) {
    self.digestsOfDisclosures = digestsOfDisclosuresDict
  }
  
  // MARK: - Methods
  
  @discardableResult
  public func findDigests(
    payload json: JSON,
    disclosures: [Disclosure],
    visitor: ClaimVisitor? = nil,
    currentPath: [String] = []
  ) throws -> ClaimExtractorResult {
    
    var json = json
    json.dictionaryObject?.removeValue(forKey: Keys.sdAlg.rawValue)
    var foundDigests: [DigestType] = []
    
    // try to find sd keys on the top level
    if let sdArray = json[Keys.sd.rawValue].array, !sdArray.isEmpty {
      var sdArray = sdArray.compactMap(\.string)
      // try to find matching digests in order to be replaced with the value
      while true {
        let (updatedSdArray, foundDigest) = sdArray.findAndRemoveFirst(from: digestsOfDisclosures.compactMap({$0.key}))
        if let foundDigest,
           let foundDisclosure = digestsOfDisclosures[foundDigest]?.base64URLDecode()?.objectProperty {
          json[Keys.sd.rawValue].arrayObject = updatedSdArray
          
          guard !json[foundDisclosure.key].exists() else {
            throw SDJWTVerifierError.nonUniqueDisclosures
          }
          
          json[foundDisclosure.key] = foundDisclosure.value
          
          if let disclosure = digestsOfDisclosures[foundDigest] {
            let currentJsonPointer = "/" + (currentPath + [foundDisclosure.key]).joined(separator: "/")
            visitor?.call(
              pointer: .init(
                pointer: currentJsonPointer
              ),
              path: .init(
                jsonPointer: currentJsonPointer
              ),
              disclosure: disclosure,
              value: foundDisclosure.value.string
            )
          }
          foundDigests.append(.object(foundDigest))
          
        } else {
          json.dictionaryObject?.removeValue(forKey: Keys.sd.rawValue)
          break
        }
      }
    }
    
    // Loop through the inner JSON data
    for (key, subJson): (String, JSON) in json {
      if !subJson.dictionaryValue.isEmpty {
        let newPath = currentPath + [key]  // Update the path
        let foundOnSubJSON = try self.findDigests(
          payload: subJson,
          disclosures: disclosures,
          visitor: visitor,
          currentPath: newPath // Pass the updated path
        )
        
        // if found swap the disclosed value with the found value
        foundDigests += foundOnSubJSON.digestsFoundOnPayload
        json[key] = foundOnSubJSON.recreatedClaims
      } else if !subJson.arrayValue.isEmpty {
        for (index, object) in subJson.arrayValue.enumerated() {
          let newPath = currentPath + [key, "\(index)"] // Update the path for array elements
          if object[Keys.dots.rawValue].exists() {
            if let foundDisclosedArrayElement = digestsOfDisclosures[object[Keys.dots].stringValue]?
              .base64URLDecode()?
              .arrayProperty {
              
              foundDigests.appendOptional(.array(object[Keys.dots].stringValue))
              
              // If the object is a json we should further process it and replace
              // the element with the value found in the disclosure
              // Example https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-05.html#name-example-3-complex-structure
              if let ifHasNested = try? findDigests(
                payload: foundDisclosedArrayElement,
                disclosures: disclosures,
                visitor: visitor,
                currentPath: newPath  // Pass the updated path for the nested JSON
                
              ), !ifHasNested.digestsFoundOnPayload.isEmpty {
                foundDigests += ifHasNested.digestsFoundOnPayload
                json[key].arrayObject?[index] = ifHasNested.recreatedClaims
                
              } else if foundDisclosedArrayElement.isPrimitive,
                        let dislosure = digestsOfDisclosures[object[Keys.dots].stringValue] {
                let found = foundDisclosedArrayElement
                json[key].arrayObject?[index] = found
                
                visitor?.call(
                  pointer: .init(
                    pointer: "/" + newPath.joined(separator: "/")
                  ),
                  path: .init(
                    jsonPointer: "/" + newPath.joined(separator: "/")
                  ),
                  disclosure: dislosure,
                  value: found.string
                )
              }
            }
          } else {
            
            visitor?.call(
              pointer: .init(
                pointer: "/" + newPath.joined(separator: "/")
              ),
              path: .init(
                jsonPointer: "/" + newPath.joined(separator: "/")
              )
            )
            
            try self.findDigests(
              payload: object,
              disclosures: disclosures,
              visitor: visitor,
              currentPath: newPath // Pass the updated path
            )
          }
        }
      } else if subJson.isPrimitive {
        let newPath = currentPath + [key]
        visitor?.call(
          pointer: .init(
            pointer: "/" + newPath.joined(separator: "/")
          ),
          path: .init(
            jsonPointer: "/" + newPath.joined(separator: "/")
          )
        )
      }
    }
    
    return (
      foundDigests,
      json,
      visitor?.disclosuresPerClaim,
      visitor?.disclosuresPerClaimPath
    )
  }
}

extension ClaimPath {
  /// Initializes a `ClaimPath` from a JSON Pointer string.
  /// - Parameter jsonPointer: The JSON Pointer string (e.g., `"/user/name"`, `"/items/0"`, `"/items/1/child"`).
  init?(jsonPointer: String) {
    guard jsonPointer.hasPrefix("/") else { return nil } // JSON Pointers must start with "/"
    
    let components = jsonPointer
      .dropFirst() // Remove leading "/"
      .split(separator: "/") // Split by "/"
      .map { String($0).replacingOccurrences(of: "~1", with: "/").replacingOccurrences(of: "~0", with: "~") } // Decode JSON Pointer escape sequences
    
    guard !components.isEmpty else { return nil }
    
    let elements = components.map { component in
      if let index = Int(component) {
        // If the component is an integer, treat it as an array element
        return ClaimPathElement.arrayElement(index: index)
      } else {
        // Otherwise, treat it as a claim name
        return ClaimPathElement.claim(name: component)
      }
    }
    
    self.init(elements)
  }
}
