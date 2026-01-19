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
import XCTest

@testable import eudi_lib_sdjwt_swift


final class TypeMetadataMergerTests: XCTestCase {
  
  func test_mergeMetadata_withChildAndParentMetadata_mergesFieldsCorrectly() async throws {
    
    // Given
    let childMetada = SDJWTConstants.childMetadata
    let parentMetadata = SDJWTConstants.parentMetadata
    
    let sut = TypeMetadataMerger()
    let mergedMetadata = try sut.mergeMetadata(from: [childMetada, parentMetadata])
    
    guard let mergedMetadata else {
      XCTFail("Merged metadata should not be nil")
      return
    }
    XCTAssertEqual(mergedMetadata.vct, "child_vct")
    XCTAssertEqual(mergedMetadata.name, "child_name")
    XCTAssertEqual(mergedMetadata.description, "child_description")
    XCTAssertEqual(mergedMetadata.displays.count, 4)
    XCTAssertEqual(mergedMetadata.claims.count, 4)
    
    XCTAssertEqual(mergedMetadata.displays[0].locale, "child_display_1_lang")
    XCTAssertEqual(mergedMetadata.displays[1].locale, "child_display_2_lang")
    
    XCTAssertEqual(mergedMetadata.displays[2].locale, "parent_display_1_lang")
    XCTAssertEqual(mergedMetadata.displays[3].locale, "parent_display_2_lang")
    
    XCTAssertEqual(mergedMetadata.claims[0].path, ClaimPath([.claim(name: "child_claims_1_path")]))
    XCTAssertEqual(mergedMetadata.claims[0].display?.count, 3)
    XCTAssertEqual(mergedMetadata.claims[1].path, ClaimPath([.claim(name: "child_claims_2_path")]))
    XCTAssertEqual(mergedMetadata.claims[1].display?.count, 3)
    
    XCTAssertEqual(mergedMetadata.claims[2].path, ClaimPath([.claim(name: "parent_claims_1_path")]))
    XCTAssertEqual(mergedMetadata.claims[2].display?.count, 3)
    XCTAssertEqual(mergedMetadata.claims[3].path, ClaimPath([.claim(name: "parent_claims_2_path")]))
    XCTAssertEqual(mergedMetadata.claims[3].display?.count, 3)
    
    
    // Extra random nested asserts
    XCTAssertEqual(mergedMetadata.displays[0].rendering?.svgTemplates?.first?.properties?.orientation,
                   "child_display_1_rendering_svgTemplates_properties_orientation")
    XCTAssertEqual(mergedMetadata.displays[2].rendering?.simple?.logo?.uri.absoluteString,
                   "parent_display_1_rendering_simple_logo_uri")
    XCTAssertEqual(mergedMetadata.displays[1].rendering?.simple?.backgroundColor,
                   "child_display_2_rendering_simple_backgroundColor")
    XCTAssertEqual(mergedMetadata.claims[3].selectivelyDisclosable, .always)
    XCTAssertEqual(mergedMetadata.claims[0].display?[1].label, "child_claims_1_display_2_label")
    
  }
  
  func test_mergeMetadata_whenChildAndParentHaveSameLangDisplay_childWins() throws {
    // Given
    let childDisplay = SdJwtVcTypeMetadata.DisplayMetadata(
      locale: "en",
      name: "child_name",
      description: "child_description",
      rendering: nil
    )
    
    let parentDisplay = SdJwtVcTypeMetadata.DisplayMetadata(
      locale: "en",
      name: "parent_name",
      description: "parent_description",
      rendering: nil
    )
    
    let childMetadata = ResolvedTypeMetadata(
      vct: "child_vct",
      name: nil,
      description: nil,
      displays: [childDisplay],
      claims: []
    )
    
    let parentMetadata = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: nil,
      description: nil,
      displays: [parentDisplay],
      claims: []
    )
    
    let sut = TypeMetadataMerger()
    
    // When
    let merged = try sut.mergeMetadata(from: [childMetadata, parentMetadata])
    
    // Then
    XCTAssertEqual(merged?.displays.count, 1)
    XCTAssertEqual(merged?.displays.first?.locale, "en")
    XCTAssertEqual(merged?.displays.first?.name, "child_name")
    XCTAssertEqual(merged?.displays.first?.description, "child_description")
  }
  
  func test_mergeMetadata_withEmptyArray_returnsNil() throws {
    let sut = TypeMetadataMerger()
    let result = try sut.mergeMetadata(from: [])
    XCTAssertNil(result)
  }
  
  func test_mergeMetadata_withSingleMetadata_returnsItself() throws {
    let metadata = ResolvedTypeMetadata(
      vct: "vct_test",
      name: "Test Name",
      description: "Test Description",
      displays: [],
      claims: []
    )
    let sut = TypeMetadataMerger()
    let result = try sut.mergeMetadata(from: [metadata])
    XCTAssertEqual(result?.vct, "vct_test")
    XCTAssertEqual(result?.name, "Test Name")
    XCTAssertEqual(result?.description, "Test Description")
  }
  
  func test_mergeMetadata_childMissingName_parentUsedInstead() throws {
    let child = ResolvedTypeMetadata(
      vct: "child_vct", name: nil, description: nil, displays: [], claims: []
    )
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct", name: "Parent Name", description: "Parent Desc", displays: [], claims: []
    )
    let result = try TypeMetadataMerger().mergeMetadata(from: [child, parent])
    XCTAssertEqual(result?.name, "Parent Name")
    XCTAssertEqual(result?.description, "Parent Desc")
  }
  
  func test_mergeMetadata_withConflictingClaimPath_childClaimWins() throws {
    // Child claim with same path but different selectivelyDisclosable and svgId
    // Changed parent from .never to .allowed so child can legitimately tighten to .always
    let childClaim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: ClaimPath([.claim(name: "same_path")]),
      display: [SdJwtVcTypeMetadata.ClaimDisplay(locale: "en", label: "Child Label")],
      selectivelyDisclosable: .always,
      svgId: "child_svg"
    )
    
    let parentClaim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: ClaimPath([.claim(name: "same_path")]),
      display: [SdJwtVcTypeMetadata.ClaimDisplay(locale: "en", label: "Parent Label")],
      selectivelyDisclosable: .never,
      svgId: "parent_svg"
    )
    
    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: nil,
      description: nil,
      displays: [],
      claims: [childClaim]
    )
    
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: nil,
      description: nil,
      displays: [],
      claims: [parentClaim]
    )

    let merged = try TypeMetadataMerger().mergeMetadata(from: [child, parent])

    XCTAssertEqual(merged?.claims.count, 1)
    let mergedClaim = merged?.claims.first
    XCTAssertEqual(mergedClaim?.path, ClaimPath([.claim(name: "same_path")]))
    XCTAssertEqual(mergedClaim?.selectivelyDisclosable, .always) // child wins
    XCTAssertEqual(mergedClaim?.svgId, "child_svg") // child wins
    XCTAssertEqual(mergedClaim?.display?.first?.label, "Child Label") // child's display wins
  }

  func test_mergeMetadata_withConflictingClaimPath_childFullyOverridesParentDisplay() throws {
    
    let childClaim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: ClaimPath([.claim(name: "same_path")]),
      display: [
        SdJwtVcTypeMetadata.ClaimDisplay(locale: "en", label: "Child Label EN")
      ],
      selectivelyDisclosable: .always,
      svgId: "child_svg"
    )
    
    let parentClaim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: ClaimPath([.claim(name: "same_path")]),
      display: [
        SdJwtVcTypeMetadata.ClaimDisplay(locale: "en", label: "Parent Label EN"),
        SdJwtVcTypeMetadata.ClaimDisplay(locale: "fr", label: "Parent Label FR")
      ],
      selectivelyDisclosable: .allowed, // Changed from .never to .allowed
      svgId: "parent_svg"
    )
    
    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: nil,
      description: nil,
      displays: [],
      claims: [childClaim]
    )
    
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: nil,
      description: nil,
      displays: [],
      claims: [parentClaim]
    )
    
    let merged = try TypeMetadataMerger().mergeMetadata(from: [child, parent])
    
    // Child claim fully overrides parent
    XCTAssertEqual(merged?.claims.count, 1)
    let mergedClaim = merged?.claims.first
    
    // Only child's displays should be present (no French from parent)
    XCTAssertEqual(mergedClaim?.display?.count, 1)
    XCTAssertEqual(mergedClaim?.display?.first?.locale, "en")
    XCTAssertEqual(mergedClaim?.display?.first?.label, "Child Label EN")
    
    // Parent's French display should NOT be present
    XCTAssertFalse(mergedClaim?.display?.contains(where: { $0.locale == "fr" }) ?? true)
    
    // All child properties win
    XCTAssertEqual(mergedClaim?.selectivelyDisclosable, .always)
    XCTAssertEqual(mergedClaim?.svgId, "child_svg")
  }
  
  func test_mergeMetadata_parentDisplaysAppended() throws {
    let childDisplay = SdJwtVcTypeMetadata.DisplayMetadata(
      locale: "en",
      name: "Child Name",
      description: "Child Desc",
      rendering: nil
    )
    
    let parentDisplay = SdJwtVcTypeMetadata.DisplayMetadata(
      locale: "fr",
      name: "Parent Name",
      description: "Parent Desc",
      rendering: nil
    )
    
    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: nil,
      description: nil,
      displays: [childDisplay],
      claims: []
    )
    
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: nil,
      description: nil,
      displays: [parentDisplay],
      claims: []
    )
    
    let merged = try TypeMetadataMerger().mergeMetadata(from: [child, parent])
    
    XCTAssertEqual(merged?.displays.count, 2)
    XCTAssertTrue(merged?.displays.contains(where: { $0.locale == "en" }) ?? false)
    XCTAssertTrue(merged?.displays.contains(where: { $0.locale == "fr" }) ?? false)
  }
  
  func test_mergeMetadata_parentClaimsAppended() throws {
    let childClaim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: ClaimPath([.claim(name: "child_path")]),
      display: [SdJwtVcTypeMetadata.ClaimDisplay(locale: "en", label: "Child Label")],
      selectivelyDisclosable: .allowed,
      svgId: "child_svg"
    )
    
    let parentClaim = SdJwtVcTypeMetadata.ClaimMetadata(
      path: ClaimPath([.claim(name: "parent_path")]),
      display: [SdJwtVcTypeMetadata.ClaimDisplay(locale: "en", label: "Parent Label")],
      selectivelyDisclosable: .never,
      svgId: "parent_svg"
    )
    
    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: nil,
      description: nil,
      displays: [],
      claims: [childClaim]
    )
    
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: nil,
      description: nil,
      displays: [],
      claims: [parentClaim]
    )
    
    let merged = try TypeMetadataMerger().mergeMetadata(from: [child, parent])
    
    XCTAssertEqual(merged?.claims.count, 2)
    XCTAssertTrue(merged?.claims.contains(where: { $0.path == ClaimPath([.claim(name: "child_path")]) }) ?? false)
    XCTAssertTrue(merged?.claims.contains(where: { $0.path == ClaimPath([.claim(name: "parent_path")]) }) ?? false)
  }

  func test_mergeMetadata_whenChildAndParentHaveSameMandatoryTrue_shouldSucceed() throws {
    // Given: Both parent and child have mandatory = true
    let testClaimPath = ClaimPath([.claim(name: "testClaim")])
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: "Parent",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: true,
          selectivelyDisclosable: .allowed
        )
      ]
    )

    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: "Child",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: true,
          selectivelyDisclosable: .allowed
        )
      ]
    )

    // When
    let result = try TypeMetadataMerger().mergeMetadata(from: [child, parent])

    // Then
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.claims.count, 1)
    XCTAssertTrue(result?.claims.first?.mandatory ?? false)
  }

  func test_mergeMetadata_whenChildTightensMandatoryConstraint_shouldSucceed() throws {
    // Given: Child has mandatory = true, parent has mandatory = false
    // This is valid: child is tightening the constraint
    let testClaimPath = ClaimPath([.claim(name: "testClaim")])
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: "Parent",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .allowed
        )
      ]
    )

    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: "Child",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: true,
          selectivelyDisclosable: .allowed
        )
      ]
    )

    // When
    let result = try TypeMetadataMerger().mergeMetadata(from: [child, parent])

    // Then
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.claims.count, 1)
    XCTAssertTrue(result?.claims.first?.mandatory ?? false)
  }

  func test_mergeMetadata_whenChildRelaxesMandatoryConstraint_shouldThrowError() {
    // Given: Parent has mandatory = true, child tries to override to false
    let testClaimPath = ClaimPath([.claim(name: "testClaim")])
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: "Parent",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: true,
          selectivelyDisclosable: .allowed
        )
      ]
    )

    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: "Child",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .allowed
        )
      ]
    )

    // When/Then: Should throw mandatoryPropertyOverrideNotAllowed error
    let merger = TypeMetadataMerger()
    XCTAssertThrowsError(try merger.mergeMetadata(from: [child, parent])) { error in
      guard case TypeMetadataError.mandatoryPropertyOverrideNotAllowed(let path) = error else {
        XCTFail("Expected mandatoryPropertyOverrideNotAllowed error, got \(error)")
        return
      }
      XCTAssertEqual(path, testClaimPath)
    }
  }

  func test_mergeMetadata_whenBothHaveSDAlways_shouldSucceed() throws {
    // Given: Both parent and child have sd = always
    let testClaimPath = ClaimPath([.claim(name: "testClaim")])
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: "Parent",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .always
        )
      ]
    )

    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: "Child",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .always
        )
      ]
    )

    // When
    let result = try TypeMetadataMerger().mergeMetadata(from: [child, parent])

    // Then
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.claims.count, 1)
    XCTAssertEqual(result?.claims.first?.selectivelyDisclosable, .always)
  }

  func test_mergeMetadata_whenChildTightensSDFromAllowedToAlways_shouldSucceed() throws {
    // Given: Parent has sd = allowed, child has sd = always
    // This is valid: child is tightening the constraint
    let testClaimPath = ClaimPath([.claim(name: "testClaim")])
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: "Parent",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .allowed
        )
      ]
    )

    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: "Child",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .always
        )
      ]
    )

    // When
    let result = try TypeMetadataMerger().mergeMetadata(from: [child, parent])

    // Then
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.claims.count, 1)
    XCTAssertEqual(result?.claims.first?.selectivelyDisclosable, .always)
  }

  func test_mergeMetadata_whenChildRelaxesSDFromAlwaysToAllowed_shouldThrowError() {
    // Given: Parent has sd = always, child tries to override to allowed
    let testClaimPath = ClaimPath([.claim(name: "testClaim")])
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: "Parent",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .always
        )
      ]
    )

    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: "Child",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .allowed
        )
      ]
    )

    // When/Then: Should throw selectivelyDisclosablePropertyOverrideNotAllowed error
    let merger = TypeMetadataMerger()
    XCTAssertThrowsError(try merger.mergeMetadata(from: [child, parent])) { error in
      guard case TypeMetadataError.selectivelyDisclosablePropertyOverrideNotAllowed(let path) = error else {
        XCTFail("Expected selectivelyDisclosablePropertyOverrideNotAllowed error, got \(error)")
        return
      }
      XCTAssertEqual(path, testClaimPath)
    }
  }

  func test_mergeMetadata_whenBothHaveSDNever_shouldSucceed() throws {
    // Given: Both parent and child have sd = never
    let testClaimPath = ClaimPath([.claim(name: "testClaim")])
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: "Parent",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .never
        )
      ]
    )

    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: "Child",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .never
        )
      ]
    )

    // When
    let result = try TypeMetadataMerger().mergeMetadata(from: [child, parent])

    // Then
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.claims.count, 1)
    XCTAssertEqual(result?.claims.first?.selectivelyDisclosable, .never)
  }

  func test_mergeMetadata_whenChildRelaxesSDFromNeverToAllowed_shouldThrowError() {
    // Given: Parent has sd = never, child tries to override to allowed
    let testClaimPath = ClaimPath([.claim(name: "testClaim")])
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: "Parent",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .never
        )
      ]
    )

    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: "Child",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .allowed
        )
      ]
    )

    // When/Then: Should throw selectivelyDisclosablePropertyOverrideNotAllowed error
    let merger = TypeMetadataMerger()
    XCTAssertThrowsError(try merger.mergeMetadata(from: [child, parent])) { error in
      guard case TypeMetadataError.selectivelyDisclosablePropertyOverrideNotAllowed(let path) = error else {
        XCTFail("Expected selectivelyDisclosablePropertyOverrideNotAllowed error, got \(error)")
        return
      }
      XCTAssertEqual(path, testClaimPath)
    }
  }

  func test_mergeMetadata_whenChildTightensBothMandatoryAndSD_shouldSucceed() throws {
    // Given: Valid combination - child tightens both constraints
    let testClaimPath = ClaimPath([.claim(name: "testClaim")])
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct",
      name: "Parent",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: false,
          selectivelyDisclosable: .allowed
        )
      ]
    )

    let child = ResolvedTypeMetadata(
      vct: "child_vct",
      name: "Child",
      description: nil,
      displays: [],
      claims: [
        SdJwtVcTypeMetadata.ClaimMetadata(
          path: testClaimPath,
          mandatory: true,
          selectivelyDisclosable: .always
        )
      ]
    )

    // When
    let result = try TypeMetadataMerger().mergeMetadata(from: [child, parent])

    // Then
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.claims.count, 1)
    let claim = result?.claims.first
    XCTAssertTrue(claim?.mandatory ?? false)
    XCTAssertEqual(claim?.selectivelyDisclosable, .always)
  }
}
