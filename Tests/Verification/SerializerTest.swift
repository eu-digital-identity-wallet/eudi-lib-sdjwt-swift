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

@testable import eudi_lib_sdjwt_swift

final class SerialiserTest: XCTestCase {
  func testSerializerWhenSerializedFormatIsSelected_ThenExpectSerialisedFormattedSignedSDJWT() throws -> String {
    let keyBindingTest = KeyBindingTest()
    let (issuersSDJWT, holdersSDJWT) = try keyBindingTest.testKeyBindingCreation_WhenKeybindingIsPresent_ThenExpectCorrectVerification()

    let issuersSerialisedFormat = CompactSerialiser(signedSDJWT: issuersSDJWT).serialised
    XCTAssert(issuersSerialisedFormat.components(separatedBy: "~").count >= 2)

    let holdersSerialisedFormat = CompactSerialiser(signedSDJWT: holdersSDJWT).serialised
    XCTAssert(holdersSerialisedFormat.components(separatedBy: "~").count >= 3)

    return holdersSerialisedFormat
  }

  func testPareserWhenReceivingASerialisedFormatJWT_ThenConstructUnsignedSDJWT() throws {
    let serialisedString = try testSerializerWhenSerializedFormatIsSelected_ThenExpectSerialisedFormattedSignedSDJWT()
    let parser = CompactParser(serialisedString: serialisedString)
    let jwt = try parser.getSignedSdJwt().toSDJWT()
    print(jwt.disclosures)
  }

  func testSerialiseWhenChosingEnvelopeFormat_AppylingNoKeyBinding_ThenExpectACorrectJWT() throws {
    let compactParser = try CompactParser(serialisedString: testSerializerWhenSerializedFormatIsSelected_ThenExpectSerialisedFormattedSignedSDJWT())

    let envelopeSerializer = try EnvelopedSerialiser(
        SDJWT: compactParser.getSignedSdJwt(),
        jwTpayload: JWTBody(nonce: "", aud: "sub", iat: 1234).toJSONData())

    let parser = try EnvelopedParser(serialiserProtocol: envelopeSerializer)

    let verifier = try SDJWTVerifier(parser: parser).verifyIssuance { jws in
      try SignatureVerifier(signedJWT: jws, publicKey: issuersKeyPair.public)
    } claimVerifier: { _, _ in
      ClaimsVerifier()
    }.get()

    print(verifier)
  }

}
