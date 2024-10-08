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
@preconcurrency import Foundation
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
    ).verifyIssuance(
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
        session: NetworkingBundleMock(
          path: "issuer_meta_data",
          extension: "json"
        )
      ),
      trust: X509CertificateTrustFactory.none
    ).verifyIssuance(
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
      trust: X509CertificateTrustFactory.none,
      lookup: LookupPublicKeysFromDIDDocumentMock()
    ).verifyIssuance(
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
    ).verifyIssuance(
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
    ).verifyIssuance(
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
    
    let result = try await SDJWTVCVerifier(
      fetcher: SdJwtVcIssuerMetaDataFetcher(
        session: NetworkingBundleMock(
          path: "issuer_meta_data",
          extension: "json"
        )
      ),
      trust: X509CertificateTrustFactory.none
    ).verifyIssuance(
      unverifiedSdJwt: json
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyPresentation_WithValidSDJWTPresentation_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.presentation_sd_jwt.clean()
    
    // When
    let result = try await SDJWTVCVerifier(
      fetcher: SdJwtVcIssuerMetaDataFetcher(
        session: NetworkingBundleMock(
          path: "issuer_meta_data",
          extension: "json"
        )
      ),
      trust: X509CertificateTrustFactory.none
    ).verifyPresentation(
      unverifiedSdJwt: sdJwtString,
      claimsVerifier: ClaimsVerifier(),
      keyBindingVerifier: KeyBindingVerifier()
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyPresentation_WithValidSDJWT_AsFlattendedJSON_Presentation_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.presentation_sd_jwt.clean()
    let parser = CompactParser()
    let sdJwt = try! parser.getSignedSdJwt(serialisedString: sdJwtString)
    
    // When
    let json = try sdJwt.asJwsJsonObject(
      option: .general,
      kbJwt: sdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    let result = try await SDJWTVCVerifier(
      fetcher: SdJwtVcIssuerMetaDataFetcher(
        session: NetworkingBundleMock(
          path: "issuer_meta_data",
          extension: "json"
        )
      ),
      trust: X509CertificateTrustFactory.none
    ).verifyPresentation(
      unverifiedSdJwt: json,
      claimsVerifier: ClaimsVerifier(),
      keyBindingVerifier: KeyBindingVerifier()
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyPresentation_WithDSLBuiltValidSDJWT_WithIssuerMetaData_Presentation_ShouldSucceed() async throws {
    
    let issuersKey = await issuersKeyPair.public
    let issuerJwk = try issuersKey.jwk
    
    let holdersKey = await holdersKeyPair.public
    let holdersJwk = try holdersKey.jwk
    
    let jsonObject: JSON = [
      "issuer": "https://example.com/issuer",
      "jwks": [
        "keys": [
          [
            "crv": "P-256",
            "kid": "Ao50Swzv_uWu805LcuaTTysu_6GwoqnvJh9rnc44U48",
            "kty": "EC",
            "x": issuerJwk.x?.base64URLEncode(),
            "y": issuerJwk.y?.base64URLEncode()
          ]
        ]
      ]
    ]
    
    let issuerSignedSDJWT = try await SDJWTIssuer.issue(
      issuersPrivateKey: issuersKeyPair.private,
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        keyID: "Ao50Swzv_uWu805LcuaTTysu_6GwoqnvJh9rnc44U48"
      )
    ) {
      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date() + 3600)
      ConstantClaims.iss(domain: "https://example.com/issuer")
      FlatDisclosedClaim("sub", "6c5c0a49-b589-431d-bae7-219122a9ec2c")
      FlatDisclosedClaim("given_name", "太郎")
      FlatDisclosedClaim("family_name", "山田")
      FlatDisclosedClaim("email", "\"unusual email address\"@example.jp")
      FlatDisclosedClaim("phone_number", "+81-80-1234-5678")
      ObjectClaim("address") {
        FlatDisclosedClaim("street_address", "東京都港区芝公園４丁目２−８")
        FlatDisclosedClaim("locality", "東京都")
        FlatDisclosedClaim("region", "港区")
        FlatDisclosedClaim("country", "JP")
      }
      FlatDisclosedClaim("birthdate", "1940-01-01")
      ObjectClaim("cnf") {
        ObjectClaim("jwk") {
          PlainClaim("kid", "Ao50Swzv_uWu805LcuaTTysu_6GwoqnvJh9rnc44U48")
          PlainClaim("kty", "EC")
          PlainClaim("y", holdersJwk.y!.base64URLEncode())
          PlainClaim("x", holdersJwk.x!.base64URLEncode())
          PlainClaim("crv", "P-256")
        }
      }
    }
    
    let sdHash = DigestCreator()
      .hashAndBase64Encode(
        input: CompactSerialiser(
          signedSDJWT: issuerSignedSDJWT
        ).serialised
      )!
    
    let holder = try await SDJWTIssuer
      .presentation(
        holdersPrivateKey: holdersKeyPair.private,
        signedSDJWT: issuerSignedSDJWT,
        disclosuresToPresent: issuerSignedSDJWT.disclosures,
        keyBindingJWT: KBJWT(
          header: DefaultJWSHeaderImpl(algorithm: .ES256),
          kbJwtPayload: .init([
            Keys.nonce.rawValue: "123456789",
            Keys.aud.rawValue: "example.com",
            Keys.iat.rawValue: 1694600000,
            Keys.sdHash.rawValue: sdHash
          ])
        )
      )
    
    let serialized: String = CompactSerialiser(signedSDJWT: holder).serialised
    
    let result = try await SDJWTVCVerifier(
      fetcher: SdJwtVcIssuerMetaDataFetcher(
        session: NetworkingJSONMock(
          json: jsonObject
        )
      ),
      trust: X509CertificateTrustFactory.none
    ).verifyPresentation(
      unverifiedSdJwt: serialized,
      claimsVerifier: ClaimsVerifier(),
      keyBindingVerifier: KeyBindingVerifier()
    )
    
    XCTAssertEqual(sdHash, holder.delineatedCompactSerialisation)
    XCTAssertNoThrow(try result.get())
  }
}
