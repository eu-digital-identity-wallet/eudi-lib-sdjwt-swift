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
}
