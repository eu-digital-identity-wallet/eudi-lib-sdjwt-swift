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

final class EndToEndTest: XCTestCase {
  
  override func setUp() async throws {
    try await super.setUp()
  }
  
  override func tearDown() async throws {
    try await super.tearDown()
  }
  
  func testEndToEndWithPrimaryIssuerSdJWT() async throws {
    
    // Given
    let visitor = ClaimVisitor()
    let verifier: KeyBindingVerifier = KeyBindingVerifier()
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    let query: Set<JSONPointer> = Set(
      [
        "/family_name",
        "/given_name"
      ].compactMap {
        JSONPointer(pointer: $0)
      }
    )
    
    // When
    let result = try await SDJWTVCVerifier(
      trust: X509CertificateChainVerifier()
    ).verifyIssuance(
      unverifiedSdJwt: sdJwtString
    )
    
    let issuerSignedSDJWT = try CompactParser().getSignedSdJwt(
      serialisedString: sdJwtString
    )
    
    let presentedSdJwt = try await issuerSignedSDJWT.present(
      query: query,
      visitor: visitor
    )
    
    let sdHash = DigestCreator()
      .hashAndBase64Encode(
        input: CompactSerialiser(
          signedSDJWT: presentedSdJwt!
        ).serialised
      )!
    
    let aud = "example.com"
    let timestamp = Int(Date().timeIntervalSince1970.rounded())
    var holderPresentation: SignedSDJWT?
    holderPresentation = try await SDJWTIssuer
      .presentation(
        holdersPrivateKey: TestP256AsyncSigner(
          secKey: holdersKeyPair.private
        ),
        signedSDJWT: issuerSignedSDJWT,
        disclosuresToPresent: presentedSdJwt!.disclosures,
        keyBindingJWT: .init(
          header: DefaultJWSHeaderImpl(algorithm: .ES256),
          kbJwtPayload: .init([
            Keys.nonce.rawValue: "123456789",
            Keys.aud.rawValue: aud,
            Keys.iat.rawValue: timestamp,
            Keys.sdHash.rawValue: sdHash
          ])
        )
      )
    
    let kbJwt = holderPresentation?.kbJwt
    
    // Then
    XCTAssertNoThrow(try result.get())
    XCTAssertNoThrow(
      try verifier.verify(
        iatOffset: .init(
          startTime: Date(timeIntervalSinceNow: -100000),
          endTime: Date(timeIntervalSinceNow: 100000)
        )!,
        expectedAudience: "example.com",
        challenge: kbJwt!,
        extractedKey: try holdersKeyPair.public.jwk
      )
    )
    
    XCTAssertNotNil(kbJwt)
    XCTAssertEqual(presentedSdJwt!.disclosures.count, 2)
    
    let presentedDisclosures = Set(presentedSdJwt!.disclosures)
    let visitedDisclosures = Set(visitor.disclosures)
    XCTAssertTrue(presentedDisclosures.isSubset(of: visitedDisclosures))
  }
  
  func testEndToEndWithSecondaryIssuerSdJWT() async throws {
    
    // Given
    let visitor = ClaimVisitor()
    let verifier: KeyBindingVerifier = KeyBindingVerifier()
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    let query: Set<JSONPointer> = Set(
      [
        "/family_name",
        "/given_name"
      ].compactMap {
        JSONPointer(pointer: $0)
      }
    )
    
    // When
    let result = try await SDJWTVCVerifier(
      trust: X509CertificateChainVerifier()
    ).verifyIssuance(
      unverifiedSdJwt: sdJwtString
    )
    
    let issuerSignedSDJWT = try CompactParser().getSignedSdJwt(
      serialisedString: sdJwtString
    )
    
    let presentedSdJwt = try await issuerSignedSDJWT.present(
      query: query,
      visitor: visitor
    )
    
    let sdHash = DigestCreator()
      .hashAndBase64Encode(
        input: CompactSerialiser(
          signedSDJWT: presentedSdJwt!
        ).serialised
      )!
    
    var holderPresentation: SignedSDJWT?
    holderPresentation = try await SDJWTIssuer
      .presentation(
        holdersPrivateKey: TestP256AsyncSigner(secKey: holdersKeyPair.private),
        signedSDJWT: issuerSignedSDJWT,
        disclosuresToPresent: presentedSdJwt!.disclosures,
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
    XCTAssertNoThrow(try result.get())
    XCTAssertNoThrow(
      try verifier.verify(
        iatOffset: .init(
          startTime: Date(timeIntervalSinceNow: -100000),
          endTime: Date(timeIntervalSinceNow: 100000)
        )!,
        expectedAudience: "example.com",
        challenge: kbJwt!,
        extractedKey: try holdersKeyPair.public.jwk
      )
    )
    
    XCTAssertNotNil(kbJwt)
    XCTAssertEqual(presentedSdJwt!.disclosures.count, 2)
    
    let presentedDisclosures = Set(presentedSdJwt!.disclosures)
    let visitedDisclosures = Set(visitor.disclosures)
    XCTAssertTrue(presentedDisclosures.isSubset(of: visitedDisclosures))
  }
}
