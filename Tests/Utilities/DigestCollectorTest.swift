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

import XCTest
import SwiftyJSON
@testable import eudi_lib_sdjwt_swift

/// Tests for DigestCollector utility
///
/// "Ensure that the same digest value does not appear more than once"
final class DigestCollectorTest: XCTestCase {

  // MARK: - Basic Collection Tests

  func testCollectAll_EmptyJSON_ReturnsEmptyArray() {
    let json = JSON([:])
    let digests = DigestCollector.collectAll(from: json)
    XCTAssertTrue(digests.isEmpty, "Should return empty array for empty JSON")
  }

  func testCollectAll_SingleLevel_CollectsDigests() {
    let json = JSON([
      "_sd": ["digest1", "digest2", "digest3"],
      "plain_claim": "value"
    ])

    let digests = DigestCollector.collectAll(from: json)
    XCTAssertEqual(digests.count, 3, "Should collect all 3 digests")
    XCTAssertTrue(digests.contains("digest1"))
    XCTAssertTrue(digests.contains("digest2"))
    XCTAssertTrue(digests.contains("digest3"))
  }

  func testCollectAll_NestedObjects_CollectsAllLevels() {
    let json = JSON([
      "_sd": ["digest1", "digest2"],
      "plain": "value",
      "nested": [
        "_sd": ["digest3", "digest4"],
        "inner_plain": "data"
      ]
    ])

    let digests = DigestCollector.collectAll(from: json)
    XCTAssertEqual(digests.count, 4, "Should collect digests from all levels")
    XCTAssertTrue(digests.contains("digest1"))
    XCTAssertTrue(digests.contains("digest2"))
    XCTAssertTrue(digests.contains("digest3"))
    XCTAssertTrue(digests.contains("digest4"))
  }

  func testCollectAll_DeeplyNested_CollectsAll() {
    let json = JSON([
      "_sd": ["digest1"],
      "level1": [
        "_sd": ["digest2"],
        "level2": [
          "_sd": ["digest3"],
          "level3": [
            "_sd": ["digest4"]
          ]
        ]
      ]
    ])

    let digests = DigestCollector.collectAll(from: json)
    XCTAssertEqual(digests.count, 4, "Should collect from deeply nested structures")
  }

  // MARK: - Array Element Tests

  func testCollectAll_ArrayElements_CollectsDotsDigests() {
    let json = JSON([
      "array_claim": [
        ["...": "array_digest1"],
        ["...": "array_digest2"],
        "plain_value"
      ]
    ])

    let digests = DigestCollector.collectAll(from: json)
    XCTAssertEqual(digests.count, 2, "Should collect array element digests")
    XCTAssertTrue(digests.contains("array_digest1"))
    XCTAssertTrue(digests.contains("array_digest2"))
  }

  func testCollectAll_MixedArrayAndObject_CollectsAll() {
    let json = JSON([
      "_sd": ["obj_digest1"],
      "array": [
        ["...": "array_digest1"],
        [
          "_sd": ["nested_digest1"],
          "data": "value"
        ]
      ]
    ])

    let digests = DigestCollector.collectAll(from: json)
    XCTAssertEqual(digests.count, 3, "Should collect from mixed structures")
    XCTAssertTrue(digests.contains("obj_digest1"))
    XCTAssertTrue(digests.contains("array_digest1"))
    XCTAssertTrue(digests.contains("nested_digest1"))
  }

  // MARK: - Uniqueness Validation Tests

  func testEnsureUnique_UniqueDigests_Succeeds() {
    let digests = ["digest1", "digest2", "digest3"]
    XCTAssertNoThrow(try DigestCollector.ensureUnique(digests))
  }

  func testEnsureUnique_DuplicateDigests_Throws() {
    let digests = ["digest1", "digest2", "digest1"]  // digest1 appears twice

    XCTAssertThrowsError(try DigestCollector.ensureUnique(digests)) { error in
      guard case SDJWTVerifierError.nonUniqueDisclosureDigests = error else {
        XCTFail("Expected nonUniqueDisclosureDigests error")
        return
      }
    }
  }

  func testEnsureUnique_EmptyArray_Succeeds() {
    let digests: [String] = []
    XCTAssertNoThrow(try DigestCollector.ensureUnique(digests))
  }

  // MARK: - Validate Uniqueness Tests

  func testValidateUniqueness_UniqueDigests_Succeeds() {
    let json = JSON([
      "_sd": ["digest1", "digest2"],
      "nested": [
        "_sd": ["digest3", "digest4"]
      ]
    ])

    XCTAssertNoThrow(try DigestCollector.validateUniqueness(in: json))
  }

  func testValidateUniqueness_DuplicateInSameLevel_Throws() {
    let json = JSON([
      "_sd": ["digest1", "digest2", "digest1"]  // duplicate at same level
    ])

    XCTAssertThrowsError(try DigestCollector.validateUniqueness(in: json)) { error in
      guard case SDJWTVerifierError.nonUniqueDisclosureDigests = error else {
        XCTFail("Expected nonUniqueDisclosureDigests error")
        return
      }
    }
  }

  func testValidateUniqueness_DuplicateAcrossLevels_Throws() {
    let json = JSON([
      "_sd": ["digest1", "digest2"],
      "nested": [
        "_sd": ["digest2", "digest3"]  // digest2 appears in both levels
      ]
    ])

    XCTAssertThrowsError(try DigestCollector.validateUniqueness(in: json)) { error in
      guard case SDJWTVerifierError.nonUniqueDisclosureDigests = error else {
        XCTFail("Expected nonUniqueDisclosureDigests error")
        return
      }
    }
  }

  func testValidateUniqueness_DuplicateInArray_Throws() {
    let json = JSON([
      "_sd": ["digest1"],
      "array": [
        ["...": "digest1"]  // digest1 appears in both _sd and array
      ]
    ])

    XCTAssertThrowsError(try DigestCollector.validateUniqueness(in: json)) { error in
      guard case SDJWTVerifierError.nonUniqueDisclosureDigests = error else {
        XCTFail("Expected nonUniqueDisclosureDigests error")
        return
      }
    }
  }

  // MARK: - Edge Cases

  func testCollectAll_IgnoresSdAlg_DoesNotCollectIt() {
    let json = JSON([
      "_sd_alg": "sha-256",
      "_sd": ["digest1", "digest2"]
    ])

    let digests = DigestCollector.collectAll(from: json)
    XCTAssertEqual(digests.count, 2, "Should ignore _sd_alg")
    XCTAssertFalse(digests.contains("sha-256"))
  }

  func testCollectAll_ComplexRealWorld_CollectsAll() {
    // Simulate a real SD-JWT structure
    let json = JSON([
      "_sd_alg": "sha-256",
      "_sd": ["root_digest1", "root_digest2"],
      "iss": "https://issuer.example.com",
      "iat": 1516239022,
      "address": [
        "_sd": ["addr_digest1", "addr_digest2"],
        "country": "US",
        "coordinates": [
          "_sd": ["coord_digest1"]
        ]
      ],
      "nationalities": [
        ["...": "nat_digest1"],
        ["...": "nat_digest2"]
      ]
    ])

    let digests = DigestCollector.collectAll(from: json)
    XCTAssertEqual(digests.count, 7, "Should collect all 7 digests")
    XCTAssertTrue(digests.contains("root_digest1"))
    XCTAssertTrue(digests.contains("root_digest2"))
    XCTAssertTrue(digests.contains("addr_digest1"))
    XCTAssertTrue(digests.contains("addr_digest2"))
    XCTAssertTrue(digests.contains("coord_digest1"))
    XCTAssertTrue(digests.contains("nat_digest1"))
    XCTAssertTrue(digests.contains("nat_digest2"))
  }

  // MARK: - Disclosure-Aware Collection Tests

  func testCollectAllWithDisclosures_NoNesting_CollectsSameAsBasic() {
    // Simple case: disclosures don't contain nested _sd arrays
    let json = JSON([
      "_sd": ["digest1", "digest2"]
    ])

    // Disclosures reveal simple values, not nested structures
    let disclosures: [DisclosureDigest: Disclosure] = [
      "digest1": createDisclosure(salt: "salt1", key: "name", value: "Alice"),
      "digest2": createDisclosure(salt: "salt2", key: "age", value: 30)
    ]

    let digests = DigestCollector.collectAll(from: json, disclosures: disclosures)
    XCTAssertEqual(digests.count, 2, "Should collect both digests")
    XCTAssertTrue(digests.contains("digest1"))
    XCTAssertTrue(digests.contains("digest2"))
  }

  func testCollectAllWithDisclosures_NestedObject_FindsNestedDigests() {
    // Disclosure reveals an object with nested _sd array
    let json = JSON([
      "_sd": ["digest1"]
    ])

    let disclosures: [DisclosureDigest: Disclosure] = [
      "digest1": createDisclosure(salt: "salt1", key: "address", value: [
        "_sd": ["nested_digest1", "nested_digest2"],
        "country": "US"
      ])
    ]

    let digests = DigestCollector.collectAll(from: json, disclosures: disclosures)
    XCTAssertEqual(digests.count, 3, "Should find digest1 + 2 nested digests")
    XCTAssertTrue(digests.contains("digest1"))
    XCTAssertTrue(digests.contains("nested_digest1"))
    XCTAssertTrue(digests.contains("nested_digest2"))
  }

  func testCollectAllWithDisclosures_DuplicateInNested_FindsDuplicate() {
    // This is the security issue: same digest appears in top-level and nested
    let json = JSON([
      "_sd": ["digest_A", "digest_B"]
    ])

    // disclosure_A reveals an object that ALSO contains digest_B
    let disclosures: [DisclosureDigest: Disclosure] = [
      "digest_A": createDisclosure(salt: "salt1", key: "nested", value: [
        "_sd": ["digest_B"],  // DUPLICATE!
        "data": "value"
      ])
    ]

    let digests = DigestCollector.collectAll(from: json, disclosures: disclosures)

    // Should find: digest_A (top), digest_B (top), digest_B (nested) = 3 total, 2 unique
    XCTAssertEqual(digests.count, 3, "Should collect all 3 digest occurrences")
    XCTAssertTrue(digests.contains("digest_A"))
    XCTAssertTrue(digests.contains("digest_B"))

    // Verify uniqueness check would fail
    XCTAssertThrowsError(try DigestCollector.ensureUnique(digests)) { error in
      guard case SDJWTVerifierError.nonUniqueDisclosureDigests = error else {
        XCTFail("Expected nonUniqueDisclosureDigests error")
        return
      }
    }
  }

  func testValidateUniquenessWithDisclosures_DuplicateInNested_Throws() {
    let json = JSON([
      "_sd": ["digest_A", "digest_B"]
    ])

    let disclosures: [DisclosureDigest: Disclosure] = [
      "digest_A": createDisclosure(salt: "salt1", key: "nested", value: [
        "_sd": ["digest_B"]  // DUPLICATE!
      ])
    ]

    XCTAssertThrowsError(try DigestCollector.validateUniqueness(in: json, disclosures: disclosures)) { error in
      guard case SDJWTVerifierError.nonUniqueDisclosureDigests = error else {
        XCTFail("Expected nonUniqueDisclosureDigests error, got \(error)")
        return
      }
    }
  }

  func testCollectAllWithDisclosures_DeeplyNested_FindsAll() {
    // Test multiple levels of nesting
    let json = JSON([
      "_sd": ["level1_digest"]
    ])

    let disclosures: [DisclosureDigest: Disclosure] = [
      "level1_digest": createDisclosure(salt: "s1", key: "level1", value: [
        "_sd": ["level2_digest"],
        "data": "value"
      ]),
      "level2_digest": createDisclosure(salt: "s2", key: "level2", value: [
        "_sd": ["level3_digest"]
      ]),
      "level3_digest": createDisclosure(salt: "s3", key: "level3", value: "final_value")
    ]

    let digests = DigestCollector.collectAll(from: json, disclosures: disclosures)
    XCTAssertEqual(digests.count, 3, "Should find all 3 levels of digests")
    XCTAssertTrue(digests.contains("level1_digest"))
    XCTAssertTrue(digests.contains("level2_digest"))
    XCTAssertTrue(digests.contains("level3_digest"))
  }

  func testCollectAllWithDisclosures_ArrayElement_FindsNestedDigests() {
    // Test array element disclosure containing _sd array
    let json = JSON([
      "array": [
        ["...": "array_digest1"]
      ]
    ])

    let disclosures: [DisclosureDigest: Disclosure] = [
      "array_digest1": createArrayDisclosure(salt: "salt1", value: [
        "_sd": ["nested_in_array"],
        "item": "data"
      ])
    ]

    let digests = DigestCollector.collectAll(from: json, disclosures: disclosures)
    XCTAssertEqual(digests.count, 2, "Should find array digest + nested digest")
    XCTAssertTrue(digests.contains("array_digest1"))
    XCTAssertTrue(digests.contains("nested_in_array"))
  }

  func testCollectAllWithDisclosures_CircularReference_AvoidInfiniteLoop() {
    // Edge case: ensure we don't infinite loop if somehow digests reference each other
    let json = JSON([
      "_sd": ["digest_A"]
    ])

    // This is an invalid scenario, but we should handle it gracefully
    let disclosures: [DisclosureDigest: Disclosure] = [
      "digest_A": createDisclosure(salt: "s1", key: "field", value: [
        "_sd": ["digest_A"]  // Self-reference (invalid but shouldn't crash)
      ])
    ]

    let digests = DigestCollector.collectAll(from: json, disclosures: disclosures)
    // Should collect digest_A twice but not loop forever
    XCTAssertTrue(digests.count >= 1, "Should collect at least one digest")
    XCTAssertTrue(digests.contains("digest_A"))
  }

  func testCollectAllWithDisclosures_MultipleNestedSameDigest_FindsAll() {
    // Multiple different top-level digests reveal the same nested digest
    let json = JSON([
      "_sd": ["digest_A", "digest_B"]
    ])

    let disclosures: [DisclosureDigest: Disclosure] = [
      "digest_A": createDisclosure(salt: "s1", key: "field1", value: [
        "_sd": ["shared_digest"]
      ]),
      "digest_B": createDisclosure(salt: "s2", key: "field2", value: [
        "_sd": ["shared_digest"]  // Same nested digest!
      ])
    ]

    let digests = DigestCollector.collectAll(from: json, disclosures: disclosures)
    // Should find: digest_A, digest_B, shared_digest (from A), shared_digest (from B) = 4 total
    XCTAssertEqual(digests.count, 4, "Should collect all occurrences")

    // Verify uniqueness check fails
    XCTAssertThrowsError(try DigestCollector.ensureUnique(digests))
  }

  // MARK: - Helper Methods

  /// Creates a base64-encoded disclosure for an object property
  private func createDisclosure(salt: String, key: String, value: Any) -> Disclosure {
    let array = [salt, key, value]
    let jsonData = try! JSONSerialization.data(withJSONObject: array)
    return jsonData.base64URLEncode()
  }

  /// Creates a base64-encoded disclosure for an array element
  private func createArrayDisclosure(salt: String, value: Any) -> Disclosure {
    let array = [salt, value]
    let jsonData = try! JSONSerialization.data(withJSONObject: array)
    return jsonData.base64URLEncode()
  }
}

extension Data {
  /// Base64URL encoding helper for tests
  func base64URLEncode() -> String {
    let base64 = self.base64EncodedString()
    return base64
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
