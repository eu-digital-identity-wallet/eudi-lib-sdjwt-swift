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

/// OpenID4VP 1.0 section 7.3: the path ["address"] selects "the claim address with its sub-claims as the value".
final class SubClaimPresentationTests: XCTestCase {

  private func issue() async throws -> SignedSDJWT {
    try await SDJWTIssuer.issue(
      issuersPrivateKey: issuersKeyPair.private,
      header: DefaultJWSHeaderImpl(algorithm: .ES256)
    ) {
      ConstantClaims.iss(domain: "https://example.com/issuer")
      FlatDisclosedClaim("given_name", "Erika")
      // The object and each sub-claim are selectively disclosable.
      RecursiveObject("address") {
        FlatDisclosedClaim("street_address", "Heidestrasse 17")
        FlatDisclosedClaim("locality", "Koeln")
      }
      // The object is always disclosed. Each sub-claim is selectively disclosable.
      ObjectClaim("place_of_birth") {
        FlatDisclosedClaim("locality", "Berlin")
        FlatDisclosedClaim("country", "DE")
      }
    }
  }

  func testRecursiveObjectDisclosesAllSubClaims() async throws {
    let sdJwt = try await issue()
    let presented = try XCTUnwrap(try sdJwt.present(query: [.claim("address")]))
    let claims = try presented.recreateClaims().recreatedClaims

    XCTAssertEqual(claims["address"]["street_address"].string, "Heidestrasse 17")
    XCTAssertEqual(claims["address"]["locality"].string, "Koeln")
    XCTAssertFalse(claims["given_name"].exists())
  }

  func testPlainObjectDisclosesAllSubClaims() async throws {
    let sdJwt = try await issue()
    let presented = try XCTUnwrap(try sdJwt.present(query: [.claim("place_of_birth")]))
    let claims = try presented.recreateClaims().recreatedClaims

    XCTAssertEqual(claims["place_of_birth"]["locality"].string, "Berlin")
    XCTAssertEqual(claims["place_of_birth"]["country"].string, "DE")
  }

  func testSubClaimPathDisclosesOnlyThatSubClaim() async throws {
    let query: Set<ClaimPath> = [ClaimPath([.claim(name: "address"), .claim(name: "locality")])]
    let sdJwt = try await issue()
    let presented = try XCTUnwrap(try sdJwt.present(query: query))
    let claims = try presented.recreateClaims().recreatedClaims

    XCTAssertEqual(claims["address"]["locality"].string, "Koeln")
    XCTAssertFalse(claims["address"]["street_address"].exists())
  }

  func testIsSelectedBy() {
    let address = ClaimPath([.claim(name: "address")])
    let locality = ClaimPath([.claim(name: "address"), .claim(name: "locality")])
    let firstNationality = ClaimPath([.claim(name: "nationalities"), .arrayElement(index: 0)])

    XCTAssertTrue(locality.isSelected(by: address))
    XCTAssertTrue(locality.isSelected(by: locality))
    XCTAssertFalse(address.isSelected(by: locality))
    XCTAssertFalse(locality.isSelected(by: ClaimPath([.claim(name: "place_of_birth")])))
    XCTAssertTrue(firstNationality.isSelected(by: ClaimPath([.claim(name: "nationalities")])))
    XCTAssertTrue(firstNationality.isSelected(by: ClaimPath([.claim(name: "nationalities"), .allArrayElements])))
    XCTAssertFalse(firstNationality.isSelected(by: ClaimPath([.claim(name: "nationalities"), .arrayElement(index: 1)])))
  }
}
