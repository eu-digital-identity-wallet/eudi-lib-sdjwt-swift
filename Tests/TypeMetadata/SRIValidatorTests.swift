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
import CryptoKit
@testable import eudi_lib_sdjwt_swift

final class SRIValidatorTests: XCTestCase {
  
  let testString = "asdasdas"
  let testData = "asdasdas".data(using: .utf8)!
  
  func testValidationSucceedsWhenHashExistsInStrongestHashes() throws {
    // SHA-512 hash of "asdasdas"
    let sha512Hash = Data(SHA512.hash(data: testData)).base64EncodedString()
    
    let expectedIntegrity = try DocumentIntegrity(
      "sha384-Li9vy3DqF8tnTXuiaAJuML3ky+er10rcgNR/VqsVpcw+ThHmYcwiB1pbOxEbzJr7 " +
      "sha384-H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO?asdasdsadsadsad " +
      "sha512-Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw== " +
      "sha512-\(sha512Hash)"
    )
    
    let validator = try SRIValidator()
    let validationResult = validator.isValid(expectedIntegrity: expectedIntegrity, content: testData)
    
    XCTAssertTrue(validationResult)
  }
  
  func testValidationFailsWhenHashDoesNotExistInStrongestHashes() throws {
    let expectedIntegrity = try DocumentIntegrity(
      "sha384-Li9vy3DqF8tnTXuiaAJuML3ky+er10rcgNR/VqsVpcw+ThHmYcwiB1pbOxEbzJr7 " +
      "sha384-H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO?asdasdsadsadsad " +
      "sha512-Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw== " +
      "sha384-tLL38NKkjSrUzPZcxdw2Cje4pvsXFicllTGy7hgenGSdRfaU7jSVqscGaV9OjUq6UmeHJXyoPYrCiwQcR3r5uw=="
    )
    
    let validator = try SRIValidator()
    let validationResult = validator.isValid(expectedIntegrity: expectedIntegrity, content: testData)
    
    XCTAssertFalse(validationResult)
  }
  
  func testValidationFailsWhenHashDoesNotExistInProvidedHashes() throws {
    let expectedIntegrity = try DocumentIntegrity(
      "sha384-Li9vy3DqF8tnTXuiaAJuML3ky+er10rcgNR/VqsVpcw+ThHmYcwiB1pbOxEbzJr7 " +
      "sha384-H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO?asdasdsadsadsad " +
      "sha512-Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw=="
    )
    
    let validator = try SRIValidator()
    let validationResult = validator.isValid(expectedIntegrity: expectedIntegrity, content: testData)
    
    XCTAssertFalse(validationResult)
  }
  
  func testValidationWithOnlyAllowedAlgorithms() throws {
    // SHA-256 hash of "asdasdas"
    let sha256Hash = Data(SHA256.hash(data: testData)).base64EncodedString()
    
    let expectedIntegrity = try DocumentIntegrity(
      "sha256-\(sha256Hash) " +
      "sha512-Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw=="
    )
    
    // Only allow SHA256
    let validator = try SRIValidator(allowedAlgorithms: [.sha256])
    let validationResult = validator.isValid(expectedIntegrity: expectedIntegrity, content: testData)
    
    XCTAssertTrue(validationResult)
  }
  
  func testValidationSelectsStrongestAlgorithm() throws {
    // SHA-512 hash of "asdasdas"
    let sha512Hash = Data(SHA512.hash(data: testData)).base64EncodedString()
    // SHA-256 hash of "asdasdas"
    let sha256Hash = Data(SHA256.hash(data: testData)).base64EncodedString()
    
    let expectedIntegrity = try DocumentIntegrity(
      "sha256-\(sha256Hash) " +
      "sha512-\(sha512Hash)"
    )
    
    let validator = try SRIValidator()
    let validationResult = validator.isValid(expectedIntegrity: expectedIntegrity, content: testData)
    
    // Should validate against SHA-512 (strongest)
    XCTAssertTrue(validationResult)
  }
  
  func testValidationIgnoresWeakerAlgorithmWhenStrongerExists() throws {
    // Wrong SHA-256 hash
    let wrongSha256Hash = "wronghash123456789"
    // SHA-512 hash of "asdasdas"
    let sha512Hash = Data(SHA512.hash(data: testData)).base64EncodedString()
    
    let expectedIntegrity = try DocumentIntegrity(
      "sha256-\(wrongSha256Hash) " +
      "sha512-\(sha512Hash)"
    )
    
    let validator = try SRIValidator()
    let validationResult = validator.isValid(expectedIntegrity: expectedIntegrity, content: testData)
    
    // Should ignore wrong SHA-256 and validate against correct SHA-512
    XCTAssertTrue(validationResult)
  }
}

