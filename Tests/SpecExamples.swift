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

@testable import eudi_lib_sdjwt_swift

final class SpecExamples: XCTestCase {

  func testStructuredClaims_AsProvidedByTheSpec() throws {

    let factory = SDJWTFactory(saltProvider: DefaultSaltProvider(), decoysLimit: 6)

    @SDJWTBuilder
    var structuredSDJWT: SdElement {
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
    }
    XCTAssert(structuredSDJWT.expectedDigests == 10)
    let output = factory.createSDJWTPayload(sdJwtObject: structuredSDJWT.asObject)

    let keyPair = generateES256KeyPair()

    let sdjwt = try SDJWTIssuer.createSDJWT(purpose: .issuance(DefaultJWSHeaderImpl(algorithm: .ES256), output.get()), signingKey: keyPair.private)

    let string = CompactSerialiser(signedSDJWT: sdjwt).serialised

    let disclosureVerifierOut = try DisclosuresVerifier(parser: CompactParser(serialisedString: string)).verify()

    validateObjectResults(factoryResult: output,
                          expectedDigests: disclosureVerifierOut.digestsFoundOnPayload.count,
                          numberOfDecoys: factory.decoyCounter,
                          decoysLimit: 6)

  }

  func testComplexClaims_AsProvidedByTheSpec() throws {
    let factory = SDJWTFactory(saltProvider: DefaultSaltProvider())

    @SDJWTBuilder
    var evidenceObject: SdElement {
      FlatDisclosedClaim("type", "document")
      FlatDisclosedClaim("method", "pipp")
      FlatDisclosedClaim("time", "2012-04-22T11:30Z")
      FlatDisclosedClaim("document") {
        PlainClaim("type", "idcard")
        ObjectClaim("issuer") {
          PlainClaim("name", "Stadt Augsburg")
          PlainClaim("country", "DE")
        }
        PlainClaim("number", "53554554")
        PlainClaim("date_of_issuance", "2010-03-23")
        PlainClaim("date_of_expiry", "2020-03-22")
      }

    }
    // .......
    @SDJWTBuilder
    var complex: SdElement {

      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date() + 3600)
      ConstantClaims.iss(domain: "https://example.com/issuer")

      ObjectClaim("verified_claims") {
        ObjectClaim("verification") {
          PlainClaim("trust_framework", "de_aml")
          FlatDisclosedClaim("time", "2012-04-23T18:25Z")
          FlatDisclosedClaim("verification_process", "f24c6f-6d3f-4ec5-973e-b0d8506f3bc7")
          ArrayClaim("evidence", array: [
            evidenceObject
          ])

        }
        ObjectClaim("claims") {
          FlatDisclosedClaim("given_name", "Max")
          FlatDisclosedClaim("family_name", "Müller")
          FlatDisclosedClaim("nationalities", ["DE"])
          FlatDisclosedClaim("birthdate", "1956-01-28")
          FlatDisclosedClaim("place_of_birth", ["country": "IS",
                                                "locality": "Þykkvabæjarklaustur"])
          FlatDisclosedClaim("address", ["locality": "Maxstadt",
                                         "postal_code": "12344",
                                         "country": "DE",
                                         "street_address": "Weidenstraße 22"])
        }
      }

      FlatDisclosedClaim("birth_middle_name", "Timotheus")
      FlatDisclosedClaim("salutation", "Dr.")
      FlatDisclosedClaim("msisdn", "49123456789")
    }

    let output = factory.createSDJWTPayload(sdJwtObject: complex.asObject)
    let digestCount = try XCTUnwrap(try? output.get().value.findDigestCount())
    validateObjectResults(factoryResult: output, expectedDigests: 16)

    try output.get().disclosures.forEach { disclosure in
      print(disclosure.base64URLDecode())
    }
    let findDigest = try? XCTUnwrap(output.get())
  }
}
