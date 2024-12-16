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
import JSONWebKey
import JSONWebSignature
import JSONWebToken
import XCTest

@testable import eudi_lib_sdjwt_swift

final class PresentationTest: XCTestCase {
  
  override func setUp() async throws {
    try await super.setUp()
  }
  
  override func tearDown() async throws {
    try await super.tearDown()
  }
  
  func testSDJWTPresentationWithSelectiveDisclosures() async throws {
    
    // Given
    let visitor = Visitor()
    let holdersKey = holdersKeyPair.public
    let holdersJwk = try holdersKey.jwk
    let verifier: KeyBindingVerifier = KeyBindingVerifier()
    
    @SDJWTBuilder
    var evidenceObject: SdElement {
      FlatDisclosedClaim("type", "document")
      FlatDisclosedClaim("method", "pipp")
      FlatDisclosedClaim("time", "2012-04-22T11:30Z")
    }
    
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
      RecursiveObject("test_recursive") {
        FlatDisclosedClaim("recursive_address", "東京都港区芝公園４丁目２−８")
      }
      ArrayClaim("evidence", array: [
        evidenceObject
      ])
    }
    
    // When
    let query: Set<JSONPointer> = Set(
      [
        "/address/region",
        "/address/country",
        "/test_recursive/recursive_address",
        "/evidence/0/time"
      ].compactMap {
        JSONPointer(pointer: $0)
      }
    )
    
    let presentedSdJwt = try await issuerSignedSDJWT.present(
      query: query,
      visitor: visitor
    )
    
    guard let presentedSdJwt = presentedSdJwt else {
      XCTFail("Expected presentedSdJwt value to be non-nil but it was nil")
      return
    }
    
    let sdHash = DigestCreator()
      .hashAndBase64Encode(
        input: CompactSerialiser(
          signedSDJWT: presentedSdJwt
        ).serialised
      )!
    
    var holderPresentation: SignedSDJWT?
      holderPresentation = try await SDJWTIssuer
        .presentation(
          holdersPrivateKey: TestP256AsyncSigner(secKey: holdersKeyPair.private),
          signedSDJWT: issuerSignedSDJWT,
          disclosuresToPresent: presentedSdJwt.disclosures,
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
    
    let kbJwt = holderPresentation?.kbJwt
    
    // Then
    XCTAssertNoThrow(
      try verifier.verify(
        iatOffset: .init(
          startTime: Date(timeIntervalSince1970: 1694600000 - 1000),
          endTime: Date(timeIntervalSince1970: 1694600000)
        )!,
        expectedAudience: "example.com",
        challenge: kbJwt!,
        extractedKey: holdersJwk
      )
    )
    
    XCTAssertNotNil(kbJwt)
    XCTAssertEqual(presentedSdJwt.disclosures.count, 5)
    
    let presentedDisclosures = Set(presentedSdJwt.disclosures)
    let visitedDisclosures = Set(visitor.disclosures)
    XCTAssertTrue(presentedDisclosures.isSubset(of: visitedDisclosures))
  }
}

