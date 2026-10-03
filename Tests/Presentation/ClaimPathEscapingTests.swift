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
import SwiftyJSON
import XCTest
import Crypto

@testable import eudi_lib_sdjwt_swift

// Regression coverage for the JSON Pointer round-trip bug: the encoder used
// to join claim names into a path with `/` without escaping, while the
// decoder splits on `/` and unescapes `~0`/`~1`. A claim literally named
// `address/country` would decode as the nested path `address.country`, so
// requests for the real nested claim could return the wrong disclosure (or
// none at all).
final class ClaimPathEscapingTests: XCTestCase {

  // MARK: - Helpers

  private func mint(
    disclosedClaimName: String,
    disclosedValue: String = "value"
  ) async throws -> SignedSDJWT {
    let privateKey = P256.Signing.PrivateKey()
    return try await SDJWTIssuer.issue(
      issuersPrivateKey: privateKey,
      header: DefaultJWSHeaderImpl(algorithm: .ES256, type: "dc+sd-jwt")
    ) {
      ConstantClaims.iss(domain: "did:web:example.com")
      FlatDisclosedClaim(disclosedClaimName, disclosedValue)
    }
  }

  private func pathKeys(of sdJwt: SignedSDJWT) throws -> [ClaimPath] {
    let visitor = ClaimVisitor()
    _ = try sdJwt.recreateClaims(visitor: visitor)
    return Array(visitor.disclosuresPerClaimPath.keys)
  }

  // MARK: - Escaping

  func test_slashInClaimName_producesSingleClaimElement() async throws {
    let sdJwt = try await mint(disclosedClaimName: "address/country")
    let paths = try pathKeys(of: sdJwt)

    // Pre-fix, this would have been [.claim("address"), .claim("country")].
    XCTAssertTrue(
      paths.contains(ClaimPath([.claim(name: "address/country")])),
      "expected single-element path for 'address/country', got \(paths)"
    )
  }

  func test_tildeInClaimName_producesSingleClaimElement() async throws {
    let sdJwt = try await mint(disclosedClaimName: "foo~bar")
    let paths = try pathKeys(of: sdJwt)

    XCTAssertTrue(
      paths.contains(ClaimPath([.claim(name: "foo~bar")])),
      "expected single-element path for 'foo~bar', got \(paths)"
    )
  }

  func test_bothEscapesInClaimName() async throws {
    let sdJwt = try await mint(disclosedClaimName: "a/b~c")
    let paths = try pathKeys(of: sdJwt)

    XCTAssertTrue(
      paths.contains(ClaimPath([.claim(name: "a/b~c")])),
      "expected single-element path for 'a/b~c', got \(paths)"
    )
  }

  func test_nonSpecialName_unchanged() async throws {
    let sdJwt = try await mint(disclosedClaimName: "given_name")
    let paths = try pathKeys(of: sdJwt)

    XCTAssertTrue(
      paths.contains(ClaimPath([.claim(name: "given_name")])),
      "expected single-element path for 'given_name', got \(paths)"
    )
  }
}
