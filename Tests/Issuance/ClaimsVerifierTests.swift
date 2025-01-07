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

final class ClaimsVerifierTests: XCTestCase {
  
  // MARK: - IAT / Success
  
  func testPassesIatCheck_WhenIatIsNotPresent() {
    let claimsVerifier = ClaimsVerifier(iat: nil)
    
    XCTAssertTrue(try claimsVerifier.verify())
  }
  
  func testPassesIatCheck_WhenIatValidWindowIsNotPresent() {
    let iat = Int(Date().timeIntervalSince1970)
    let claimsVerifier = ClaimsVerifier(iat: iat)
    
    XCTAssertTrue(try claimsVerifier.verify())
  }
  
  func testPassesIatCheck_WhenIatIsInsideValidWindow() {
    let iat = Int(Date().timeIntervalSince1970) + 5
    let iatValidWindow = TimeRange(startTime: Date(), endTime: Date().advanced(by: 10))
    let claimsVerifier = ClaimsVerifier(iat: iat, iatValidWindow: iatValidWindow)
    
    XCTAssertTrue(try claimsVerifier.verify())
  }
  
  // MARK: - IAT / Failure
  
  func testFailsIatCheck_WhenIatIsBeforeValidWindow() {
    let iat = Int(Date().timeIntervalSince1970) - 5
    let iatValidWindow = TimeRange(startTime: Date(), endTime: Date().advanced(by: 10))
    let claimsVerifier = ClaimsVerifier(iat: iat, iatValidWindow: iatValidWindow)
    
    XCTAssertThrowsError(try claimsVerifier.verify()) { error in
      guard case SDJWTVerifierError.invalidJwt = error else {
        return XCTFail("wrong type of error \(error.localizedDescription)")
      }
    }
  }
  
  func testFailsIatCheck_WhenIatIsPastValidWindow() {
    let iat = Int(Date().timeIntervalSince1970) + 15
    let iatValidWindow = TimeRange(startTime: Date(), endTime: Date().advanced(by: 10))
    let claimsVerifier = ClaimsVerifier(iat: iat, iatValidWindow: iatValidWindow)
    
    XCTAssertThrowsError(try claimsVerifier.verify()) { error in
      guard case SDJWTVerifierError.invalidJwt = error else {
        return XCTFail("wrong type of error \(error.localizedDescription)")
      }
    }
  }
  
  // MARK: - NBF / Success
  
  func testPassesNbfCheck_WhenNbfIsNotPresent() {
    let claimsVerifier = ClaimsVerifier(nbf: nil)
    
    XCTAssertTrue(try claimsVerifier.verify())
  }
  
  func testPassesNbfCheck_WhenNbfIsInThePast() {
    let nbf = Int(Date().timeIntervalSince1970) - 5
    let claimsVerifier = ClaimsVerifier(nbf: nbf)
    
    XCTAssertTrue(try claimsVerifier.verify())
  }
  
  // MARK: - NBF / Failure
  
  func testFailsNbfCheck_WhenNbfIsInTheFuture() {
    let nbf = Int(Date().timeIntervalSince1970) + 5
    let claimsVerifier = ClaimsVerifier(nbf: nbf)
    
    XCTAssertThrowsError(try claimsVerifier.verify()) { error in
      guard case SDJWTVerifierError.notValidYetJwt = error else {
        return XCTFail("wrong type of error \(error.localizedDescription)")
      }
    }
  }
  
  // MARK: - EXP / Success
  
  func testPassesNbfCheck_WhenExpIsNotPresent() {
    let claimsVerifier = ClaimsVerifier(exp: nil)
    
    XCTAssertTrue(try claimsVerifier.verify())
  }
  
  func testPassesNbfCheck_WhenExpIsInTheFuture() {
    let exp = Int(Date().timeIntervalSince1970) + 5
    let claimsVerifier = ClaimsVerifier(exp: exp)
    
    XCTAssertTrue(try claimsVerifier.verify())
  }
  
  // MARK: - EXP / Failure
  
  func testFailsNbfCheck_WhenExpIsInThePast() {
    let exp = Int(Date().timeIntervalSince1970) - 5
    let claimsVerifier = ClaimsVerifier(exp: exp)
    
    XCTAssertThrowsError(try claimsVerifier.verify()) { error in
      guard case SDJWTVerifierError.expiredJwt = error else {
        return XCTFail("wrong type of error \(error.localizedDescription)")
      }
    }
  }
  
  // MARK: - AUD / Success
  
  func testPassesAudCheck_WhenAudClaimIsNotPresent() {
    let claimsVerifier = ClaimsVerifier(audClaim: nil, expectedAud: "AUD1")
    
    XCTAssertTrue(try claimsVerifier.verify())
  }
  
  func testPassesAudCheck_WhenExpectedAudIsNotPresent() {
    let claimsVerifier = ClaimsVerifier(audClaim: "AUD1", expectedAud: nil)
    
    XCTAssertTrue(try claimsVerifier.verify())
  }
  
  func testPassesAudCheck_WhenAudClaimIsArray() {
    let expectedAud = "AUD1"
    let audClaim = """
        ["SOME_AUD", "SOME_OTHER_AUD", "\(expectedAud)"]
        """
    let claimsVerifier = ClaimsVerifier(audClaim: audClaim, expectedAud: expectedAud)
    
    XCTAssertTrue(try claimsVerifier.verify())
  }
  
  func testPassesAudCheck_WhenAudClaimClaimIsString() {
    let expectedAud = "AUD1"
    let audClaim = expectedAud
    let claimsVerifier = ClaimsVerifier(audClaim: audClaim, expectedAud: expectedAud)
    
    XCTAssertTrue(try claimsVerifier.verify())
  }
  
  // MARK: - AUD / Failure
  
  func testFailsAudCheck_WhenAudClaimIsArray() {
    let expectedAud = "AUD1"
    let audClaim = """
        ["SOME_AUD", "SOME_OTHER_AUD"]
        """
    let claimsVerifier = ClaimsVerifier(audClaim: audClaim, expectedAud: expectedAud)
    
    XCTAssertThrowsError(try claimsVerifier.verify()) { error in
      guard case SDJWTVerifierError.keyBindingFailed = error else {
        return XCTFail("wrong type of error \(error.localizedDescription)")
      }
    }
  }
  
  func testFailsAudCheck_WhenAudClaimIsString() {
    let expectedAud = "AUD1"
    let audClaim = "SOME_AUD2"
    let claimsVerifier = ClaimsVerifier(audClaim: audClaim, expectedAud: expectedAud)
    
    XCTAssertThrowsError(try claimsVerifier.verify()) { error in
      guard case SDJWTVerifierError.keyBindingFailed = error else {
        return XCTFail("wrong type of error \(error.localizedDescription)")
      }
    }
  }
}
