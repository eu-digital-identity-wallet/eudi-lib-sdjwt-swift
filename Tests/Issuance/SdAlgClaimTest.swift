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

/// Regression tests for SDJWT_15: `_sd_alg` type validation.
///
/// Before the fix, a non-string `_sd_alg` (number, array, object, null)
/// silently defaulted to `"sha-256"` because SwiftyJSON's `.string`
/// returns `nil` for wrong types. The extractor now distinguishes
/// "absent" from "present but wrong type" and rejects the latter.
final class SdAlgClaimTest: XCTestCase {

  // MARK: - Absent

  func testExtractSdAlg_MissingClaim_DefaultsToSha256() throws {
    let payload: JSON = ["some_other_field": "value"]
    XCTAssertEqual(try SDJWT.extractSdAlgClaim(from: payload), "sha-256")
  }

  // MARK: - Present, valid

  func testExtractSdAlg_StringSha256_Passes() throws {
    let payload: JSON = ["_sd_alg": "sha-256"]
    XCTAssertEqual(try SDJWT.extractSdAlgClaim(from: payload), "sha-256")
  }

  func testExtractSdAlg_StringSha512_Passes() throws {
    let payload: JSON = ["_sd_alg": "sha-512"]
    XCTAssertEqual(try SDJWT.extractSdAlgClaim(from: payload), "sha-512")
  }

  // MARK: - Present, invalid type

  func testExtractSdAlg_NumberValue_ThrowsMissingOrUnknown() {
    let payload: JSON = ["_sd_alg": 42]
    XCTAssertThrowsError(try SDJWT.extractSdAlgClaim(from: payload)) { error in
      guard case SDJWTVerifierError.missingOrUnknownHashingAlgorithm = error else {
        XCTFail("Expected missingOrUnknownHashingAlgorithm, got \(error)"); return
      }
    }
  }

  func testExtractSdAlg_ArrayValue_ThrowsMissingOrUnknown() {
    let payload: JSON = ["_sd_alg": ["sha-256"]]
    XCTAssertThrowsError(try SDJWT.extractSdAlgClaim(from: payload)) { error in
      guard case SDJWTVerifierError.missingOrUnknownHashingAlgorithm = error else {
        XCTFail("Expected missingOrUnknownHashingAlgorithm, got \(error)"); return
      }
    }
  }

  func testExtractSdAlg_ObjectValue_ThrowsMissingOrUnknown() {
    let payload: JSON = ["_sd_alg": ["alg": "sha-256"]]
    XCTAssertThrowsError(try SDJWT.extractSdAlgClaim(from: payload)) { error in
      guard case SDJWTVerifierError.missingOrUnknownHashingAlgorithm = error else {
        XCTFail("Expected missingOrUnknownHashingAlgorithm, got \(error)"); return
      }
    }
  }

  func testExtractSdAlg_NullValue_ThrowsMissingOrUnknown() {
    let payload: JSON = ["_sd_alg": NSNull()]
    XCTAssertThrowsError(try SDJWT.extractSdAlgClaim(from: payload)) { error in
      guard case SDJWTVerifierError.missingOrUnknownHashingAlgorithm = error else {
        XCTFail("Expected missingOrUnknownHashingAlgorithm, got \(error)"); return
      }
    }
  }

  // MARK: - Present, unknown string

  func testExtractSdAlg_UnknownStringValue_ReturnsIt() throws {
    // Unknown but syntactically valid strings are passed through here; the
    // caller checks membership in HashingAlgorithmIdentifier.allCases.
    let payload: JSON = ["_sd_alg": "sha-999"]
    XCTAssertEqual(try SDJWT.extractSdAlgClaim(from: payload), "sha-999")
  }
}
