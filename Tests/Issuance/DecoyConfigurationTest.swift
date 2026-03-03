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
@testable import eudi_lib_sdjwt_swift

/// Tests for the new DecoyConfiguration system
final class DecoyConfigurationTest: XCTestCase {

  // MARK: - Per-Object Minimum Tests

  /// Test that per-object minimum is enforced for single object
  func testPerObjectMinimum_SingleDisclosure_MeetsMinimum() {
    let minimumDigests = 5
    let config = DecoyConfiguration.perObject(minimum: minimumDigests)
    let factory = SDJWTFactory(decoyConfiguration: config)

    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "John")
      FlatDisclosedClaim("age", 30)  // 1 real disclosure
    }

    let result = factory.createSDJWTPayload(sdJwtObject: sdObject.asObject)

    guard case .success(let claimSet) = result else {
      XCTFail("Failed to create payload")
      return
    }

    // Should have exactly 5 digests (1 real + 4 decoys)
    let digestCount = claimSet.value.findDigestCount()
    XCTAssertEqual(digestCount, minimumDigests, "Should have exactly \(minimumDigests) digests")
  }

  /// Test that per-object minimum is enforced with multiple disclosures
  func testPerObjectMinimum_MultipleDisclosures_MeetsMinimum() {
    let minimumDigests = 7
    let config = DecoyConfiguration.perObject(minimum: minimumDigests)
    let factory = SDJWTFactory(decoyConfiguration: config)

    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "John")
      FlatDisclosedClaim("age", 30)           // 1st disclosure
      FlatDisclosedClaim("email", "j@x.com") // 2nd disclosure
      FlatDisclosedClaim("city", "Athens")   // 3rd disclosure
    }

    let result = factory.createSDJWTPayload(sdJwtObject: sdObject.asObject)

    guard case .success(let claimSet) = result else {
      XCTFail("Failed to create payload")
      return
    }

    // Should have exactly 7 digests (3 real + 4 decoys)
    let digestCount = claimSet.value.findDigestCount()
    XCTAssertEqual(digestCount, minimumDigests, "Should have exactly \(minimumDigests) digests")
  }

  /// Test that minimum is enforced when disclosures exceed minimum
  func testPerObjectMinimum_ExceedsMinimum_NoExtraDecoys() {
    let minimumDigests = 3
    let config = DecoyConfiguration.perObject(minimum: minimumDigests)
    let factory = SDJWTFactory(decoyConfiguration: config)

    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "John")
      FlatDisclosedClaim("age", 30)           // 1st
      FlatDisclosedClaim("email", "j@x.com") // 2nd
      FlatDisclosedClaim("city", "Athens")   // 3rd
      FlatDisclosedClaim("country", "GR")    // 4th
      FlatDisclosedClaim("zip", "12345")     // 5th
    }

    let result = factory.createSDJWTPayload(sdJwtObject: sdObject.asObject)

    guard case .success(let claimSet) = result else {
      XCTFail("Failed to create payload")
      return
    }

    // Should have exactly 5 digests (5 real + 0 decoys, since 5 > 3 minimum)
    let digestCount = claimSet.value.findDigestCount()
    XCTAssertEqual(digestCount, 5, "Should have exactly 5 digests (no extra decoys)")
  }

  // MARK: - Per-Object with Maximum Tests

  /// Test that random decoys are added within range
  func testPerObjectWithMaximum_AddsRandomDecoys() {
    let minimumDigests = 3
    let maximumExtra = 5
    let config = DecoyConfiguration.perObject(minimum: minimumDigests, maximum: maximumExtra)
    let factory = SDJWTFactory(decoyConfiguration: config)

    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "John")
      FlatDisclosedClaim("age", 30)  // 1 real disclosure
    }

    // Run multiple times to test randomness
    var digestCounts: Set<Int> = []
    for _ in 0..<20 {
      let result = factory.createSDJWTPayload(sdJwtObject: sdObject.asObject)

      guard case .success(let claimSet) = result else {
        XCTFail("Failed to create payload")
        return
      }

      let digestCount = claimSet.value.findDigestCount()
      digestCounts.insert(digestCount)

      // Should be in range [minimum, minimum + maximum]
      XCTAssertGreaterThanOrEqual(digestCount, minimumDigests, "Should have at least \(minimumDigests) digests")
      XCTAssertLessThanOrEqual(digestCount, minimumDigests + maximumExtra, "Should have at most \(minimumDigests + maximumExtra) digests")
    }

    // With 20 runs and range [3, 8], we should see some variation
    // (though theoretically could get same value, it's very unlikely)
    XCTAssertGreaterThan(digestCounts.count, 1, "Should see variation in digest counts across multiple runs")
  }

  // MARK: - Nested Objects Tests

  /// Test that each nested object gets its own minimum
  func testPerObjectMinimum_NestedObjects_EachMeetsMinimum() {
    let minimumDigests = 4
    let config = DecoyConfiguration.perObject(minimum: minimumDigests)
    let factory = SDJWTFactory(decoyConfiguration: config)

    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "John")
      FlatDisclosedClaim("age", 30)  // 1 disclosure at root level
      ObjectClaim("address") {
        PlainClaim("country", "GR")
        FlatDisclosedClaim("city", "Athens")  // 1 disclosure at nested level
      }
    }

    let result = factory.createSDJWTPayload(sdJwtObject: sdObject.asObject)

    guard case .success(let claimSet) = result else {
      XCTFail("Failed to create payload")
      return
    }

    // Root level should have 4 digests (1 real + 3 decoys)
    let rootDigestCount = claimSet.value["_sd"].arrayValue.count
    XCTAssertEqual(rootDigestCount, minimumDigests, "Root level should have \(minimumDigests) digests")

    // Nested address object should also have 4 digests (1 real + 3 decoys)
    let addressObject = claimSet.value["address"]
    XCTAssertTrue(addressObject.exists(), "Address object should exist")
    let nestedDigestCount = addressObject["_sd"].arrayValue.count
    XCTAssertEqual(nestedDigestCount, minimumDigests, "Nested object should have \(minimumDigests) digests")
  }

  /// Test deeply nested objects
  func testPerObjectMinimum_DeeplyNested_AllLevelsMeetMinimum() {
    let minimumDigests = 3
    let config = DecoyConfiguration.perObject(minimum: minimumDigests)
    let factory = SDJWTFactory(decoyConfiguration: config)

    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "John")
      FlatDisclosedClaim("age", 30)
      ObjectClaim("address") {
        PlainClaim("country", "GR")
        FlatDisclosedClaim("city", "Athens")
        ObjectClaim("coordinates") {
          PlainClaim("system", "WGS84")
          FlatDisclosedClaim("lat", "37.9838")
        }
      }
    }

    let result = factory.createSDJWTPayload(sdJwtObject: sdObject.asObject)

    guard case .success(let claimSet) = result else {
      XCTFail("Failed to create payload")
      return
    }

    // Root level: 1 real disclosure
    let rootDigestCount = claimSet.value["_sd"].arrayValue.count
    XCTAssertGreaterThanOrEqual(rootDigestCount, minimumDigests, "Root should meet minimum")

    // Address level: 1 real disclosure
    let addressObject = claimSet.value["address"]
    XCTAssertTrue(addressObject.exists(), "Address object should exist")
    let addressDigestCount = addressObject["_sd"].arrayValue.count
    XCTAssertGreaterThanOrEqual(addressDigestCount, minimumDigests, "Address should meet minimum")

    // Coordinates level: 1 real disclosure
    let coordinatesObject = addressObject["coordinates"]
    XCTAssertTrue(coordinatesObject.exists(), "Coordinates object should exist")
    let coordsDigestCount = coordinatesObject["_sd"].arrayValue.count
    XCTAssertGreaterThanOrEqual(coordsDigestCount, minimumDigests, "Coordinates should meet minimum")
  }

  // MARK: - Backward Compatibility Tests

  /// Test that global limit still works (deprecated but functional)
  func testGlobalLimit_BackwardCompatibility() {
    let globalLimit = 10
    let factory = SDJWTFactory(decoysLimit: globalLimit)

    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "John")
      FlatDisclosedClaim("age", 30)
      FlatDisclosedClaim("email", "j@x.com")
    }

    let result = factory.createSDJWTPayload(sdJwtObject: sdObject.asObject)

    guard case .success(let claimSet) = result else {
      XCTFail("Failed to create payload")
      return
    }

    // Should have 2 real disclosures + some decoys (0 to 10 total decoys globally)
    let digestCount = claimSet.value.findDigestCount()
    XCTAssertGreaterThanOrEqual(digestCount, 2, "Should have at least 2 real disclosures")
    XCTAssertLessThanOrEqual(digestCount, 2 + globalLimit, "Should not exceed 2 real + 10 decoys")
  }

  /// Test that .none configuration produces no decoys
  func testNoneConfiguration_NoDecoys() {
    let config = DecoyConfiguration.none
    let factory = SDJWTFactory(decoyConfiguration: config)

    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "John")
      FlatDisclosedClaim("age", 30)
      FlatDisclosedClaim("email", "j@x.com")
    }

    let result = factory.createSDJWTPayload(sdJwtObject: sdObject.asObject)

    guard case .success(let claimSet) = result else {
      XCTFail("Failed to create payload")
      return
    }

    // Should have exactly 2 digests (2 real + 0 decoys)
    let digestCount = claimSet.value.findDigestCount()
    XCTAssertEqual(digestCount, 2, "Should have exactly 2 digests (no decoys)")
  }

  // MARK: - Edge Cases

  /// Test minimum = 0
  func testPerObjectMinimum_Zero_NoDecoys() {
    let config = DecoyConfiguration.perObject(minimum: 0)
    let factory = SDJWTFactory(decoyConfiguration: config)

    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "John")
      FlatDisclosedClaim("age", 30)
    }

    let result = factory.createSDJWTPayload(sdJwtObject: sdObject.asObject)

    guard case .success(let claimSet) = result else {
      XCTFail("Failed to create payload")
      return
    }

    // Should have exactly 1 digest (1 real + 0 decoys)
    let digestCount = claimSet.value.findDigestCount()
    XCTAssertEqual(digestCount, 1, "Should have exactly 1 digest")
  }

  /// Test large minimum value
  func testPerObjectMinimum_LargeValue_AddsManyDecoys() {
    let minimumDigests = 100
    let config = DecoyConfiguration.perObject(minimum: minimumDigests)
    let factory = SDJWTFactory(decoyConfiguration: config)

    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "John")
      FlatDisclosedClaim("age", 30)  // 1 real disclosure
    }

    let result = factory.createSDJWTPayload(sdJwtObject: sdObject.asObject)

    guard case .success(let claimSet) = result else {
      XCTFail("Failed to create payload")
      return
    }

    // Should have exactly 100 digests (1 real + 99 decoys)
    let digestCount = claimSet.value.findDigestCount()
    XCTAssertEqual(digestCount, minimumDigests, "Should have exactly \(minimumDigests) digests")
  }
}
