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

@testable import eudi_lib_sdjwt_swift

final class BuilderTest: XCTestCase {
  func testBuild() {

    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "Edmun")
      SdArrayClaim("Nationalites", array: [.flat(value: "DE"), .flat(value: 123)])
      ObjectClaim("adress") {
        PlainClaim("locality", "gr")
        FlatDisclosedClaim("adress", "Marathonos 49")
      }
    }

    let sd = sdObject
    XCTAssert(sd.jsonString?.isEmpty == false)
  }

  func testSalt() {

    let salt = "_26bc4LT-ac6q2KI6cBW5es"
    let factory = SDJWTFactory(saltProvider: MockSaltProvider(saltString: salt))

    @SDJWTBuilder
    var jwt: SdElement {
      ObjectClaim("BaseObject") {
        PlainClaim("name", "Sal")
        PlainClaim("adress", "Athens")
        FlatDisclosedClaim("flat_element", "disclosed")
        ObjectClaim("Deep Object") {
          FlatDisclosedClaim("Deep Disclose", "C Level")
          PlainClaim("Deep Plain", "Deep Plain Value")
        }
      }
    }

    let unsignedJwt = factory.createJWT(sdjwtObject: jwt.asObject)

    switch unsignedJwt {
    case .success((let json, let disclosures)):
      print(try! json.toJSONString(outputFormatting: .prettyPrinted))
      print(disclosures)
    case .failure(let err):
      XCTFail("Failed to Create SDJWT")
    }

  }


  func testSalt2() {

    let salt = "_26bc4LT-ac6q2KI6cBW5es"
    let factory = SDJWTFactory(saltProvider: MockSaltProvider(saltString: salt))

    @SDJWTBuilder
    var jwt: SdElement {
      FlatDisclosedClaim("name", "nikos")
    }

    let unsignedJwt = factory.createJWT(sdjwtObject: jwt.asObject)

    switch unsignedJwt {
    case .success((let json, let disclosures)):
      print(try! json.toJSONString(outputFormatting: .prettyPrinted))
      print(disclosures)
    case .failure(let err):
      XCTFail("Failed to Create SDJWT")
    }

  }
}
