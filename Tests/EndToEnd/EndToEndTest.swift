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
    let x509Verifier = SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateChainVerifier())
    )
    
    let result = try await x509Verifier.verifyIssuance(
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
  
  func testEndToEndWithClaimPathsAndPrimaryIssuerSdJWT() async throws {
    
    // Given
    let visitor = ClaimVisitor()
    let verifier: KeyBindingVerifier = KeyBindingVerifier()
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    let query: Set<ClaimPath> = Set(
      [
        .claim("family_name"),
        .claim("given_name")
      ]
    )
    
    // When
    let result = try await SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateChainVerifier())
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
    let x509Verifier = SDJWTVCVerifier(verificationMethod: .x509(trust: X509CertificateChainVerifier()))
    let result = try await x509Verifier.verifyIssuance(
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
  
  func testEndToEndWithClaimPathsSecondaryIssuerSdJWT() async throws {
    
    // Given
    let visitor = ClaimVisitor()
    let verifier: KeyBindingVerifier = KeyBindingVerifier()
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    let query: Set<ClaimPath> = [
      .claim("family_name"),
      .claim("given_name"),
      .claim("address").claim("street_address")
    ]
    
    // When
    let result = try await SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateChainVerifier())
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
    XCTAssertEqual(presentedSdJwt!.disclosures.count, 3)
    
    let presentedDisclosures = Set(presentedSdJwt!.disclosures)
    let visitedDisclosures = Set(visitor.disclosures)
    XCTAssertTrue(presentedDisclosures.isSubset(of: visitedDisclosures))
  }
  
  func testEndToEndWithDSLIssueedSdJWTClaimPaths() async throws {
    
    // Given
    let keyData = Data(
      base64Encoded: SDJWTConstants.anIssuerPrivateKey
    )!
    
    let visitor = ClaimVisitor()
    let verifier: KeyBindingVerifier = KeyBindingVerifier()
    let query: Set<ClaimPath> = Set(
      [
        .claim("hidden_name"),
        .claim("second_hidden_name"),
        .claim("address").claim("street_address"),
        .claim("nationalities"),
        .claim("type").arrayElement(2)
      ]
    )
    
    let issuerSignedSDJWT = try await SDJWTIssuer.issue(
      issuersPrivateKey: extractECKey(
        from: keyData
      ),
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        x509CertificateChain: [
          SDJWTConstants.anIssuersPrivateKeySignedcertificate
        ]
      )
    ) {
      ConstantClaims.iss(domain: "https://www.example.com")
      ConstantClaims.iat(time: Date())
      ConstantClaims.sub(subject: "Test Subject")
      PlainClaim("name", "plain name")
      FlatDisclosedClaim("hidden_name", "disclosedName")
      FlatDisclosedClaim("second_hidden_name", "disclosedName")
      ObjectClaim("address") {
        FlatDisclosedClaim("street_address", "東京都港区芝公園４丁目２−８")
        FlatDisclosedClaim("locality", "東京都")
        FlatDisclosedClaim("region", "港区")
        FlatDisclosedClaim("country", "JP")
      }
      FlatDisclosedClaim("nationalities", ["DE", "FR", "EN"])
      ArrayClaim("type", array: [
        .plain("VerifiableCredential"),
        .plain("VaccinationCertificate"),
        .flat("bhhbbib")
      ])
    }
    
    let sdJwtString = issuerSignedSDJWT.serialisation
    
    let x509Verifier = SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateChainVerifier())
    )
    
    // When
    let result = try await x509Verifier.verifyIssuance(
      unverifiedSdJwt: sdJwtString
    )
    
    switch result {
    case .success:
      XCTAssert(true)
    case .failure(let error):
      XCTAssert(true, error.localizedDescription)
    }
    
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
    
    let aud = "www.example.com"
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
          header: DefaultJWSHeaderImpl(
            algorithm: .ES256
          ),
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
        expectedAudience: "www.example.com",
        challenge: kbJwt!,
        extractedKey: try holdersKeyPair.public.jwk
      )
    )
    
    XCTAssertNotNil(kbJwt)
    XCTAssertEqual(presentedSdJwt!.disclosures.count, 5)
    
    let presentedDisclosures = Set(presentedSdJwt!.disclosures)
    let visitedDisclosures = Set(visitor.disclosures)
    XCTAssertTrue(presentedDisclosures.isSubset(of: visitedDisclosures))
  }
  
  func testEndToEndWithDSLIssueedSdJWTJSONPointers() async throws {
    
    // Given
    let keyData = Data(
      base64Encoded: SDJWTConstants.anIssuerPrivateKey
    )!
    
    let visitor = ClaimVisitor()
    let verifier: KeyBindingVerifier = KeyBindingVerifier()
    let query: Set<JSONPointer> = Set(
      [
        "/hidden_name",
        "/second_hidden_name",
        "/address/street_address",
        "/nationalities"
      ].compactMap {
        JSONPointer(pointer: $0)
      }
    )
    
    let issuerSignedSDJWT = try await SDJWTIssuer.issue(
      issuersPrivateKey: extractECKey(
        from: keyData
      ),
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        x509CertificateChain: [
          SDJWTConstants.anIssuersPrivateKeySignedcertificate
        ]
      )
    ) {
      ConstantClaims.iss(domain: "https://www.example.com")
      ConstantClaims.iat(time: Date())
      ConstantClaims.sub(subject: "Test Subject")
      PlainClaim("name", "plain name")
      FlatDisclosedClaim("hidden_name", "disclosedName")
      FlatDisclosedClaim("second_hidden_name", "disclosedName")
      ObjectClaim("address") {
        FlatDisclosedClaim("street_address", "東京都港区芝公園４丁目２−８")
        FlatDisclosedClaim("locality", "東京都")
        FlatDisclosedClaim("region", "港区")
        FlatDisclosedClaim("country", "JP")
      }
      FlatDisclosedClaim("nationalities", ["DE", "FR", "EN"])
      ArrayClaim("type", array: [
        .plain("VerifiableCredential"),
        .plain("VaccinationCertificate"),
        .flat("bhhbbib")
      ])
      ArrayClaim("hidden_nationalites", array: [.flat(value: "DE"), .plain(value: "GR")])
    }
    
    let sdJwtString = issuerSignedSDJWT.serialisation
    
    let x509Verifier = SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateChainVerifier())
    )
    
    // When
    let result = try await x509Verifier.verifyIssuance(
      unverifiedSdJwt: sdJwtString
    )
    
    switch result {
    case .success:
      XCTAssert(true)
    case .failure(let error):
      XCTAssert(true, error.localizedDescription)
    }
    
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
    
    let aud = "www.example.com"
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
          header: DefaultJWSHeaderImpl(
            algorithm: .ES256
          ),
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
        expectedAudience: "www.example.com",
        challenge: kbJwt!,
        extractedKey: try holdersKeyPair.public.jwk
      )
    )
    
    XCTAssertNotNil(kbJwt)
    XCTAssertEqual(presentedSdJwt!.disclosures.count, 4)
    
    let presentedDisclosures = Set(presentedSdJwt!.disclosures)
    let visitedDisclosures = Set(visitor.disclosures)
    XCTAssertTrue(presentedDisclosures.isSubset(of: visitedDisclosures))
  }
}
