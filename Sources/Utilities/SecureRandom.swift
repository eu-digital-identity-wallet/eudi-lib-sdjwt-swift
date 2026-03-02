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

/// Provides cryptographically secure random number generation
///
/// This utility uses `SecRandomCopyBytes` to generate unpredictable random numbers,
/// suitable for security-sensitive operations like decoy digest generation.
enum SecureRandom {

  /// Generates a cryptographically secure random integer in the specified range
  ///
  /// - Parameter range: The range of possible values (inclusive)
  /// - Returns: A random integer within the specified range
  /// - Note: Uses rejection sampling to ensure uniform distribution
  ///
  /// ## Example
  /// ```swift
  /// let randomCount = SecureRandom.number(in: 0...10)
  /// ```
  static func number(in range: ClosedRange<Int>) -> Int {
    let lowerBound = range.lowerBound
    let upperBound = range.upperBound

    guard lowerBound <= upperBound else {
      return lowerBound
    }

    // Special case: single value range
    if lowerBound == upperBound {
      return lowerBound
    }

    let rangeSize = UInt64(upperBound - lowerBound + 1)

    // Generate random bytes and convert to UInt64
    var randomValue: UInt64 = 0
    let byteCount = MemoryLayout<UInt64>.size
    let result = withUnsafeMutableBytes(of: &randomValue) { bufferPointer in
      SecRandomCopyBytes(
        kSecRandomDefault,
        byteCount,
        bufferPointer.baseAddress!
      )
    }

    // If random generation fails, fall back to deterministic value (should never happen)
    guard result == errSecSuccess else {
      return lowerBound
    }

    // Use modulo with rejection sampling to ensure uniform distribution
    // This prevents modulo bias for ranges that don't divide evenly
    let maxAcceptableValue = UInt64.max - (UInt64.max % rangeSize)

    // Rejection sampling: retry if value is in the biased range
    if randomValue >= maxAcceptableValue {
      // Recursively retry (very rare, typically happens < 0.01% of the time)
      return number(in: range)
    }

    return lowerBound + Int(randomValue % rangeSize)
  }
}
