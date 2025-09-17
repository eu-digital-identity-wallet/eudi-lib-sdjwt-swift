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

class CompactParserJwsJsonTests: XCTestCase {
  
  var parser: CompactParser!
  
  override func setUp() {
    super.setUp()
    parser = CompactParser()
  }
  
  override func tearDown() {
    parser = nil
    super.tearDown()
  }
  
  // MARK: - Test fromJwsJsonObject -> String
  
  func testFromJwsJsonObject_WithFlattenedFormat_ShouldReturnCompactString() throws {
    // Given
    let originalSdJwt = SDJWTConstants.x509_sd_jwt.clean()
    let signedSdJwt = try parser.getSignedSdJwt(serialisedString: originalSdJwt)
    
    let jwsJson = try signedSdJwt.asJwsJsonObject(
      option: .flattened,
      kbJwt: signedSdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    // When
    let result: String = try parser.stringFromJwsJsonObject(jwsJson)
    
    // Then
    XCTAssertFalse(result.isEmpty)
    XCTAssertTrue(result.contains("~"))
    
    // Verify round-trip consistency
    let reparsedSdJwt = try parser.getSignedSdJwt(serialisedString: result)
    XCTAssertEqual(signedSdJwt.disclosures.count, reparsedSdJwt.disclosures.count)
  }
  
  func testFromJwsJsonObject_WithGeneralFormat_ShouldReturnCompactString() throws {
    // Given
    let originalSdJwt = SDJWTConstants.x509_sd_jwt.clean()
    let signedSdJwt = try parser.getSignedSdJwt(serialisedString: originalSdJwt)
    
    let jwsJson = try signedSdJwt.asJwsJsonObject(
      option: .flattened,
      kbJwt: signedSdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    // When
    let result: String = try parser.stringFromJwsJsonObject(jwsJson)
    
    // Then
    XCTAssertFalse(result.isEmpty)
    XCTAssertTrue(result.contains("~"))
    
    // Verify round-trip consistency
    let reparsedSdJwt = try parser.getSignedSdJwt(serialisedString: result)
    XCTAssertEqual(signedSdJwt.disclosures.count, reparsedSdJwt.disclosures.count)
  }
  
  func testFromJwsJsonObject_WithoutKeyBindingJWT_ShouldReturnValidString() throws {
    // Given
    let originalSdJwt = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    let signedSdJwt = try parser.getSignedSdJwt(serialisedString: originalSdJwt)
    
    let jwsJson = try signedSdJwt.asJwsJsonObject(
      option: .flattened,
      kbJwt: nil, // No key binding JWT
      getParts: parser.extractJWTParts
    )
    
    // When
    let result: String = try parser.stringFromJwsJsonObject(jwsJson)
    
    // Then
    XCTAssertFalse(result.isEmpty)
    XCTAssertTrue(result.contains("~"))
    
    // Verify it doesn't end with an extra tilde when no KB-JWT
    XCTAssertFalse(result.hasSuffix("~~"))
  }
  
  // MARK: - Test fromJwsJsonObject -> SignedSDJWT
  
  func testFromJwsJsonObject_WithFlattenedFormat_ShouldReturnSignedSDJWT() throws {
    // Given
    let originalSdJwt = SDJWTConstants.x509_sd_jwt.clean()
    let originalSignedSdJwt = try parser.getSignedSdJwt(serialisedString: originalSdJwt)
    
    let jwsJson = try originalSignedSdJwt.asJwsJsonObject(
      option: .flattened,
      kbJwt: originalSignedSdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    // When
    let result: SignedSDJWT = try parser.fromJwsJsonObject(jwsJson)
    
    // Then
    XCTAssertEqual(result.disclosures.count, originalSignedSdJwt.disclosures.count)
    XCTAssertEqual(result.kbJwt?.compactSerialization, originalSignedSdJwt.kbJwt?.compactSerialization)
    
    // Verify disclosure contents match
    let originalDigests = Set(originalSignedSdJwt.disclosures)
    let resultDigests = Set(result.disclosures)
    XCTAssertEqual(originalDigests, resultDigests)
  }
  
  func testFromJwsJsonObject_WithGeneralFormat_ShouldReturnSignedSDJWT() throws {
    // Given
    let originalSdJwt = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    let originalSignedSdJwt = try parser.getSignedSdJwt(serialisedString: originalSdJwt)
    
    let jwsJson = try originalSignedSdJwt.asJwsJsonObject(
      option: .flattened,
      kbJwt: nil,
      getParts: parser.extractJWTParts
    )
    
    // When
    let result: SignedSDJWT = try parser.fromJwsJsonObject(jwsJson)
    
    // Then
    XCTAssertEqual(result.disclosures.count, originalSignedSdJwt.disclosures.count)
    XCTAssertNil(result.kbJwt)
    
    // Verify JWT payload equivalence
    XCTAssertEqual(result.jwt.compactSerialization, originalSignedSdJwt.jwt.compactSerialization)
  }
  
  // MARK: - Error Cases
  
  func testFromJwsJsonObject_WithMissingPayload_ShouldThrow() throws {
    // Given
    let invalidJson = JSON([
      JWS_JSON_PROTECTED: "eyJhbGciOiJIUzI1NiJ9",
      JWS_JSON_SIGNATURE: "signature"
      // Missing payload
    ])
    
    // When/Then
    XCTAssertThrowsError(try parser.stringFromJwsJsonObject(invalidJson) as String)
    XCTAssertThrowsError(try parser.fromJwsJsonObject(invalidJson) as SignedSDJWT)
  }
  
  func testFromJwsJsonObject_WithInvalidJWTStructure_ShouldThrow() throws {
    // Given
    let invalidJson = JSON([
      JWS_JSON_PAYLOAD: "invalid-payload",
      JWS_JSON_PROTECTED: "invalid-header",
      JWS_JSON_SIGNATURE: "invalid-signature",
      JWS_JSON_HEADER: [
        JWS_JSON_DISCLOSURES: []
      ]
    ])
    
    // When/Then - String version should work, but SignedSDJWT parsing should fail
    let compactString: String = try parser.stringFromJwsJsonObject(invalidJson)
    XCTAssertFalse(compactString.isEmpty)
    
    XCTAssertThrowsError(try parser.fromJwsJsonObject(invalidJson) as SignedSDJWT)
  }
  
  // MARK: - Round-trip Integration Tests
  
  func testRoundTrip_FlattenedToCompactToFlattened_ShouldBeConsistent() throws {
    // Given
    let originalSdJwt = SDJWTConstants.x509_sd_jwt.clean()
    let originalSignedSdJwt = try parser.getSignedSdJwt(serialisedString: originalSdJwt)
    
    // Convert to JWS JSON
    let jwsJson = try originalSignedSdJwt.asJwsJsonObject(
      option: .flattened,
      kbJwt: originalSignedSdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    // Convert back to compact
    let compactString: String = try parser.stringFromJwsJsonObject(jwsJson)
    let reconstructedSdJwt = try parser.getSignedSdJwt(serialisedString: compactString)
    
    // Convert to JWS JSON again
    let finalJwsJson = try reconstructedSdJwt.asJwsJsonObject(
      option: .flattened,
      kbJwt: reconstructedSdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    // Then - Should be equivalent
    XCTAssertEqual(jwsJson[JWS_JSON_PAYLOAD], finalJwsJson[JWS_JSON_PAYLOAD])
    XCTAssertEqual(jwsJson[JWS_JSON_PROTECTED], finalJwsJson[JWS_JSON_PROTECTED])
    XCTAssertEqual(jwsJson[JWS_JSON_SIGNATURE], finalJwsJson[JWS_JSON_SIGNATURE])
  }
  
  func testRoundTrip_GeneralToCompactToGeneral_ShouldBeConsistent() throws {
    // Given
    let originalSdJwt = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    let originalSignedSdJwt = try parser.getSignedSdJwt(serialisedString: originalSdJwt)
    
    // Convert to JWS JSON General format
    let jwsJson = try originalSignedSdJwt.asJwsJsonObject(
      option: .general,
      kbJwt: nil,
      getParts: parser.extractJWTParts
    )
    
    // Convert back via SignedSDJWT method
    let reconstructedSdJwt: SignedSDJWT = try parser.fromJwsJsonObject(jwsJson)
    
    // Then - Should maintain equivalence
    XCTAssertEqual(originalSignedSdJwt.disclosures.count, reconstructedSdJwt.disclosures.count)
    XCTAssertEqual(originalSignedSdJwt.jwt.compactSerialization, reconstructedSdJwt.jwt.compactSerialization)
  }
  
  func testFromJwsJsonObject_DetectsGeneralFormat_Correctly() throws {
    // Given
    let originalSdJwt = SDJWTConstants.x509_sd_jwt.clean()
    let signedSdJwt = try parser.getSignedSdJwt(serialisedString: originalSdJwt)
    
    let generalJson = try signedSdJwt.asJwsJsonObject(
      option: .general,
      kbJwt: signedSdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    let flattenedJson = try signedSdJwt.asJwsJsonObject(
      option: .flattened,
      kbJwt: signedSdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    // When
    let resultFromGeneral: String = try parser.stringFromJwsJsonObject(generalJson)
    let resultFromFlattened: String = try parser.stringFromJwsJsonObject(flattenedJson)
    
    // Then - Both should produce equivalent compact strings
    let sdJwtFromGeneral = try parser.getSignedSdJwt(serialisedString: resultFromGeneral)
    let sdJwtFromFlattened = try parser.getSignedSdJwt(serialisedString: resultFromFlattened)
    
    XCTAssertEqual(sdJwtFromGeneral.disclosures.count, sdJwtFromFlattened.disclosures.count)
    XCTAssertEqual(sdJwtFromGeneral.jwt.compactSerialization, sdJwtFromFlattened.jwt.compactSerialization)
  }
}
