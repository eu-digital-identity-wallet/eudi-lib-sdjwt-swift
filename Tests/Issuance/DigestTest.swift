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

  func testDisclosureCreationg_GivenAfixedInput_ThenExpectBase64encodedDisclosure() {

    let parts = ["6qMQvRL5haj", "family_name", "Möbius"]
    let salt = parts[0]
    _ = parts[1]
    let value = parts [2]

    let factory = SDJWTFactory(saltProvider: MockSaltProvider(saltString: salt))

    let disclose = factory.createSDJWTPayload(sdJwtObject: ["family_name": .flat(value: value)])
    switch disclose {
    case .success((_, let disclosures)):
      XCTAssertEqual(disclosures.first, "WyI2cU1RdlJMNWhhaiIsImZhbWlseV9uYW1lIiwiTcO2Yml1cyJd")
    case .failure:
      XCTFail("Failed to Create SDJWT")
    }

  }

  func testDigestCreationg_GivenAfixedInputWithSpacesAfterEachElement_ThenExpectTheHashedOutputToMatch() {
    // this is the case where we add an extra space after each object
    let base64String = "WyI2cU1RdlJMNWhhaiIsICJmYW1pbHlfbmFtZSIsICJNw7ZiaXVzIl0"
    let signer = DigestCreator()
    let out = signer.hashAndBase64Encode(input: base64String)
    let output = "uutlBuYeMDyjLLTpf6Jxi7yNkEF35jdyWMn9U7b_RYY"

    XCTAssertEqual(out, output)
  }

  func testDigestCreationg_GivenAfixedInputWithoutSpacesAfterEachElement_ThenExpectTheHashedOutputToMatch() {
    // this is the case where we remove the extra space after each object
    let base64String = "WyI2cU1RdlJMNWhhaiIsICJmYW1pbHlfbmFtZSIsICJNw7ZiaXVzIl0"
    let signer = DigestCreator()
    let out = signer.hashAndBase64Encode(input: base64String)
    let output = "uutlBuYeMDyjLLTpf6Jxi7yNkEF35jdyWMn9U7b_RYY"

    XCTAssertEqual(out, output)
  }

  func testDigestCreationg_GivenAnArrayInput_ThenExpectTheHashedOutputToMatch() {
    let string =
    """
    ["lklxF5jMYlGTPUovMNIvCA", "FR"]
    """
    let base64 = string.toBase64URLEncoded()!

    let base64String = "WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgIkZSIl0"
    XCTAssert(base64 == base64String)
    let signer = DigestCreator()
    let out = signer.hashAndBase64Encode(input: base64)
    let output = "w0I8EKcdCtUPkGCNUrfwVp2xEgNjtoIDlOxc9-PlOhs"
    XCTAssert(out == output)
  }
}
