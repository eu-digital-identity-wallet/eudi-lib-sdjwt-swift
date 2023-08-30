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

final class DigestTest: XCTestCase {

  func testJWTCreation() {

    let parts = ["6qMQvRL5haj", "family_name", "Möbius"]
    let salt = parts[0]
    let key = parts[1]
    let value = parts [2]

    let factory = SDJWTFactory(saltProvider: MockSaltProvider(saltString: salt))

    let disclose = factory.createJWT(sdjwtObject: ["family_name": .flat(value: value)])
    switch disclose {
    case .success((let json, let disclosures)):
      XCTAssertEqual(disclosures.first, "WyI2cU1RdlJMNWhhaiIsImZhbWlseV9uYW1lIiwiTcO2Yml1cyJd")
      //      XCTAssertEqual(json[Keys.sd.rawValue].arrayValue.contains("uutlBuYeMDyjLLTpf6Jxi7yNkEF35jdyWMn9U7b_RYY"), true)
    case .failure(let err):
      XCTFail("Failed to Create SDJWT")
    }

  }

  func testHashing() {
    //     ["6qMQvRL5haj", "family_name", "Möbius"]
    //    ["2GLC42sKQveCfGfryNRN9w", "street_address", "Schulst. 12"]
    let base64String = "WyI2cU1RdlJMNWhhaiIsICJmYW1pbHlfbmFtZSIsICJNw7ZiaXVzIl0"
    print(base64String.base64ToUTF8())
    let signer = DigestCreator()
    let out = signer.hashAndBase64Encode(input: base64String)
    print(out)
    let output = "uutlBuYeMDyjLLTpf6Jxi7yNkEF35jdyWMn9U7b_RYY"

    XCTAssertEqual(out, output)
  }

  func testHashing2() {
    //     ["6qMQvRL5haj", "family_name", "Möbius"]
    //    ["2GLC42sKQveCfGfryNRN9w", "street_address", "Schulst. 12"]
    // Test for values with no space between values (remove line
    let base64String = "WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgInN0cmVldF9hZGRyZXNzIiwgIlNjaHVsc3RyLiAxMiJd"
    let signer = DigestCreator()
    let out = signer.hashAndBase64Encode(input: base64String)
    print(out)
    let output = "9gjVuXtdFROCgRrtNcGUXmF65rdezi_6Er_j76kmYyM"

    XCTAssertEqual(out, output)
  }

  func testArrayHashing() {
    let string =
    """
    ["lklxF5jMYlGTPUovMNIvCA", "FR"]
    """
    let base64 = string.toBase64URLEncoded()!

    let base64String = "WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgIkZSIl0"
    XCTAssert(base64 == base64String)
    let signer = DigestCreator()
    let out = signer.hashAndBase64Encode(input: base64)
    print(out)
    let output = "w0I8EKcdCtUPkGCNUrfwVp2xEgNjtoIDlOxc9-PlOhs"
  }
}
