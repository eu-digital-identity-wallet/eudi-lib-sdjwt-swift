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

final class JSONSerializationTest: XCTestCase {
  
  override func setUp() async throws {
    
  }
  
  override func tearDown() {
    
  }
  
  func testSdJWTGeneralSerialization() async throws {
    
    // Given
    let parser = CompactParser(serialisedString: SDJWTConstants.compactSdJwt)
    let sdJwt = try! parser.getSignedSdJwt()
    
    // When
    let json = try sdJwt.asJwsJsonObject(
      option: .general,
      kbJwt: sdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    // Then
    let payload = json["payload"].stringValue
    XCTAssertNotNil(payload, "The value should not be nil")
    XCTAssertEqual(payload, SDJWTConstants.payload)
    
    let signature = json["signatures"].arrayValue.first?["signature"].stringValue
    XCTAssertNotNil(signature, "The value should not be nil")
    if let signature = signature {
      XCTAssertEqual(signature, SDJWTConstants.signature)
    }
    
    let protected = json["signatures"].arrayValue.first?["protected"].stringValue
    XCTAssertNotNil(protected, "The value should not be nil")
    if let protected = protected {
      XCTAssertEqual(protected, SDJWTConstants.protected)
    }
    
    let disclosures = json["signatures"].arrayValue.first?["header"]["disclosures"].arrayValue.map { $0.stringValue }
    XCTAssertNotNil(disclosures, "The value should not be nil")
    if let disclosures = disclosures {
      XCTAssertEqual(disclosures.count, 10)
      XCTAssertEqual(disclosures.contains(where: { $0 == "WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgImVtYWlsIiwgImpvaG5kb2VAZXhhbXBsZS5jb20iXQ" }), true)
    }
  }
  
  func testSdJWTFlattendedSerializationtest() async throws {
    
    // Given
    let parser = CompactParser(serialisedString: SDJWTConstants.compactSdJwt)
    let sdJwt = try! parser.getSignedSdJwt()
    
    // When
    let json = try sdJwt.asJwsJsonObject(
      option: .flattened,
      kbJwt: sdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    // Then
    let payload = json["payload"].stringValue
    XCTAssertEqual(payload, SDJWTConstants.payload)
    
    let signature = json["signature"].stringValue
    XCTAssertNotNil(signature, "The value should not be nil")
    XCTAssertEqual(signature, SDJWTConstants.signature)
    
    let protected = json["protected"].stringValue
    XCTAssertNotNil(protected, "The value should not be nil")
    XCTAssertEqual(protected, SDJWTConstants.protected)
    
    let disclosures = json["header"]["disclosures"].arrayValue.map { $0.stringValue }
    XCTAssertNotNil(disclosures, "The value should not be nil")
    XCTAssertEqual(disclosures.count, 10)
    XCTAssertEqual(disclosures.contains(where: { $0 == "WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgImVtYWlsIiwgImpvaG5kb2VAZXhhbXBsZS5jb20iXQ" }), true)
  }
}

