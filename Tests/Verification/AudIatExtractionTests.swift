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
import Crypto

@testable import eudi_lib_sdjwt_swift

// Regression coverage for the aud/iat extraction bug: SDJWTVCVerifier used to
// source iat and aud from the caller's own ClaimsVerifier object instead of
// from the token payload, making the audience and iat window checks
// self-referential ("silent false assurance").
final class AudIatExtractionTests: XCTestCase {

  private let did = "did:web:example.com"

  /// Mint a minimal SD-JWT signed by a fresh ES256 key, with an optional iat
  /// and optional top-level aud claim. Returns the compact serialisation and
  /// the matching public JWK (for the .did verification method).
  ///
  /// Four branches rather than one — SDJWTBuilder is a result builder with
  /// no buildOptional, so the DSL cannot contain `if let`.
  private func mint(
    iat: Date?,
    aud: String?
  ) async throws -> (serialised: String, jwk: JWK) {
    let kid = "\(did)#key-1"
    let privateKey = P256.Signing.PrivateKey()

    var publicJWK = privateKey.jwkRepresentation.publicKey
    publicJWK.keyID = kid
    publicJWK.algorithm = "ES256"

    var header = DefaultJWSHeaderImpl(algorithm: .ES256, type: "dc+sd-jwt")
    header.keyID = kid

    let signed: SignedSDJWT
    switch (iat, aud) {
    case let (iatValue?, audValue?):
      signed = try await SDJWTIssuer.issue(issuersPrivateKey: privateKey, header: header) {
        ConstantClaims.iss(domain: did)
        ConstantClaims.iat(time: iatValue.timeIntervalSince1970)
        PlainClaim("aud", audValue)
        FlatDisclosedClaim("marker", "value")
      }
    case let (iatValue?, nil):
      signed = try await SDJWTIssuer.issue(issuersPrivateKey: privateKey, header: header) {
        ConstantClaims.iss(domain: did)
        ConstantClaims.iat(time: iatValue.timeIntervalSince1970)
        FlatDisclosedClaim("marker", "value")
      }
    case let (nil, audValue?):
      signed = try await SDJWTIssuer.issue(issuersPrivateKey: privateKey, header: header) {
        ConstantClaims.iss(domain: did)
        PlainClaim("aud", audValue)
        FlatDisclosedClaim("marker", "value")
      }
    case (nil, nil):
      signed = try await SDJWTIssuer.issue(issuersPrivateKey: privateKey, header: header) {
        ConstantClaims.iss(domain: did)
        FlatDisclosedClaim("marker", "value")
      }
    }

    return (signed.serialisation, publicJWK)
  }

  private func verifier(for jwk: JWK) -> SDJWTVCVerifier {
    SDJWTVCVerifier(verificationMethod: .did(lookup: DIDPublicKeyLookupAgent(jwk: jwk)))
  }

  // MARK: - iat extracted from token

  func test_tokenIat_insideWindow_passes() async throws {
    let (serialised, jwk) = try await mint(iat: Date(), aud: nil)

    let claimsVerifier = ClaimsVerifier(
      iatValidWindow: TimeRange(
        startTime: Date(timeIntervalSinceNow: -60),
        endTime: Date(timeIntervalSinceNow: 60)
      )
    )

    let result = try await verifier(for: jwk).verifyIssuance(
      unverifiedSdJwt: serialised,
      claimsVerifier: claimsVerifier
    )
    XCTAssertNoThrow(try result.get())
  }

  func test_tokenIat_outsideWindow_fails() async throws {
    // Token iat two hours in the past; window is ±60s. Pre-fix, the caller's
    // "now" was substituted and this passed.
    let stale = Date(timeIntervalSinceNow: -7200)
    let (serialised, jwk) = try await mint(iat: stale, aud: nil)

    let claimsVerifier = ClaimsVerifier(
      iatValidWindow: TimeRange(
        startTime: Date(timeIntervalSinceNow: -60),
        endTime: Date(timeIntervalSinceNow: 60)
      )
    )

    let result = try await verifier(for: jwk).verifyIssuance(
      unverifiedSdJwt: serialised,
      claimsVerifier: claimsVerifier
    )
    XCTAssertThrowsError(try result.get()) { error in
      guard case SDJWTVerifierError.invalidJwt = error else {
        XCTFail("expected invalidJwt, got \(error)")
        return
      }
    }
  }

  // MARK: - aud extracted from token

  func test_tokenAud_matchesExpected_passes() async throws {
    let (serialised, jwk) = try await mint(iat: nil, aud: "verifier.example")

    let claimsVerifier = ClaimsVerifier(expectedAud: "verifier.example")

    let result = try await verifier(for: jwk).verifyIssuance(
      unverifiedSdJwt: serialised,
      claimsVerifier: claimsVerifier
    )
    XCTAssertNoThrow(try result.get())
  }

  func test_tokenAud_mismatchesExpected_fails() async throws {
    let (serialised, jwk) = try await mint(iat: nil, aud: "attacker.example")

    let claimsVerifier = ClaimsVerifier(expectedAud: "verifier.example")

    let result = try await verifier(for: jwk).verifyIssuance(
      unverifiedSdJwt: serialised,
      claimsVerifier: claimsVerifier
    )
    XCTAssertThrowsError(try result.get())
  }

  func test_tokenAud_requiredButMissing_fails() async throws {
    let (serialised, jwk) = try await mint(iat: nil, aud: nil)

    let claimsVerifier = ClaimsVerifier(
      expectedAud: "verifier.example",
      requireAud: true
    )

    let result = try await verifier(for: jwk).verifyIssuance(
      unverifiedSdJwt: serialised,
      claimsVerifier: claimsVerifier
    )
    XCTAssertThrowsError(try result.get())
  }

  // The regression test. Pre-fix, the caller's audClaim was copied into the
  // new ClaimsVerifier and compared against the caller's own expectedAud,
  // so a token with any (or no) aud would pass as long as the caller was
  // self-consistent. Post-fix the token's actual aud is used and this fails.
  func test_regression_callerAudCannotMaskTokenAud() async throws {
    let (serialised, jwk) = try await mint(iat: nil, aud: "attacker.example")

    let claimsVerifier = ClaimsVerifier(
      audClaim: "verifier.example",
      expectedAud: "verifier.example"
    )

    let result = try await verifier(for: jwk).verifyIssuance(
      unverifiedSdJwt: serialised,
      claimsVerifier: claimsVerifier
    )
    XCTAssertThrowsError(try result.get())
  }
}
