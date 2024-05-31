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

import XCTest
import JSONWebKey
import JSONWebSignature
import SwiftyJSON

@testable import eudi_lib_sdjwt_swift

final class IssuerTest: XCTestCase {

  func testIssuer_ForIssuance_WhenProvidedWithAsetOfClaimsAndIssuersPrivateKey() throws -> SignedSDJWT {
    let signedSDJWT = try SDJWTIssuer.issue(
        issuersPrivateKey: issuersKeyPair.private,
        header: DefaultJWSHeaderImpl(algorithm: .ES256)) {
        ConstantClaims.iat(time: Date())
        ConstantClaims.sub(subject: "Test Subject")
        PlainClaim("name", "plain name")
        FlatDisclosedClaim("hidden name", "disclosedName")
    }

    return signedSDJWT
  }

  func testCompactFormatSerialisation_WhenProvidedWithABuiltSDJWT() throws {
    let sdjwt = try self.testIssuer_ForIssuance_WhenProvidedWithAsetOfClaimsAndIssuersPrivateKey()

    let compactSerializer = CompactSerialiser(signedSDJWT: sdjwt)

    let jwtString = compactSerializer.serialised.components(separatedBy: "~").first!

    let jws = try JWS(jwsString: jwtString)
    XCTAssertTrue(try jws.verify(key: issuersKeyPair.public))
  }

  func testEnvelopedFormatSerializeation_WhenProvidedWithABuiltSDJWT() throws {
    let sdjwt = try self.testIssuer_ForIssuance_WhenProvidedWithAsetOfClaimsAndIssuersPrivateKey()
//    let envelopeJWT = try JWT(header: .init(parameters: [Keys.sdAlg.rawValue: SignatureAlgorithm.ES256.rawValue]),
//                              payload: JSON([
//                                  "aud": "https://verifier.example.com",
//                                  "iat": 1580000000,
//                                  "nonce": "iRnRdKuu1AtLM4ltc16by2XF0accSeutUescRw6BWC14"
//                              ]))

    let payload = try JSON([
        "aud": "https://verifier.example.com",
        "iat": 1580000000,
        "nonce": "iRnRdKuu1AtLM4ltc16by2XF0accSeutUescRw6BWC14"]).rawData()

    let envelopedFormat = try EnvelopedSerialiser(SDJWT: sdjwt,
                                              jwTpayload: payload)

    let jwt = try JWT(header: DefaultJWSHeaderImpl(algorithm: .ES256), payload: JSON(envelopedFormat.data))
    print(jwt.payload)
  }
}
