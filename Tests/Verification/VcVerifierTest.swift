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
import JSONWebKey
import JSONWebSignature
import JSONWebToken
import SwiftyJSON
import XCTest

@testable import eudi_lib_sdjwt_swift


final class VcVerifierTest: XCTestCase {
  
  override func setUp() async throws {
  }
  
  override func tearDown() async throws {
  }
  
  func testVerifyIssuance_WithValidSDJWT_Withx509Header_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.x509_sd_jwt.clean()
    
    // When
    let result = try await SDJWTVCVerifier(
      trust: X509CertificateChainVerifier()
    )
    .verifyIssuance(
      unverifiedSdJwt: sdJwtString
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWT_WithIssuerMetaData_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.issuer_metadata_sd_jwt.clean()
    
    // When
    let result = try await SDJWTVCVerifier(
      fetcher: SdJwtVcIssuerMetaDataFetcher(
        session: NetworkingMock(
          path: "issuer_meta_data",
          extension: "json"
        )
      )
    )
    .verifyIssuance(
      unverifiedSdJwt: sdJwtString
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWT_WithDID_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.did_sd_jwt.clean()
    
    // When
    let result = try await SDJWTVCVerifier(
      lookup: LookupPublicKeysFromDIDDocumentMock()
    )
    .verifyIssuance(
      unverifiedSdJwt: sdJwtString
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWTFlattendedJSON_Withx509Header_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.x509_sd_jwt.clean()
    let parser = CompactParser()
    let sdJwt = try! parser.getSignedSdJwt(serialisedString: sdJwtString)
    
    // When
    let json = try sdJwt.asJwsJsonObject(
      option: .flattened,
      kbJwt: sdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    let result = try await SDJWTVCVerifier(
      trust: X509CertificateChainVerifier()
    )
    .verifyIssuance(
      unverifiedSdJwt: json
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWTGeneralJSON_Withx509Header_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.x509_sd_jwt.clean()
    let parser = CompactParser()
    let sdJwt = try! parser.getSignedSdJwt(serialisedString: sdJwtString)
    
    // When
    let json = try sdJwt.asJwsJsonObject(
      option: .general,
      kbJwt: sdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    let result = try await SDJWTVCVerifier(
      trust: X509CertificateChainVerifier()
    )
    .verifyIssuance(
      unverifiedSdJwt: json
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWTFlattended_WithIssuerMetaData_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.issuer_metadata_sd_jwt.clean()
    let parser = CompactParser()
    let sdJwt = try! parser.getSignedSdJwt(serialisedString: sdJwtString)
    
    // When
    let json = try sdJwt.asJwsJsonObject(
      option: .general,
      kbJwt: sdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    // When
    let result = try await SDJWTVCVerifier(
      fetcher: SdJwtVcIssuerMetaDataFetcher(
        session: NetworkingMock(
          path: "issuer_meta_data",
          extension: "json"
        )
      )
    )
    .verifyIssuance(
      unverifiedSdJwt: json
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testPresentation() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.issuer_metadata_sd_jwt.clean()
    
    // When
    let result = try await SDJWTVCVerifier(
      fetcher: SdJwtVcIssuerMetaDataFetcher(
        session: NetworkingMock(
          path: "issuer_meta_data",
          extension: "json"
        )
      )
    ).verifyPresentation(
      unverifiedSdJwt: sdJwtString,
      claimsVerifier: ClaimsVerifier()
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
}
