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

  /// Recursively collects digests from JSON structure
  ///
  /// - Parameters:
  ///   - json: The JSON to search
  ///   - digests: Mutable array to collect digests into
  private static func collectDigestsRecursively(from json: JSON, into digests: inout [DisclosureDigest]) {
    // Collect from _sd array at this level
    if let sdArray = json[Keys.sd.rawValue].array {
      let digestStrings = sdArray.compactMap { $0.string }
      digests.append(contentsOf: digestStrings)
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
          collectDigestsRecursively(from: subJson, into: &digests)
        }

        // Recurse into arrays
        if subJson.type == .array {
          for arrayElement in subJson.arrayValue {
            // Check for array element digest (... syntax)
            if let dotDigest = arrayElement[Keys.dots.rawValue].string {
              digests.append(dotDigest)
            }

            // Recurse into nested objects/arrays within array
            if arrayElement.type == .dictionary || arrayElement.type == .array {
              collectDigestsRecursively(from: arrayElement, into: &digests)
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
}
