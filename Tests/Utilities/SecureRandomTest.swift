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

/// Tests for cryptographically secure random number generation
final class SecureRandomTest: XCTestCase {

  /// Test that generated numbers are within the specified range
  func testSecureRandom_NumberInRange() {
    let range = 0...10
    for _ in 0..<100 {
      let randomNumber = SecureRandom.number(in: range)
      XCTAssertGreaterThanOrEqual(randomNumber, range.lowerBound, "Number should be >= lower bound")
      XCTAssertLessThanOrEqual(randomNumber, range.upperBound, "Number should be <= upper bound")
    }
  }

  /// Test that distribution is reasonably uniform (statistical test)
  func testSecureRandom_ReasonablyUniformDistribution() {
    let range = 0...9
    var counts = [Int: Int]()

    // Generate 10,000 samples
    for _ in 0..<10000 {
      let number = SecureRandom.number(in: range)
      counts[number, default: 0] += 1
    }

    // Each number should appear roughly 1000 times (10,000 / 10)
    // Allow reasonable variance (e.g., 700-1300 is acceptable for uniform distribution)
    for i in 0...9 {
      let count = counts[i] ?? 0
      XCTAssertGreaterThan(count, 700, "Number \(i) should appear at least 700 times (got \(count))")
      XCTAssertLessThan(count, 1300, "Number \(i) should appear at most 1300 times (got \(count))")
    }
  }

  /// Test single value range
  func testSecureRandom_SingleValueRange() {
    let range = 5...5
    for _ in 0..<10 {
      let number = SecureRandom.number(in: range)
      XCTAssertEqual(number, 5, "Single value range should always return that value")
    }
  }

  /// Test that different calls produce different results (non-deterministic)
  func testSecureRandom_NonDeterministic() {
    let range = 0...1000
    var results = Set<Int>()

    for _ in 0..<50 {
      let number = SecureRandom.number(in: range)
      results.insert(number)
    }

    // With 50 samples from 0-1000, we should get multiple unique values
    XCTAssertGreaterThan(results.count, 10, "Should produce varied results (got \(results.count) unique values)")
  }

  /// Test large range
  func testSecureRandom_LargeRange() {
    let range = 0...1_000_000
    for _ in 0..<100 {
      let number = SecureRandom.number(in: range)
      XCTAssertGreaterThanOrEqual(number, range.lowerBound)
      XCTAssertLessThanOrEqual(number, range.upperBound)
    }
  }

  /// Test negative ranges
  func testSecureRandom_NegativeRange() {
    let range = -10...10
    for _ in 0..<100 {
      let number = SecureRandom.number(in: range)
      XCTAssertGreaterThanOrEqual(number, -10)
      XCTAssertLessThanOrEqual(number, 10)
    }
  }

  /// Test range with only negative numbers
  func testSecureRandom_OnlyNegativeRange() {
    let range = -100...(-50)
    for _ in 0..<100 {
      let number = SecureRandom.number(in: range)
      XCTAssertGreaterThanOrEqual(number, -100)
      XCTAssertLessThanOrEqual(number, -50)
    }
  }
}
