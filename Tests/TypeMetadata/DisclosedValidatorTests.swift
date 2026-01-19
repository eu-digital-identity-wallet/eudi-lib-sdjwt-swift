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
}
