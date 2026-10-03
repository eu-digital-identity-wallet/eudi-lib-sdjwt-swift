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
import JSONWebKey
import JSONWebSignature
import JSONWebToken

@testable import eudi_lib_sdjwt_swift

/// TypeMetadataPolicy.optional must only
/// swallow metadata-availability errors (bad URL, unsupported scheme,
/// missing resource, network failure). All other errors — integrity,
/// schema, disclosure, override violations — must still propagate.
final class OptionalPolicyErrorFilterTest: XCTestCase {

  /// Injectable mock that throws a chosen error on both verifyTypeMetadata overloads.
  private final class ThrowingTypeMetadataVerifier: TypeMetadataVerifierType {
    let error: Error
    init(error: Error) { self.error = error }
    func verifyTypeMetadata(sdJwt: SignedSDJWT) async throws {
      throw error
    }
    func verifyTypeMetadata(for vcts: Set<String>, sdJwt: SignedSDJWT) async throws {
      throw error
    }
  }

  private func issueSampleSDJWT() async throws -> (SignedSDJWT, JWK) {
    var issuerJwk = try issuersKeyPair.public.jwk
    issuerJwk.keyID = "kid-1"
    let signed = try await SDJWTIssuer.issue(
      issuersPrivateKey: issuersKeyPair.private,
      header: DefaultJWSHeaderImpl(algorithm: .ES256, keyID: "kid-1", type: "dc+sd-jwt")
    ) {
      ConstantClaims.iss(domain: "did:web:example.com")
      ConstantClaims.iat(time: Date())
      PlainClaim("vct", "https://example.com/vct")
      FlatDisclosedClaim("given_name", "John")
    }
    return (signed, issuerJwk)
  }

  private func verifier(withPolicyError error: Error, issuerJwk: JWK) -> SDJWTVCVerifier {
    SDJWTVCVerifier(
      verificationMethod: .did(lookup: DIDPublicKeyLookupAgent(jwk: issuerJwk)),
      typeMetadataPolicy: .optional(
        verifier: ThrowingTypeMetadataVerifier(error: error)
      )
    )
  }

  // MARK: - Hard errors (must propagate)

  func testOptionalPolicy_IntegrityValidationFailed_Propagates() async throws {
    let (sdjwt, jwk) = try await issueSampleSDJWT()
    let v = verifier(withPolicyError: TypeMetadataError.integrityValidationFailed, issuerJwk: jwk)
    do {
      _ = try await v.verifyIssuance(unverifiedSdJwt: sdjwt.serialisation)
      XCTFail("Expected integrity error to propagate under .optional")
    } catch let error as TypeMetadataError {
      XCTAssertEqual(error, .integrityValidationFailed)
    }
  }

  func testOptionalPolicy_SchemaValidationFailed_Propagates() async throws {
    let (sdjwt, jwk) = try await issueSampleSDJWT()
    let v = verifier(
      withPolicyError: TypeMetadataError.schemaValidationFailed(description: "bad field"),
      issuerJwk: jwk
    )
    do {
      _ = try await v.verifyIssuance(unverifiedSdJwt: sdjwt.serialisation)
      XCTFail("Expected schema error to propagate under .optional")
    } catch let error as TypeMetadataError {
      if case .schemaValidationFailed = error { /* ok */ }
      else { XCTFail("Expected schemaValidationFailed, got \(error)") }
    }
  }

  func testOptionalPolicy_VctIntegrityCheckFailed_Propagates() async throws {
    let (sdjwt, jwk) = try await issueSampleSDJWT()
    let v = verifier(withPolicyError: TypeMetadataError.vctIntegrityCheckFailed, issuerJwk: jwk)
    do {
      _ = try await v.verifyIssuance(unverifiedSdJwt: sdjwt.serialisation)
      XCTFail("Expected vct integrity error to propagate under .optional")
    } catch let error as TypeMetadataError {
      XCTAssertEqual(error, .vctIntegrityCheckFailed)
    }
  }

  // MARK: - Soft errors (must be swallowed)

  func testOptionalPolicy_MissingTypeMetadata_Swallowed() async throws {
    let (sdjwt, jwk) = try await issueSampleSDJWT()
    let v = verifier(withPolicyError: TypeMetadataError.missingTypeMetadata, issuerJwk: jwk)
    let result = try await v.verifyIssuance(unverifiedSdJwt: sdjwt.serialisation)
    XCTAssertNoThrow(try result.get(), "missingTypeMetadata is an availability error and must be swallowed under .optional")
  }

  func testOptionalPolicy_InvalidTypeMetadataURL_Swallowed() async throws {
    let (sdjwt, jwk) = try await issueSampleSDJWT()
    let v = verifier(withPolicyError: TypeMetadataError.invalidTypeMetadataURL, issuerJwk: jwk)
    let result = try await v.verifyIssuance(unverifiedSdJwt: sdjwt.serialisation)
    XCTAssertNoThrow(try result.get(), "invalidTypeMetadataURL is an availability error and must be swallowed under .optional")
  }

  func testOptionalPolicy_URLError_Swallowed() async throws {
    let (sdjwt, jwk) = try await issueSampleSDJWT()
    let v = verifier(withPolicyError: URLError(.notConnectedToInternet), issuerJwk: jwk)
    let result = try await v.verifyIssuance(unverifiedSdJwt: sdjwt.serialisation)
    XCTAssertNoThrow(try result.get(), "URLError is a network availability error and must be swallowed under .optional")
  }
}
