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

// Coverage for the algorithm allow-list. The allow-list check runs in
// SignatureVerifier.init BEFORE any key/signature inspection, so these tests
// hand-craft JWS objects with the target header rather than minting real HMAC
// tokens — the rejection point is the init, not the verification.
final class AlgorithmAllowListTests: XCTestCase {

  // MARK: - Helpers

  /// Build a JWS carrying the given algorithm header. Payload and signature
  /// are arbitrary (zeroes / empty); the allow-list check does not look at
  /// them.
  private func craftJws(
    algorithm: SigningAlgorithm,
    signature: Data = Data([0x00])
  ) throws -> JWS {
    try JWS(
      protectedHeader: DefaultJWSHeaderImpl(algorithm: algorithm),
      data: Data("{}".utf8),
      signature: signature
    )
  }

  private func mintEs256() async throws -> (jws: JWS, jwk: JWK) {
    let privateKey = P256.Signing.PrivateKey()
    var publicJWK = privateKey.jwkRepresentation.publicKey
    publicJWK.algorithm = "ES256"

    let signed = try await SDJWTIssuer.issue(
      issuersPrivateKey: privateKey,
      header: DefaultJWSHeaderImpl(algorithm: .ES256)
    ) {
      ConstantClaims.iss(domain: "did:web:example.com")
      FlatDisclosedClaim("marker", "value")
    }
    return (signed.jwt, publicJWK)
  }

  // MARK: - Default allow-list

  func test_defaults_rejectAlgNone() throws {
    // alg: none with an EMPTY signature would make jose-swift's verify()
    // short-circuit to `true` without touching key or signing input. The
    // allow-list check in init must reject it before it ever gets there.
    let jws = try craftJws(algorithm: .none, signature: Data())
    let anyKey = P256.Signing.PrivateKey().publicKey.jwkRepresentation

    XCTAssertThrowsError(try SignatureVerifier(signedJWT: jws, publicKey: anyKey)) { error in
      guard case SDJWTVerifierError.algorithmNotAllowed(let alg) = error else {
        XCTFail("expected algorithmNotAllowed, got \(error)")
        return
      }
      XCTAssertEqual(alg, SigningAlgorithm.none.rawValue)
    }
  }

  func test_defaults_rejectHMAC_regressionAgainstKeyConfusion() throws {
    // HMAC algorithms are excluded from the default allow-list specifically
    // to prevent jose-swift's prepareJWK from coercing a Data-typed key into
    // an HMAC secret based on an attacker-controlled alg header.
    let jws = try craftJws(algorithm: .HS256)
    let anyKey = P256.Signing.PrivateKey().publicKey.jwkRepresentation

    XCTAssertThrowsError(try SignatureVerifier(signedJWT: jws, publicKey: anyKey)) { error in
      guard case SDJWTVerifierError.algorithmNotAllowed(let alg) = error else {
        XCTFail("expected algorithmNotAllowed, got \(error)")
        return
      }
      XCTAssertEqual(alg, SigningAlgorithm.HS256.rawValue)
    }
  }

  func test_defaults_acceptAsymmetricES256() async throws {
    let (jws, jwk) = try await mintEs256()
    XCTAssertNoThrow(try SignatureVerifier(signedJWT: jws, publicKey: jwk))
  }

  // MARK: - Explicit allow-list

  func test_explicitAllowList_rejectsNonListed() async throws {
    let (jws, jwk) = try await mintEs256()
    XCTAssertThrowsError(
      try SignatureVerifier(
        signedJWT: jws,
        publicKey: jwk,
        allowedAlgorithms: [.ES384]
      )
    ) { error in
      guard case SDJWTVerifierError.algorithmNotAllowed(let alg) = error else {
        XCTFail("expected algorithmNotAllowed, got \(error)")
        return
      }
      XCTAssertEqual(alg, SigningAlgorithm.ES256.rawValue)
    }
  }

  func test_hmacOptIn_initAcceptsHS256() throws {
    // Caller explicitly opts into HMAC; init must accept. (We do not run
    // verify() here — this test is about the allow-list gate, not whether
    // the signature is valid.)
    let jws = try craftJws(algorithm: .HS256)
    let secret = Data("test-shared-secret-at-least-256-bits-long!".utf8)

    XCTAssertNoThrow(
      try SignatureVerifier(
        signedJWT: jws,
        publicKey: secret,
        allowedAlgorithms: [.HS256]
      )
    )
  }

  // MARK: - End-to-end plumbing through SDJWTVCVerifier

  func test_sdjwtVcVerifier_restrictedAllowList_rejectsES256Token() async throws {
    let did = "did:web:example.com"
    let kid = "\(did)#key-1"
    let privateKey = P256.Signing.PrivateKey()

    var publicJWK = privateKey.jwkRepresentation.publicKey
    publicJWK.keyID = kid
    publicJWK.algorithm = "ES256"

    var header = DefaultJWSHeaderImpl(algorithm: .ES256)
    header.keyID = kid

    let signed = try await SDJWTIssuer.issue(
      issuersPrivateKey: privateKey,
      header: header
    ) {
      ConstantClaims.iss(domain: did)
      FlatDisclosedClaim("marker", "value")
    }

    // Verifier configured to accept only ES384; the ES256 token must fail.
    let verifier = SDJWTVCVerifier(
      verificationMethod: .did(lookup: DIDPublicKeyLookupAgent(jwk: publicJWK)),
      allowedAlgorithms: [.ES384]
    )

    let result = try await verifier.verifyIssuance(unverifiedSdJwt: signed.serialisation)
    XCTAssertThrowsError(try result.get()) { error in
      guard case SDJWTVerifierError.algorithmNotAllowed = error else {
        XCTFail("expected algorithmNotAllowed, got \(error)")
        return
      }
    }
  }
}
