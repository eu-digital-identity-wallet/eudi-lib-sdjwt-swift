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
  
  func test() async throws {
    
    
    let issuersKey = issuersKeyPair.public
    let issuerJwk = try issuersKey.jwk
    
    let holdersKey = holdersKeyPair.public
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
    
    let issuerSignedSDJWT = try SDJWTIssuer.issue(
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
    
    let query: Set<JSONPointer> = Set(
      ["/address/region", "/address/country"]
        .compactMap {
          JSONPointer(pointer: $0)
        }
    )

    
    let presentedSdJwt = try await issuerSignedSDJWT.present(
      query: query
    )
    
    // po CompactSerialiser(signedSDJWT: presentedSdJwt!).serialised
//    print(presentedSdJwt)
  }
}

