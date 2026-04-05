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

/// Utility for collecting all disclosure digests from SD-JWT structures
///
/// Verifiers must ensure that
/// "the same digest value does not appear more than once in the Issuer-signed
/// JWT and the Disclosures."
///
/// This utility recursively collects all digests from:
/// - Top-level `_sd` arrays
/// - Nested object `_sd` arrays
/// - Array element `...` references
/// - Disclosures that contain nested structures with `_sd` arrays
enum DigestCollector {

  /// Collects all digests from a JSON payload recursively
  ///
  /// - Parameter json: The JSON payload to search
  /// - Returns: Array of all digest strings found
  ///
  /// ## Example
  /// ```swift
  /// let digests = DigestCollector.collectAll(from: payload)
  /// let uniqueDigests = Set(digests)
  /// if digests.count != uniqueDigests.count {
  ///   throw SDJWTVerifierError.nonUniqueDisclosureDigests
  /// }
  /// ```
  static func collectAll(from json: JSON) -> [DisclosureDigest] {
    var digests: [DisclosureDigest] = []
    collectDigestsRecursively(from: json, into: &digests)
    return digests
  }

  /// Collects all digests from a JSON payload AND from nested structures within disclosures
  ///
  /// This method opens each disclosure to check if it contains nested JSON structures
  /// with additional `_sd` arrays, ensuring all digests (including nested ones) are found.
  ///
  /// - Parameters:
  ///   - json: The JWT payload to search
  ///   - disclosures: Map of digests to their corresponding disclosures
  /// - Returns: Array of all digest strings found (including nested within disclosures)
  ///
  static func collectAll(from json: JSON, disclosures: [DisclosureDigest: Disclosure]) -> [DisclosureDigest] {
    var digests: [DisclosureDigest] = []
    var processedDigests: Set<DisclosureDigest> = [] // Track to avoid infinite loops
    collectDigestsRecursively(from: json, disclosures: disclosures, into: &digests, processed: &processedDigests)
    return digests
  }

  /// Recursively collects digests from JSON structure (without using disclosures)
  ///
  /// - Parameters:
  ///   - json: The JSON to search
  ///   - digests: Mutable array to collect digests into
  private static func collectDigestsRecursively(from json: JSON, into digests: inout [DisclosureDigest]) {
    var emptyProcessed = Set<DisclosureDigest>()
    collectDigestsRecursively(from: json, disclosures: [:], into: &digests, processed: &emptyProcessed)
  }

  /// Recursively collects digests from JSON structure, opening disclosures to find nested digests
  ///
  /// This method ensures RFC 9901 compliance by finding ALL digests, including those
  /// hidden within disclosed values. When a digest is found, it looks up the corresponding
  /// disclosure and recursively searches it for additional `_sd` arrays.
  ///
  /// - Parameters:
  ///   - json: The JSON to search
  ///   - disclosures: Map of digests to disclosures for opening nested structures
  ///   - digests: Mutable array to collect digests into
  ///   - processed: Set of already-processed digests to avoid infinite loops
  ///
  private static func collectDigestsRecursively(
    from json: JSON,
    disclosures: [DisclosureDigest: Disclosure],
    into digests: inout [DisclosureDigest],
    processed: inout Set<DisclosureDigest>
  ) {
    // Collect from _sd array at this level
    if let sdArray = json[Keys.sd.rawValue].array {
      let digestStrings = sdArray.compactMap { $0.string }
      digests.append(contentsOf: digestStrings)

      // For each digest, check if we can open the disclosure to find nested _sd arrays
      for digest in digestStrings {
        // Avoid infinite loops by tracking processed digests
        guard !processed.contains(digest) else { continue }
        processed.insert(digest)

        // Try to decode the disclosure for this digest
        if let disclosure = disclosures[digest],
           let decodedString = disclosure.base64URLDecode(),
           let disclosureArray = try? JSON(parseJSON: decodedString).arrayValue,
           disclosureArray.count >= 2 {

          // The disclosure format is [salt, claim_name, claim_value] for objects
          // or [salt, claim_value] for array elements
          let valueIndex = disclosureArray.count - 1
          let claimValue = disclosureArray[valueIndex]

          // If the disclosed value is a JSON object or array, recursively search it
          if claimValue.type == .dictionary || claimValue.type == .array {
            collectDigestsRecursively(
              from: claimValue,
              disclosures: disclosures,
              into: &digests,
              processed: &processed
            )
          }
        }
      }
    }

    // Recursively search in nested objects
    if let dictionary = json.dictionaryObject {
      for (key, _) in dictionary {
        // Skip _sd_alg and _sd keys as we've already processed them
        guard key != Keys.sdAlg.rawValue && key != Keys.sd.rawValue else {
          continue
        }

        let subJson = json[key]

        // Recurse into nested objects
        if subJson.type == .dictionary {
          collectDigestsRecursively(
            from: subJson,
            disclosures: disclosures,
            into: &digests,
            processed: &processed
          )
        }

        // Recurse into arrays
        if subJson.type == .array {
          for arrayElement in subJson.arrayValue {
            // Check for array element digest (... syntax)
            if let dotDigest = arrayElement[Keys.dots.rawValue].string {
              digests.append(dotDigest)

              // Open this array element disclosure to check for nested _sd arrays
              guard !processed.contains(dotDigest) else { continue }
              processed.insert(dotDigest)

              if let disclosure = disclosures[dotDigest],
                 let decodedString = disclosure.base64URLDecode(),
                 let disclosureArray = try? JSON(parseJSON: decodedString).arrayValue,
                 disclosureArray.count >= 2 {

                let valueIndex = disclosureArray.count - 1
                let claimValue = disclosureArray[valueIndex]

                if claimValue.type == .dictionary || claimValue.type == .array {
                  collectDigestsRecursively(
                    from: claimValue,
                    disclosures: disclosures,
                    into: &digests,
                    processed: &processed
                  )
                }
              }
            }

            // Recurse into nested objects/arrays within array
            if arrayElement.type == .dictionary || arrayElement.type == .array {
              collectDigestsRecursively(
                from: arrayElement,
                disclosures: disclosures,
                into: &digests,
                processed: &processed
              )
            }
          }
        }
      }
    }
  }

  /// Validates that all digests in the array are unique
  ///
  /// - Parameter digests: Array of digests to check
  /// - Throws: `SDJWTVerifierError.nonUniqueDisclosureDigests` if duplicates found
  ///
  static func ensureUnique(_ digests: [DisclosureDigest]) throws {
    let uniqueDigests = Set(digests)
    guard digests.count == uniqueDigests.count else {
      throw SDJWTVerifierError.nonUniqueDisclosureDigests
    }
  }

  /// Collects and validates uniqueness of all digests in a JSON structure
  ///
  /// - Parameter json: The JSON payload to validate
  /// - Throws: `SDJWTVerifierError.nonUniqueDisclosureDigests` if duplicates found
  ///
  /// ## Usage
  /// ```swift
  /// try DigestCollector.validateUniqueness(in: jwtPayload)
  /// ```
  static func validateUniqueness(in json: JSON) throws {
    let allDigests = collectAll(from: json)
    try ensureUnique(allDigests)
  }

  /// Collects and validates uniqueness of all digests, including those hidden in disclosures
  ///
  /// This method is opening disclosures
  /// to find nested `_sd` arrays that may contain duplicate digests.
  ///
  /// - Parameters:
  ///   - json: The JWT payload to validate
  ///   - disclosures: Map of digests to disclosures for opening nested structures
  /// - Throws: `SDJWTVerifierError.nonUniqueDisclosureDigests` if duplicates found
  ///
  static func validateUniqueness(in json: JSON, disclosures: [DisclosureDigest: Disclosure]) throws {
    let allDigests = collectAll(from: json, disclosures: disclosures)
    try ensureUnique(allDigests)
  }
}
