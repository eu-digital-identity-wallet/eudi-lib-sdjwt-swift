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


final class DocumentIntegrityTests: XCTestCase {
  
  func testSingleValidDocumentIntegrityConversion() throws {
    let singleValid = try DocumentIntegrity("sha384-Li9vy3DqF8tnTXuiaAJuML3ky+er10rcgNR/VqsVpcw+ThHmYcwiB1pbOxEbzJr7")
    let singleValidIntegrity = singleValid.hashes
    
    XCTAssertEqual(singleValidIntegrity.count, 1)
  }
  
  func testMultipleValidDocumentIntegritiesConversion() throws {
    let multipleValid = try DocumentIntegrity(
      "sha384-H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO " +
      "sha512-Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw=="
    )
    
    XCTAssertEqual(multipleValid.hashes.count, 2)
  }
  
  func testUnknownAlgorithmThrowsError() {
    XCTAssertThrowsError(
      try DocumentIntegrity(
        "sha484-Li9vy3DqF8tnTXuiaAJuML3ky+er10rcgNR/VqsVpcw+ThHmYcwiB1pbOxEbzJr7"
      )
    ) { error in
      XCTAssertTrue(error is SRIError)
      if case .invalidFormat = error as? SRIError {
        XCTAssert(true)
      } else {
        XCTFail("Expected invalidFormat error")
      }
    }
  }
  
  func testKnownAndUnknownAlgorithmThrowsError() {
    XCTAssertThrowsError(
      try DocumentIntegrity(
        "sha484-H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO " +
        "sha512-Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw=="
      )
    ) { error in
      XCTAssertTrue(error is SRIError)
    }
  }
  
  func testOptionsAreParsedCorrectly() throws {
    let multipleValidWithOptions = try DocumentIntegrity(
      "sha384-H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO?extraOptionsReserved " +
      "sha512-Q2bFTOhEALkN8hOms2FKTDLy7eugP2zFZ1T8LCvX42Fp3WoNr3bjZSAHeOsHrbV1Fu9/A0EzCinRE7Af1ofPrw=="
    )
    
    XCTAssertEqual(multipleValidWithOptions.hashes.count, 2)
    XCTAssertEqual(
      multipleValidWithOptions.hashes[0].encodedHash,
      "H8BRh8j48O9oYatfu5AZzq6A9RINhZO5H16dQZngK7T62em8MUt1FLm52t+eX6xO"
    )
    XCTAssertEqual(
      multipleValidWithOptions.hashes[0].options,
      "extraOptionsReserved"
    )
  }
}
