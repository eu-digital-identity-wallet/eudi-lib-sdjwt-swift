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

/// Regression tests for SDJWT_17: error descriptions must not leak the
/// claim data they are supposed to protect.
///
/// Swift's default error description prints each case's associated values
/// verbatim. For cases carrying raw disclosures or whole claim JSON, that
/// means the claim payload ends up in logs and crash reports.
final class ErrorRedactionTest: XCTestCase {

  // MARK: - SDJWTVerifierError

  func testInvalidDisclosure_DescriptionDoesNotLeakDisclosureContent() {
    // Realistic disclosure: base64url of ["salt","given_name","Alice"].
    let secretDisclosure = "WyJzYWx0IiwgImdpdmVuX25hbWUiLCAiQWxpY2UiXQ"
    let error = SDJWTVerifierError.invalidDisclosure(disclosures: [secretDisclosure])

    let desc = String(describing: error)
    let interpolated = "\(error)"
    let debug = String(reflecting: error)

    for rendered in [desc, interpolated, debug] {
      XCTAssertFalse(rendered.contains(secretDisclosure), "Raw disclosure leaked: \(rendered)")
      XCTAssertFalse(rendered.contains("Alice"), "Decoded claim value leaked: \(rendered)")
      XCTAssertTrue(rendered.contains("REDACTED"), "Expected REDACTED marker: \(rendered)")
      XCTAssertTrue(rendered.contains("invalidDisclosure"), "Case name must remain for diagnosability: \(rendered)")
      XCTAssertTrue(rendered.contains("count: 1"), "Count must be exposed for diagnosability: \(rendered)")
    }
  }

  func testMissingDigests_DescriptionDoesNotLeakDisclosureContent() {
    let secretDisclosure = "WyJzYWx0IiwgInNzbiIsICIxMjMtNDUtNjc4OSJd"
    let error = SDJWTVerifierError.missingDigests(disclosures: [secretDisclosure, secretDisclosure])

    let desc = String(describing: error)
    XCTAssertFalse(desc.contains(secretDisclosure))
    XCTAssertFalse(desc.contains("ssn"))
    XCTAssertTrue(desc.contains("REDACTED"))
    XCTAssertTrue(desc.contains("missingDigests"))
    XCTAssertTrue(desc.contains("count: 2"))
  }

  func testNonSensitiveCase_RendersCaseName() {
    XCTAssertEqual(String(describing: SDJWTVerifierError.parsingError), "parsingError")
    XCTAssertEqual(String(describing: SDJWTVerifierError.expiredJwt), "expiredJwt")
    XCTAssertEqual(String(describing: SDJWTVerifierError.invalidJwt(description: "bad typ")), "invalidJwt(bad typ)")
  }

  // MARK: - SDJWTError

  func testNonObjectFormat_DescriptionDoesNotLeakElement() {
    // ofElement is the serialised sdJwtObject -- contains claim values.
    let secretClaimJson = "{\"family_name\":\"Snowden\",\"ssn\":\"123-45-6789\"}"
    let error = SDJWTError.nonObjectFormat(ofElement: secretClaimJson)

    let desc = String(describing: error)
    let debug = String(reflecting: error)

    for rendered in [desc, debug] {
      XCTAssertFalse(rendered.contains("Snowden"), "Claim value leaked: \(rendered)")
      XCTAssertFalse(rendered.contains("ssn"), "Claim key leaked: \(rendered)")
      XCTAssertFalse(rendered.contains("123-45-6789"), "Claim value leaked: \(rendered)")
      XCTAssertTrue(rendered.contains("REDACTED"), "Expected REDACTED marker: \(rendered)")
      XCTAssertTrue(rendered.contains("nonObjectFormat"), "Case name must remain: \(rendered)")
    }
  }

  func testSDJWTError_NonSensitiveCase_RendersCaseName() {
    XCTAssertEqual(String(describing: SDJWTError.keyCreation), "keyCreation")
    XCTAssertEqual(String(describing: SDJWTError.randomGenerationFailed), "randomGenerationFailed")
    XCTAssertEqual(String(describing: SDJWTError.error("boom")), "error(boom)")
  }
}
