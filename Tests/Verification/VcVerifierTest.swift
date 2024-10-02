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
  
  func testX509() async throws {
    
    let sdJwtString = SDJWTConstants.x509_sd_jwt.clean()
    
    let result = try await SDJWTVCVerifier(
      fetcher: SdJwtVcIssuerMetaDataFetcher(
        session: URLSession.shared
      ),
      trust: X509CertificateChainVerifier()
    )
    .verifyIssuance(
      unverifiedSdJwt: sdJwtString
    )
    
    XCTAssertNoThrow(try result.get())
  }
  
  func testIssuerMetaData() async throws {
    
    let sdJwtString = SDJWTConstants.issuer_metadata_sd_jwt.clean()
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
    
    XCTAssertNoThrow(try result.get())
  }
  
  func testDid() async throws {
    
    let sdJwtString = SDJWTConstants.issuer_metadata_sd_jwt.clean()
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
    
    XCTAssertNoThrow(try result.get())
  }
}
