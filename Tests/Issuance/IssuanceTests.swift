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
import CryptoKit
@testable import eudi_lib_sdjwt_swift

final class IssuanceTests: XCTestCase {
  
  var digestCreator = DigestCreator()
  
  func testDisclsure() {
    let parts = ["_26bc4LT-ac6q2KI6cBW5es", "family_name", "Möbius"]
    let salt = parts[0]
    let key = parts[1]
    let value = parts [2]

    let digestCreator = DigestCreator(saltProvider: MockSaltProvider(saltString: salt))

    let flat =
    FlatDisclose(name: key, digestCreator: digestCreator) {
      DisclosedClaim(key, .init(value))
    }
    .asJWTElement()
    print(flat.disclosure)
    XCTAssertTrue(flat.disclosure == "WyJfMjZiYzRMVC1hYzZxMktJNmNCVzVlcyIsICJmYW1pbHlfbmFtZSIsICJNw7ZiaXVzIl0")
  }
  
  func testArray() {
    let parts = ["lklxF5jMYlGTPUovMNIvCA", "FR"]
    let key = "nationalities"
    let salt = parts[0]
    let value = parts[1]
    
    var disclosedClaim = DisclosedClaim(key, .array([.init(value)]))
    
    let disclosure = try? disclosedClaim.base64Encode(saltProvider: DigestCreator(saltProvider: MockSaltProvider(saltString: salt)).saltProvider)
    
    print(disclosure)
    print(disclosure?.flatString)
    
    XCTAssertTrue(disclosure?.flatString.contains("WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgIkZSIl0") == true)
    
  }
  
  func testMixedArray() {
    let plainClaim = PlainClaim("nationalities", .array([.init("DE")]))
    var disclosedArray = DisclosedClaim("nationalities", .array([.init("FR")]))
    
    guard let encodedClaim = try? disclosedArray.base64Encode(saltProvider: MockSaltProvider(saltString: "lklxF5jMYlGTPUovMNIvCA")) else {
      XCTFail()
      return
    }
    
    let mixedClaim = MixedClaim(plainClaim: plainClaim,
                                disclosedClaim: encodedClaim)
    
    print(mixedClaim)
    print(mixedClaim?.flatString)
    
    XCTAssertTrue(mixedClaim?.flatString.contains("WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgIkZSIl0") == true)
    XCTAssertTrue(mixedClaim?.flatString.contains("DE") == true)
    
  }
  
  func testFlatObjectIssueance() {
    let jsonString = """
        "address": {
          "street_address": "123 Main St",
          "locality": "Anytown",
          "region": "Anystate",
          "country": "US"
        }
        """
    
    @SDJWTBuilder
    var testJWT: [String: SDJWTElement] {
//      DisclosedClaim("sub", .base("6c5c0a49-b589-431d-bae7-219122a9ec2c"))
      PlainClaim("iss", .base("https://example.com/issuer"))
      PlainClaim("iat", .base(1516239022))
      PlainClaim("exp", .base(1735689661))
//      FlatDisclose(name: "parts") {
//        return PlainClaim("test", .base("123"))
//      }
      DisclosedClaim("family_name", .base("Möbius"))
      FlatDisclose(name: "adress") {
        DisclosedClaim("address", .init(builder: {
          DisclosedClaim("street_address", .base("Schulstr. 12"))
          DisclosedClaim("locality", .base("Schulpforta"))
          DisclosedClaim("region", .base("Sachsen-Anhalt"))
          DisclosedClaim("country", .base("DE"))
        }))
      }
    }
    
    let builder = Builder(digestCreator: digestCreator)
    //        try? builder.encode(sdjwtRepresentation: testJWT)
    
    XCTAssertNotNil(try? builder.encode(sdjwtRepresentation: testJWT))
  }

  func testHashing() {
    let base64String = "WyI2cU1RdlJMNWhhaiIsICJmYW1pbHlfbmFtZSIsICJNw7ZiaXVzIl0"
    let signer = DigestCreator()
    let out = signer.hashAndBase64Encode(input: base64String)
    print(out)
    let output = "uutlBuYeMDyjLLTpf6Jxi7yNkEF35jdyWMn9U7b_RYY"

    XCTAssertEqual(out, output)
  }
  
  func testBase64Hashing() {
    let claim = DisclosedClaim("family_name", .base("Möbius"))
    //    claim.base64Encode(saltProvider: signer.saltProvider)
    let hashedClaim = FlatDisclose(name: "family_name", digestCreator: DigestCreator(saltProvider: MockSaltProvider(saltString: "6qMQvRL5haj"))) {
      return claim
    }
      .asJWTElement()
    print(hashedClaim.disclosure)
    let output = "uutlBuYeMDyjLLTpf6Jxi7yNkEF35jdyWMn9U7b_RYY"

    switch hashedClaim.claim.value {
    case .array(let hashedArray):
      print(hashedArray)
      let firstValue = hashedArray.first!
      let base = firstValue.value as! String
      XCTAssertEqual(base, output)
    default:
      XCTFail("wrong inputs")
    }

  }

  func testNests() {
    @SDJWTBuilder
    var testJWT: [String: SDJWTElement] {
      DisclosedClaim("address", .init(builder: {
        DisclosedClaim("street_address", .base("Schulstr. 12"))
        DisclosedClaim("locality", .base("Schulpforta"))
        DisclosedClaim("region", .base("Sachsen-Anhalt"))
        DisclosedClaim("country",
                       .object([PlainClaim("test", .base("123"))]))
      }))
      FlatDisclose(name: "test flat") {
        return DisclosedClaim("family_name", .base("Möbius"))
      }
    }

    let builder = Builder(digestCreator: digestCreator)
    //        try? builder.encode(sdjwtRepresentation: testJWT)

    XCTAssertNotNil(try? builder.encode(sdjwtRepresentation: testJWT))
  }

}
