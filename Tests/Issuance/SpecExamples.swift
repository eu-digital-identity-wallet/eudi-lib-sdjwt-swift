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
import XCTest

@testable import eudi_lib_sdjwt_swift

final class SpecExamples: XCTestCase {

  func testStructuredClaims() {
    let claimSet = """
                  {
                    "sub": "6c5c0a49-b589-431d-bae7-219122a9ec2c",
                    "given_name": "太郎",
                    "family_name": "山田",
                    "email": "\"unusual email address\"@example.jp",
                    "phone_number": "+81-80-1234-5678",
                    "address": {
                      "street_address": "東京都港区芝公園４丁目２−８",
                      "locality": "東京都",
                      "region": "港区",
                      "country": "JP"
                    },
                    "birthdate": "1940-01-01"
                  }
                  """

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
    let output = factory.createJWT(sdjwtObject: structuredSDJWT.asObject)
    validateObjectResults(factoryResult: output,
                          expectedDigests: structuredSDJWT.expectedDigests,
                          numberOfDecoys: factory.decoyCounter,
                          decoysLimit: 6)

  }

  func testComplex() {
    let factory = SDJWTFactory(saltProvider: DefaultSaltProvider())
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
          SdArrayClaim("evidence") {
            // TODO: Improve array builder functionality
            evidenceObject
          }
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
    // .......
    @SDJWTBuilder
    var evidenceObject: SdElement {
      PlainClaim("type", "document")
      PlainClaim("method", "pipp")
      PlainClaim("time", "2012-04-22T11:30Z")
      ObjectClaim("document") {
        PlainClaim("type", "idcard")
        ObjectClaim("issuer") {
          PlainClaim("name", "Stadt Augsburg")
          PlainClaim("country", "DE")
        }
      }

      PlainClaim("number", "53554554")
      PlainClaim("date_of_issuance", "2010-03-23")
      PlainClaim("date_of_expiry", "2020-03-22")
    }

    let exampleOutputJSON = JSON(stringLiteral: exampleOutputJSONString)

    let disclosuresCount = exampleOutputJSON.reduce(into: 0) { _, _ in

    }

    let output = factory.createJWT(sdjwtObject: complex.asObject)
    validateObjectResults(factoryResult: output, expectedDigests: 12)

    //    {
    //      "exp" : 1693239709.7396131,
    //      "iss" : "https:\/\/example.com\/issuer",
    //      "_sd_alg" : "sha-256",
    //      "verified_claims" : {
    //        "claims" : {
    //          "_sd" : [
    //            "3HwacVS1XBITeX1SU-PZ7oN6WKG39F2ijhQo3zXjK7Q",
    //            "yFAUAJ0B05uk2FdjWj3YSQDc-IBqeF1dHjjwjcWrFO8",
    //            "pHhCZ0VB8Sk6ejiX_hCgLdohtPR3NNxQU5ZjVpFYb1o",
    //            "7ucE3FPsAQQW_GvtrTQS0560sJXHWLq1So8Fuhv6xsE",
    //            "h99kTE7hkuq7cH4lIXnpt9zdP_7nDboFGwAokbyo4HQ",
    //            "Zz8nRP6-t4te8859QESGcSEaIW7Rercj4RiwGmIT21g"
    //          ]
    //        },
    //        "verification" : {
    //          "trust_framework" : "de_aml",
    //          "_sd" : [
    //            "C-jWw7K-x8ruTh_K3iBi_m97mFjqodOk9_jVze4ABHw",
    //            "1xSdseTWy2TGejjtQvfsmLE-Pq-nBIHQU9zf4jVT6uw"
    //          ],
    //          "evidence" : [
    //            {
    //              "..." : "RU2wzGWlRAkGBFfJLB5tZEdpJCtncbN7savv_zVcfts"
    //            }
    //          ]
    //        }
    //      },
    //      "_sd" : [
    //        "yb2NuI5AaAQSCwgJYxJxeGRmRCjqNwBn7hwcWdvmLFI",
    //        "zGZ_3mUpNREPOIYXJGo6VQTVhA6mOI-yXj0wDuBIqlU",
    //        "mZCoFe1CA5LNaD0dK07PgRIYh_3zkbh4o_fV2ajRfVA"
    //      ],
    //      "iat" : 1693236109.739372
    //    }
    //  }
    //
    //  ["ZWw-JUEmgPX9_DvrjMyxWA","msisdn","49123456789"]
    //  ["S4KcbbjCoRmBrhAiElXU7w","given_name","Max"]
    //  ["SEjvR_WhgRUyxLlGlbMe2w","address",{"locality":"Maxstadt","country":"DE","street_address":"Weidenstraße 22","postal_code":"12344"}]
    //  ["Z7-HdnOWQgNJTkTJUL23qA","nationalities",["DE"]]
    //  ["YL-FWCd6hjmcrtdtvJIZvQ","family_name","Müller"]
    //  ["3K3gwGG9WCG6yZ-SZLZ2Yg","place_of_birth",{"country":"IS","locality":"Þykkvabæjarklaustur"}]
    //  ["BwwMnkt2UfpxDMIsGJrY5w","birthdate","1956-01-28"]
    //  ["2C0LyFJMN0tEePxEPKoXyg","verification_process","f24c6f-6d3f-4ec5-973e-b0d8506f3bc7"]
    //  ["nvTG9dLN_lXyya7z2V-U_g",{"number":"53554554","method":"pipp","time":"2012-04-22T11:30Z","document":{"type":"idcard","issuer":{"name":"Stadt Augsburg","country":"DE"}},"date_of_issuance":"2010-03-23","date_of_expiry":"2020-03-22","type":"document"}]
    //  ["uOB-3MvBiByePb-fKF6m0A","time","2012-04-23T18:25Z"]
    //  ["AnIdB9NcoBBtX5QBTK0ErA","birth_middle_name","Timotheus"]
    //  ["biPz1nKQ6ShlMyckuSeMRQ","salutation","Dr."]
  }

  let exampleOutputJSONString =
  """
  {
    "_sd": [
      "-aSznId9mWM8ocuQolCllsxVggq1-vHW4OtnhUtVmWw",
      "IKbrYNn3vA7WEFrysvbdBJjDDU_EvQIr0W18vTRpUSg",
      "otkxuT14nBiwzNJ3MPaOitOl9pVnXOaEHal_xkyNfKI"
    ],
    "iss": "https://example.com/issuer",
    "iat": 1683000000,
    "exp": 1883000000,
    "verified_claims": {
      "verification": {
        "_sd": [
          "7h4UE9qScvDKodXVCuoKfKBJpVBfXMF_TmAGVaZe3Sc",
          "vTwe3raHIFYgFA3xaUD2aMxFz5oDo8iBu05qKlOg9Lw"
        ],
        "trust_framework": "de_aml",
        "evidence": [
          {
            "...": "tYJ0TDucyZZCRMbROG4qRO5vkPSFRxFhUELc18CSl3k"
          }
        ]
      },
      "claims": {
        "_sd": [
          "RiOiCn6_w5ZHaadkQMrcQJf0Jte5RwurRs54231DTlo",
          "S_498bbpKzB6Eanftss0xc7cOaoneRr3pKr7NdRmsMo",
          "WNA-UNK7F_zhsAb9syWO6IIQ1uHlTmOU8r8CvJ0cIMk",
          "Wxh_sV3iRH9bgrTBJi-aYHNCLt-vjhX1sd-igOf_9lk",
          "_O-wJiH3enSB4ROHntToQT8JmLtz-mhO2f1c89XoerQ",
          "hvDXhwmGcJQsBCA2OtjuLAcwAMpDsaU0nkovcKOqWNE"
        ]
      }
    },
    "_sd_alg": "sha-256"
  }
  """
}
