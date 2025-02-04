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
    let vct = try SdJwtVcTypeMetadata.Vct(value: "test-vct")
    
    let metadata = try SdJwtVcTypeMetadata(
      vct: vct,
      name: "Test Name",
      description: "Test Description"
    )
    
    XCTAssertEqual(metadata.vct.value, "test-vct")
    XCTAssertEqual(metadata.name, "Test Name")
    XCTAssertEqual(metadata.description, "Test Description")
    XCTAssertNil(metadata.schema) // Ensure optional properties default to nil
  }
  
  func testConflictingSchemaThrowsError() {
    let vct = try! SdJwtVcTypeMetadata.Vct(value: "test-vct")
    let schema = JSON(["key": "value"])
    let schemaUri = URL(string: "https://example.com/schema")!
    
    XCTAssertThrowsError(
      try SdJwtVcTypeMetadata(vct: vct, schema: schema, schemaUri: schemaUri)
    ) { error in
      XCTAssertEqual(error as? SDJWTError, SDJWTError.error("Conflicting schema definitions"))
    }
  }
  
  func testVctCannotBeEmpty() {
    XCTAssertThrowsError(try SdJwtVcTypeMetadata.Vct(value: "")) { error in
      XCTAssertEqual(error as? SDJWTError, SDJWTError.error("Vct value must not be blank"))
    }
  }
  
  func testValidClaimMetadataInitialization() {
    let claimMetadata = SdJwtVcTypeMetadata.ClaimMetadata(
      path: "user.age",
      selectivelyDisclosable: .allowed
    )
    
    XCTAssertEqual(claimMetadata.path, "user.age")
    XCTAssertEqual(claimMetadata.selectivelyDisclosable, .allowed)
    XCTAssertNil(claimMetadata.display)
  }
  
  func testDisplayCannotHaveDuplicateLanguages() {
    let displayList = [
      SdJwtVcTypeMetadata.DisplayMetadata(lang: "en", name: "English"),
      SdJwtVcTypeMetadata.DisplayMetadata(lang: "en", name: "Duplicate English")
    ]
    
    XCTAssertThrowsError(try SdJwtVcTypeMetadata.Display(value: displayList)) { error in
      XCTAssertEqual(error as? SDJWTError, SDJWTError.error("Each language must appear only once in the display list"))
    }
  }
  
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
  
  func testSvgTemplatePropertiesThrowsErrorWhenEmpty() {
    XCTAssertThrowsError(try SdJwtVcTypeMetadata.SvgTemplateProperties()) { error in
      XCTAssertEqual(error as? SDJWTError, SDJWTError.error("At least one property must be specified"))
    }
  }
  
  func testValidSvgTemplatePropertiesInitialization() throws {
    let properties = try SdJwtVcTypeMetadata.SvgTemplateProperties(orientation: "portrait")
    
    XCTAssertEqual(properties.orientation, "portrait")
    XCTAssertNil(properties.colorScheme)
    XCTAssertNil(properties.contrast)
  }
  
  func testValidSvgTemplateInitialization() throws {
    let uri = URL(string: "https://example.com/svg")!
    let integrity = SdJwtVcTypeMetadata.DocumentIntegrity(value: "hash123")
    let properties = try SdJwtVcTypeMetadata.SvgTemplateProperties(orientation: "landscape")
    
    let template = SdJwtVcTypeMetadata.SvgTemplate(uri: uri, uriIntegrity: integrity, properties: properties)
    
    XCTAssertEqual(template.uri, uri)
    XCTAssertEqual(template.uriIntegrity?.value, "hash123")
    XCTAssertEqual(template.properties?.orientation, "landscape")
  }
  
  func testValidLogoMetadataInitialization() {
    let uri = URL(string: "https://example.com/logo.png")!
    let integrity = SdJwtVcTypeMetadata.DocumentIntegrity(value: "hash456")
    
    let logoMetadata = SdJwtVcTypeMetadata.LogoMetadata(uri: uri, uriIntegrity: integrity, altText: "Logo Alt Text")
    
    XCTAssertEqual(logoMetadata.uri, uri)
    XCTAssertEqual(logoMetadata.uriIntegrity?.value, "hash456")
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
    let integrity = SdJwtVcTypeMetadata.DocumentIntegrity(value: "integrity-value")
    XCTAssertEqual(integrity.value, "integrity-value")
  }
  
  func testComplexInitialization() throws {
    let vct = try SdJwtVcTypeMetadata.Vct(value: "complex-vct")
    let integrity = SdJwtVcTypeMetadata.DocumentIntegrity(value: "doc-integrity")
    
    let displayMetadata = SdJwtVcTypeMetadata.DisplayMetadata(lang: "en", name: "Test Name")
    let display = try SdJwtVcTypeMetadata.Display(value: [displayMetadata])
    
    let schemaJson = JSON(["title": "Test Schema"])
    
    let metadata = try SdJwtVcTypeMetadata(
      vct: vct,
      vctIntegrity: integrity,
      name: "Complex Metadata",
      description: "A more complex test case",
      extends: URL(string: "https://example.com")!,
      extendsIntegrity: integrity,
      display: display,
      claims: [],
      schema: schemaJson
    )
    
    XCTAssertEqual(metadata.vct.value, "complex-vct")
    XCTAssertEqual(metadata.name, "Complex Metadata")
    XCTAssertEqual(metadata.description, "A more complex test case")
    XCTAssertEqual(metadata.extendsIntegrity?.value, "doc-integrity")
    XCTAssertEqual(metadata.display?.value.first?.name, "Test Name")
  }
}

