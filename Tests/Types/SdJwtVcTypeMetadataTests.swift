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

final class SdJwtVcTypeMetadataTests: XCTestCase {
  
  func testValidSdJwtVcTypeMetadataInitialization() throws {
    let vct =  "test-vct"
    
    let metadata = try SdJwtVcTypeMetadata(
      vct: vct,
      name: "Test Name",
      description: "Test Description"
    )
    
    XCTAssertEqual(metadata.vct, "test-vct")
    XCTAssertEqual(metadata.name, "Test Name")
    XCTAssertEqual(metadata.description, "Test Description")
    XCTAssertNil(metadata.schemaSource) // Ensure optional properties default to nil
  }
  
  //  func testConflictingSchemaThrowsError() {
  //    let vct = try! SdJwtVcTypeMetadata.Vct(value: "test-vct")
  //    let schema = JSON(["key": "value"])
  //    let schemaUri = URL(string: "https://example.com/schema")!
  //
  //    XCTAssertThrowsError(
  //      try SdJwtVcTypeMetadata(vct: vct, schema: schema, schemaUri: schemaUri)
  //    ) { error in
  //      XCTAssertEqual(error as? SDJWTError, SDJWTError.error("Conflicting schema definitions"))
  //    }
  //  }
  
//  func testVctCannotBeEmpty() {
//    XCTAssertThrowsError(try SdJwtVcTypeMetadata.Vct(value: "")) { error in
//      XCTAssertEqual(error as? SDJWTError, SDJWTError.error("Vct value must not be blank"))
//    }
//  }
  
  func testValidClaimMetadataInitialization() {
    let claimMetadata = SdJwtVcTypeMetadata.ClaimMetadata(
      path: .claim("user.age"),
      selectivelyDisclosable: .allowed
    )

    let expectedPath = ClaimPath([.claim(name: "user.age")])
    XCTAssertEqual(claimMetadata.path, expectedPath)
    XCTAssertEqual(claimMetadata.selectivelyDisclosable, .allowed)
    XCTAssertNil(claimMetadata.display)
  }
  
//  func testDisplayCannotHaveDuplicateLanguages() {
//    let displayList = [
//      SdJwtVcTypeMetadata.DisplayMetadata(lang: "en", name: "English"),
//      SdJwtVcTypeMetadata.DisplayMetadata(lang: "en", name: "Duplicate English")
//    ]
//    
//    XCTAssertThrowsError(try SdJwtVcTypeMetadata.Display(value: displayList)) { error in
//      XCTAssertEqual(error as? SDJWTError, SDJWTError.error("Each language must appear only once in the display list"))
//    }
//  }
  
  func testValidDisplayMetadataInitialization() {
    let displayMetadata = SdJwtVcTypeMetadata.DisplayMetadata(
      lang: "en",
      name: "Test Name",
      description: "Test Description"
    )
    
    XCTAssertEqual(displayMetadata.lang, "en")
    XCTAssertEqual(displayMetadata.name, "Test Name")
    XCTAssertEqual(displayMetadata.description, "Test Description")
  }
  
//  func testSvgTemplatePropertiesThrowsErrorWhenEmpty() {
//    XCTAssertThrowsError(try SdJwtVcTypeMetadata.SvgTemplateProperties()) { error in
//      XCTAssertEqual(error as? SDJWTError, SDJWTError.error("At least one property must be specified"))
//    }
//  }
  
  func testValidSvgTemplatePropertiesInitialization() throws {
    let properties = try SdJwtVcTypeMetadata.SvgTemplateProperties(orientation: "portrait")
    
    XCTAssertEqual(properties.orientation, "portrait")
    XCTAssertNil(properties.colorScheme)
    XCTAssertNil(properties.contrast)
  }
  
  func testValidSvgTemplateInitialization() throws {
    let uri = URL(string: "https://example.com/svg")!
    let integrity =  "hash123"
    let properties = try SdJwtVcTypeMetadata.SvgTemplateProperties(orientation: "landscape")
    
    let template = SdJwtVcTypeMetadata.SvgTemplate(uri: uri, uriIntegrity: integrity, properties: properties)
    
    XCTAssertEqual(template.uri, uri)
    XCTAssertEqual(template.uriIntegrity, "hash123")
    XCTAssertEqual(template.properties?.orientation, "landscape")
  }
  
  func testValidLogoMetadataInitialization() {
    let uri = URL(string: "https://example.com/logo.png")!
    let integrity =  "hash456"
    
    let logoMetadata = SdJwtVcTypeMetadata.LogoMetadata(uri: uri, uriIntegrity: integrity, altText: "Logo Alt Text")
    
    XCTAssertEqual(logoMetadata.uri, uri)
    XCTAssertEqual(logoMetadata.uriIntegrity, "hash456")
    XCTAssertEqual(logoMetadata.altText, "Logo Alt Text")
  }
  
  func testClaimSelectivelyDisclosableEnum() {
    XCTAssertEqual(SdJwtVcTypeMetadata.ClaimSelectivelyDisclosable.always.rawValue, "always")
    XCTAssertEqual(SdJwtVcTypeMetadata.ClaimSelectivelyDisclosable.allowed.rawValue, "allowed")
    XCTAssertEqual(SdJwtVcTypeMetadata.ClaimSelectivelyDisclosable.never.rawValue, "never")
  }
  
  func testRenderingMetadataInitialization() {
    let renderingMetadata = SdJwtVcTypeMetadata.RenderingMetadata(simple: nil, svgTemplates: nil)
    XCTAssertNil(renderingMetadata.simple)
    XCTAssertNil(renderingMetadata.svgTemplates)
  }
  
  func testDocumentIntegrityInitialization() {
    let integrity = "integrity-value"
    XCTAssertEqual(integrity, "integrity-value")
  }
  
  func testComplexInitialization() throws {
    let vct = "complex-vct"
    let integrity = "doc-integrity"
    
    let displayMetadata = [SdJwtVcTypeMetadata.DisplayMetadata(lang: "en", name: "Test Name")]
    
    let schemaJson = JSON(["title": "Test Schema"])
    
    let metadata = try SdJwtVcTypeMetadata(
      vct: vct,
      vctIntegrity: integrity,
      name: "Complex Metadata",
      description: "A more complex test case",
      extends: URL(string: "https://example.com")!,
      extendsIntegrity: integrity,
      display: displayMetadata,
      claims: [],
      schemaSource: .byValue(schemaJson)
    )
    
    XCTAssertEqual(metadata.vct, "complex-vct")
    XCTAssertEqual(metadata.name, "Complex Metadata")
    XCTAssertEqual(metadata.description, "A more complex test case")
    XCTAssertEqual(metadata.extendsIntegrity, "doc-integrity")
    XCTAssertEqual(metadata.display?.first?.name, "Test Name")
  }
  
  func testDecodingTypeMetadataFromJSON() throws {
    
    // Given
    let url = Bundle.module.url(forResource: "type_meta_data_pid", withExtension: "json")!
    let jsonData = try! Data(contentsOf: url)
    
    // When
    let decoder = JSONDecoder()
    let metadata = try decoder.decode(SdJwtVcTypeMetadata.self, from: jsonData)
    
    // Then
    XCTAssertEqual(metadata.vct, "urn:eudi:pid:1")
    XCTAssertEqual(metadata.name, "Type Metadata for Person Identification Data")

    XCTAssertEqual(metadata.display?.count, 1)
    XCTAssertEqual(metadata.display?.first?.lang, "en")
    XCTAssertEqual(metadata.display?.first?.name, "PID")
    XCTAssertEqual(metadata.display?.first?.description, "Person Identification Data")

    XCTAssertEqual(metadata.claims?.count, 35)
    XCTAssertEqual(metadata.claims?[0].path.value.first, .claim(name: "family_name"))

    // Verify at least one path includes a null value
    let containsNullPath = metadata.claims?.contains(where: { $0.path.value.contains(.allArrayElements) }) ?? false
    XCTAssertTrue(containsNullPath, "Expected at least one claim path to contain null")

    // Verify schema is parsed as byValue and is an object
    if case let .byValue(schema)? = metadata.schemaSource {
        XCTAssertEqual(schema["type"].stringValue, "object")
    } else {
        XCTFail("Expected schemaSource to be .byValue with a valid schema")
    }
  }
}

