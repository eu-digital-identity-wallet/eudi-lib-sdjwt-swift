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
    let mergedMetadata = sut.mergeMetadata(from: [childMetada, parentMetadata])
    
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
    let merged = sut.mergeMetadata(from: [childMetadata, parentMetadata])
    
    // Then
    XCTAssertEqual(merged?.displays.count, 1)
    XCTAssertEqual(merged?.displays.first?.locale, "en")
    XCTAssertEqual(merged?.displays.first?.name, "child_name")
    XCTAssertEqual(merged?.displays.first?.description, "child_description")
  }
  
  func test_mergeMetadata_withEmptyArray_returnsNil() {
    let sut = TypeMetadataMerger()
    let result = sut.mergeMetadata(from: [])
    XCTAssertNil(result)
  }
  
  func test_mergeMetadata_withSingleMetadata_returnsItself() {
    let metadata = ResolvedTypeMetadata(
      vct: "vct_test",
      name: "Test Name",
      description: "Test Description",
      displays: [],
      claims: []
    )
    let sut = TypeMetadataMerger()
    let result = sut.mergeMetadata(from: [metadata])
    XCTAssertEqual(result?.vct, "vct_test")
    XCTAssertEqual(result?.name, "Test Name")
    XCTAssertEqual(result?.description, "Test Description")
  }
  
  func test_mergeMetadata_childMissingName_parentUsedInstead() {
    let child = ResolvedTypeMetadata(
      vct: "child_vct", name: nil, description: nil, displays: [], claims: []
    )
    let parent = ResolvedTypeMetadata(
      vct: "parent_vct", name: "Parent Name", description: "Parent Desc", displays: [], claims: []
    )
    let result = TypeMetadataMerger().mergeMetadata(from: [child, parent])
    XCTAssertEqual(result?.name, "Parent Name")
    XCTAssertEqual(result?.description, "Parent Desc")
  }
  
  func test_mergeMetadata_withConflictingClaimPath_childClaimWins() {
    // Child claim with same path but different selectivelyDisclosable and svgId
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
    
    let merged = TypeMetadataMerger().mergeMetadata(from: [child, parent])
    
    XCTAssertEqual(merged?.claims.count, 1)
    let mergedClaim = merged?.claims.first
    XCTAssertEqual(mergedClaim?.path, ClaimPath([.claim(name: "same_path")]))
    XCTAssertEqual(mergedClaim?.selectivelyDisclosable, .always) // child wins
    XCTAssertEqual(mergedClaim?.svgId, "child_svg") // child wins
    XCTAssertEqual(mergedClaim?.display?.first?.label, "Child Label") // child's display wins
  }

  func test_mergeMetadata_withConflictingClaimPath_childFullyOverridesParentDisplay() {
    
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
    
    let merged = TypeMetadataMerger().mergeMetadata(from: [child, parent])
    
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
  
  func test_mergeMetadata_parentDisplaysAppended() {
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
    
    let merged = TypeMetadataMerger().mergeMetadata(from: [child, parent])
    
    XCTAssertEqual(merged?.displays.count, 2)
    XCTAssertTrue(merged?.displays.contains(where: { $0.locale == "en" }) ?? false)
    XCTAssertTrue(merged?.displays.contains(where: { $0.locale == "fr" }) ?? false)
  }
  
  func test_mergeMetadata_parentClaimsAppended() {
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
    
    let merged = TypeMetadataMerger().mergeMetadata(from: [child, parent])
    
    XCTAssertEqual(merged?.claims.count, 2)
    XCTAssertTrue(merged?.claims.contains(where: { $0.path == ClaimPath([.claim(name: "child_path")]) }) ?? false)
    XCTAssertTrue(merged?.claims.contains(where: { $0.path == ClaimPath([.claim(name: "parent_path")]) }) ?? false)
  }
}
