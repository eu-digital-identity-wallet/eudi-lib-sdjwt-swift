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

  func testJWTCreation() {

    let parts = ["_26bc4LT-ac6q2KI6cBW5es", "family_name", "Möbius"]
    let salt = parts[0]
    let key = parts[1]
    let value = parts [2]

    let factory = SDJWTFactory(saltProvider: MockSaltProvider(saltString: salt))

    let array: [Encodable] = ["", 123]

    @SDJWTBuilder
    var jwt: SdElement {
      FlatDisclosedClaim(key, value)
      FlatDisclosedClaim("object", 123)
//      PlainClaim("nick", "sal")
    }

    let unsignedJwt = factory.createJWT(sdjwtObject: jwt.asObject)

    switch unsignedJwt {
    case .success((let json, let disclosures)):
      print(try? json.toJSONString(outputFormatting: .prettyPrinted))
      print(disclosures)
    case .failure(let err):
      XCTFail("Failed to Create SDJWT")
    }

  }


}
