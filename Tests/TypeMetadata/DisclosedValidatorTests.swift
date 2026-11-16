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
import XCTest
@testable import eudi_lib_sdjwt_swift

final class DisclosedValidatorTests: XCTestCase {

  func testValidate_missingMetadata_throwsError() {
    //Given
    let sut = DisclosureValidator()
    
    // When
    XCTAssertThrowsError(try sut.validate(nil, [:])) { error in
      // Then
      XCTAssertEqual(error as? TypeMetadataError, .missingTypeMetadata)
    }
  }

  func testValidate_missingDisclosures_throwsError() {
    
    //Given
    let sut = DisclosureValidator()
    let metadata = ResolvedTypeMetadata(
      vct: "type",
      claims: []
    )
    
    // When
    XCTAssertThrowsError(try sut.validate(metadata, nil)) { error in
      // Then
      XCTAssertEqual(error as? TypeMetadataError, .missingDisclosuresForValidation)
    }
  }

  func testValidate_disclosureExpectedButMissing_throwsError() {
    
    // Given
    let claimPath = ClaimPath([.claim(name: "email")])
    let claim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: claimPath,
      selectivelyDisclosable: .always
    )
    
    let metadata = ResolvedTypeMetadata(
      vct: "vct",
      claims: [claim]
    )
    
    let disclosures: DisclosuresPerClaimPath = [:]
    let sut = DisclosureValidator()
    
    // When
    XCTAssertThrowsError(try sut.validate(metadata, disclosures)) { error in
      // Then
      XCTAssertEqual(error as? TypeMetadataError, .expectedDisclosureMissing(path: claimPath))
    }
  }

  func testValidate_disclosurePresentWhenNotAllowed_throwsError() {
    
    //Given
    let claimPath = ClaimPath([.claim(name: "iss")])
    let claim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: claimPath,
      selectivelyDisclosable: .never
    )
    
    let metadata = ResolvedTypeMetadata(
      vct: "vct",
      claims: [claim])
    
    let disclosures: DisclosuresPerClaimPath = [claimPath: ["disclosure_value"]]
    let sut = DisclosureValidator()
    
    // When
    XCTAssertThrowsError(try sut.validate(metadata, disclosures)) { error in
      // Then
      XCTAssertEqual(error as? TypeMetadataError, .unexpectedDisclosurePresent(path: claimPath))
    }
  }

  func testValidate_disclosureAllowedButOptional_passes() throws {
    
    //Given
    let claimPath = ClaimPath([.claim(name: "nickname")])
    let claim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: claimPath,
      selectivelyDisclosable: .allowed
    )
    
    let metadata = ResolvedTypeMetadata(
      vct: "vct",
      claims: [claim]
    )
    
    let disclosures: DisclosuresPerClaimPath = [:]
    let sut = DisclosureValidator()
    
    // When/Then
    XCTAssertNoThrow(try sut.validate(metadata, disclosures))
  }

  func testValidate_disclosurePresentWhenRequired_passes() throws {
    
    // Given
    let claimPath = ClaimPath([.claim(name: "email")])
    let claim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: claimPath,
      selectivelyDisclosable: .always
    )
    
    let metadata = ResolvedTypeMetadata(
      vct: "vct",
      claims: [claim]
    )
    
    let disclosures: DisclosuresPerClaimPath = [claimPath: ["user@example.com"]]
    let sut = DisclosureValidator()
    
    // When/Then
    XCTAssertNoThrow(try sut.validate(metadata, disclosures))
  }
  
  func testValidate_registeredClaimDisclosurePresent_throwsError() {
    
    // Registered claim that must NOT be disclosed (e.g. "vct#integrity")
    let claimPath = ClaimPath([.claim(name: "vct#integrity")])
    let disclosures: DisclosuresPerClaimPath = [claimPath: ["someDisclosureValue"]]
    let metadata = ResolvedTypeMetadata(vct: "vct", claims: [])
    
    let sut = DisclosureValidator()
    
    // When / Then
    XCTAssertThrowsError(try sut.validate(metadata, disclosures)) { error in
      // The validator should flag the unexpected disclosure for a registered claim
      XCTAssertEqual(error as? TypeMetadataError, .unexpectedDisclosurePresent(path: claimPath))
    }
  }

  // ClaimVisitor records plain (non-disclosed) primitive leaves with an
  // empty-string placeholder in the disclosures map. The validator must
  // treat those as "not actually disclosed" when evaluating sd:always,
  // sd:never and the registered-claims rule.

  func testValidate_sdAlways_claimPresentAsPlainPlaceholder_throwsExpectedMissing() {
    // sd:always claim is plain in the token -> visitor records a
    // placeholder entry [""]. Validator must still require a real
    // disclosure (empty string does not count).
    let claimPath = ClaimPath([.claim(name: "email")])
    let claim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: claimPath,
      selectivelyDisclosable: .always
    )
    let metadata = ResolvedTypeMetadata(vct: "vct", claims: [claim])
    let disclosures: DisclosuresPerClaimPath = [claimPath: [""]]  // placeholder

    let sut = DisclosureValidator()

    XCTAssertThrowsError(try sut.validate(metadata, disclosures)) { error in
      XCTAssertEqual(error as? TypeMetadataError, .expectedDisclosureMissing(path: claimPath))
    }
  }

  func testValidate_sdNever_claimPresentAsPlainPlaceholder_passes() {
    // sd:never claim correctly left plain in the token. Visitor records a
    // placeholder entry [""]. Validator must NOT misinterpret the
    // placeholder as a disclosure.
    let claimPath = ClaimPath([.claim(name: "nickname")])
    let claim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: claimPath,
      selectivelyDisclosable: .never
    )
    let metadata = ResolvedTypeMetadata(vct: "vct", claims: [claim])
    let disclosures: DisclosuresPerClaimPath = [claimPath: [""]]  // placeholder

    let sut = DisclosureValidator()

    XCTAssertNoThrow(try sut.validate(metadata, disclosures))
  }

  func testValidate_registeredClaimAsPlainPlaceholder_passes() {
    // Registered claim at root but only recorded as a placeholder (plain
    // in the token). Must not throw.
    let claimPath = ClaimPath([.claim(name: "iss")])
    let disclosures: DisclosuresPerClaimPath = [claimPath: [""]]  // placeholder
    let metadata = ResolvedTypeMetadata(vct: "vct", claims: [])

    let sut = DisclosureValidator()

    XCTAssertNoThrow(try sut.validate(metadata, disclosures))
  }

  func testValidate_registeredClaimNameNestedNotAtRoot_passes() {
    // A nested property named like a registered claim (e.g. foo.iss) is
    // not the registered claim itself and must not be rejected even if
    // disclosed. Only the root element matters.
    let claimPath = ClaimPath([.claim(name: "foo"), .claim(name: "iss")])
    let disclosures: DisclosuresPerClaimPath = [claimPath: ["real_disclosure_value"]]
    let metadata = ResolvedTypeMetadata(vct: "vct", claims: [])

    let sut = DisclosureValidator()

    XCTAssertNoThrow(try sut.validate(metadata, disclosures))
  }

  func testValidate_sdNeverWildcardArrayPath_withRealDisclosure_throws() {
    // metadata path with array wildcard
    // ($.credentials[*].role) was unenforceable under .never because the
    // old code used exact dictionary lookup. The fix uses containment
    // matching, so a real disclosure at a concrete index must be flagged.
    let metadataPath = ClaimPath([
      .claim(name: "credentials"),
      .allArrayElements,
      .claim(name: "role")
    ])
    let claim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: metadataPath,
      selectivelyDisclosable: .never
    )
    let metadata = ResolvedTypeMetadata(vct: "vct", claims: [claim])

    let recordedPath = ClaimPath([
      .claim(name: "credentials"),
      .arrayElement(index: 0),
      .claim(name: "role")
    ])
    let disclosures: DisclosuresPerClaimPath = [recordedPath: ["real_disclosure"]]

    let sut = DisclosureValidator()

    XCTAssertThrowsError(try sut.validate(metadata, disclosures)) { error in
      XCTAssertEqual(error as? TypeMetadataError, .unexpectedDisclosurePresent(path: metadataPath))
    }
  }

  func testValidate_sdNeverWildcardArrayPath_withOnlyPlaceholders_passes() {
    // Same wildcard-path setup but only placeholder entries recorded
    // (i.e. the role sub-field was present as plain in each credential).
    // Must pass.
    let metadataPath = ClaimPath([
      .claim(name: "credentials"),
      .allArrayElements,
      .claim(name: "role")
    ])
    let claim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: metadataPath,
      selectivelyDisclosable: .never
    )
    let metadata = ResolvedTypeMetadata(vct: "vct", claims: [claim])

    let recordedPath = ClaimPath([
      .claim(name: "credentials"),
      .arrayElement(index: 0),
      .claim(name: "role")
    ])
    let disclosures: DisclosuresPerClaimPath = [recordedPath: [""]]  // placeholder

    let sut = DisclosureValidator()

    XCTAssertNoThrow(try sut.validate(metadata, disclosures))
  }

  func testValidate_sdAlwaysWildcardArrayPath_withRealDisclosure_passes() {
    // Positive wildcard-path case for sd:always: a real disclosure at a
    // concrete array index satisfies the metadata path with [*].
    let metadataPath = ClaimPath([
      .claim(name: "credentials"),
      .allArrayElements,
      .claim(name: "role")
    ])
    let claim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: metadataPath,
      selectivelyDisclosable: .always
    )
    let metadata = ResolvedTypeMetadata(vct: "vct", claims: [claim])

    let recordedPath = ClaimPath([
      .claim(name: "credentials"),
      .arrayElement(index: 0),
      .claim(name: "role")
    ])
    let disclosures: DisclosuresPerClaimPath = [recordedPath: ["real_disclosure"]]

    let sut = DisclosureValidator()

    XCTAssertNoThrow(try sut.validate(metadata, disclosures))
  }
}
