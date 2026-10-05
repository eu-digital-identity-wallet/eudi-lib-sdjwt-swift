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
import JSONWebAlgorithms
import JSONWebKey
import JSONWebSignature
import JSONWebToken
import SwiftyJSON
import XCTest
import Crypto

@testable import eudi_lib_sdjwt_swift

// Coverage for the SD-JWT VC `typ` header enforcement. The library's
// default allow-list is {"dc+sd-jwt"} (parity with the Kotlin reference
// implementation and SD-JWT VC draft-13+). Callers that need to accept
// the legacy `vc+sd-jwt`, generic `JWT`, or other profiles must opt in
// via `allowedTypes`.
final class IssuerTypHeaderTests: XCTestCase {

  private let did = "did:web:example.com"

  /// Mint an SD-JWT with the given `typ` header value (nil = header omits
  /// `typ` entirely). Returns the serialised SD-JWT and the matching JWK
  /// for a `.did` verification method.
  private func mint(typ: String?) async throws -> (serialised: String, jwk: JWK) {
    let kid = "\(did)#key-1"
    let privateKey = P256.Signing.PrivateKey()

    var publicJWK = privateKey.jwkRepresentation.publicKey
    publicJWK.keyID = kid
    publicJWK.algorithm = "ES256"

    var header = DefaultJWSHeaderImpl(algorithm: .ES256, type: typ)
    header.keyID = kid

    let signed = try await SDJWTIssuer.issue(
      issuersPrivateKey: privateKey,
      header: header
    ) {
      ConstantClaims.iss(domain: did)
      FlatDisclosedClaim("marker", "value")
    }
    return (signed.serialisation, publicJWK)
  }

  private func verifier(
    for jwk: JWK,
    allowedTypes: Set<String>? = nil
  ) -> SDJWTVCVerifier {
    SDJWTVCVerifier(
      verificationMethod: .did(lookup: DIDPublicKeyLookupAgent(jwk: jwk)),
      allowedTypes: allowedTypes
    )
  }

  // MARK: - Default allow-list

  func test_defaults_acceptsDcSdJwt() async throws {
    let (serialised, jwk) = try await mint(typ: SdJwtVcSpec.mediaSubtypeDCSdJWT)
    let result = try await verifier(for: jwk).verifyIssuance(unverifiedSdJwt: serialised)
    XCTAssertNoThrow(try result.get())
  }

  // The typ check throws directly out of verifyIssuance (not into the
  // returned Result), so we need a do/catch here rather than
  // XCTAssertThrowsError on .get().

  func test_defaults_rejectsVcSdJwt() async throws {
    // Parity with Kotlin: the legacy vc+sd-jwt draft is NOT in the default
    // allow-list. Callers that still verify older-draft tokens must opt in.
    let (serialised, jwk) = try await mint(typ: "vc+sd-jwt")
    do {
      _ = try await verifier(for: jwk).verifyIssuance(unverifiedSdJwt: serialised)
      XCTFail("expected invalidTypHeader throw")
    } catch SDJWTVerifierError.invalidTypHeader(_, let found) {
      XCTAssertEqual(found, "vc+sd-jwt")
    }
  }

  func test_defaults_rejectsUnknownTyp() async throws {
    let (serialised, jwk) = try await mint(typ: "evil+sd-jwt")
    do {
      _ = try await verifier(for: jwk).verifyIssuance(unverifiedSdJwt: serialised)
      XCTFail("expected invalidTypHeader throw")
    } catch SDJWTVerifierError.invalidTypHeader(_, let found) {
      XCTAssertEqual(found, "evil+sd-jwt")
    }
  }

  func test_defaults_rejectsMissingTyp() async throws {
    let (serialised, jwk) = try await mint(typ: nil)
    do {
      _ = try await verifier(for: jwk).verifyIssuance(unverifiedSdJwt: serialised)
      XCTFail("expected invalidTypHeader throw")
    } catch SDJWTVerifierError.invalidTypHeader(_, let found) {
      XCTAssertNil(found)
    }
  }

  // MARK: - Explicit allow-list opt-in

  func test_customAllowList_acceptsVcSdJwt_whenOptedIn() async throws {
    let (serialised, jwk) = try await mint(typ: "vc+sd-jwt")
    let result = try await verifier(
      for: jwk,
      allowedTypes: [SdJwtVcSpec.mediaSubtypeDCSdJWT, "vc+sd-jwt"]
    ).verifyIssuance(unverifiedSdJwt: serialised)
    XCTAssertNoThrow(try result.get())
  }

  func test_customAllowList_acceptsLegacyJWT_whenOptedIn() async throws {
    let (serialised, jwk) = try await mint(typ: "JWT")
    let result = try await verifier(
      for: jwk,
      allowedTypes: [SdJwtVcSpec.mediaSubtypeDCSdJWT, "JWT"]
    ).verifyIssuance(unverifiedSdJwt: serialised)
    XCTAssertNoThrow(try result.get())
  }
}
