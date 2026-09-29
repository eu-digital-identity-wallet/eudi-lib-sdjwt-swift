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

/// Regression tests for DefaultSaltProvider CSPRNG failure handling.
final class SaltProviderTest: XCTestCase {

  func testGenerateRandomSalt_DefaultLength_ReturnsSixteenBytes() throws {
    let provider = DefaultSaltProvider()
    let salt = try provider.generateRandomSalt()
    XCTAssertEqual(salt.count, 16)
  }

  func testGenerateRandomSalt_CustomLength_ReturnsRequestedByteCount() throws {
    let provider = DefaultSaltProvider()
    let salt = try provider.generateRandomSalt(length: 32)
    XCTAssertEqual(salt.count, 32)
  }

  func testGenerateRandomSalt_SubsequentCalls_ProduceDifferentValues() throws {
    let provider = DefaultSaltProvider()
    let a = try provider.generateRandomSalt()
    let b = try provider.generateRandomSalt()
    // Cryptographic salt: consecutive draws must differ.
    XCTAssertNotEqual(a, b)
  }

  func testSaltString_ReturnsBase64URLEncodedSalt() throws {
    let provider = DefaultSaltProvider()
    let string = try provider.saltString()
    // 16 bytes → 22 base64url chars (no padding).
    XCTAssertEqual(string.count, 22)
    XCTAssertFalse(string.contains("="))
    XCTAssertFalse(string.contains("+"))
    XCTAssertFalse(string.contains("/"))
  }
}
