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

/// Configuration for decoy digest generation in SD-JWT credentials.
///
/// Decoy digests are used to hide whether optional claims are present or absent,
/// enhancing privacy by making it difficult to deduce the structure of disclosed information.
///
/// ## Security Considerations
/// - Use `.perObject` strategy for better privacy guarantees
/// - Ensure cryptographically secure random number generation
/// - Avoid predictable patterns in decoy counts
///
/// ## Example Usage
/// ```swift
/// // Recommended: Ensure at least 3 digests per object
/// let config = DecoyConfiguration.perObject(minimum: 3)
///
/// // With randomization: 3-7 digests per object
/// let config = DecoyConfiguration.perObject(minimum: 3, maximum: 7)
///
/// // Backward compatible global limit (deprecated)
/// let config = DecoyConfiguration.globalLimit(10)
/// ```
public struct DecoyConfiguration {

  /// Strategy for generating decoy digests
  public enum Strategy {
    /// No decoys will be generated (default)
    case none

    /// Global limit across entire credential (deprecated - less secure)
    ///
    /// This strategy maintains a global counter and stops generating decoys
    /// once the limit is reached. This can lead to privacy issues as early
    /// objects may consume all available decoys.
    ///
    /// - Parameter limit: Maximum total number of decoys across entire credential
    /// - Warning: This strategy is maintained for backward compatibility but is not recommended.
    ///            Use `.perObject` instead for better privacy protection.
    @available(*, deprecated, message: "Use .perObject for better privacy guarantees")
    case globalLimit(Int)

    /// Minimum digests per _sd array (recommended for privacy)
    ///
    /// Ensures each object's `_sd` array contains at least the specified minimum
    /// number of digests, filling with decoys if necessary. This prevents inference
    /// about which optional claims are present.
    ///
    /// - Parameters:
    ///   - minimum: Minimum number of digests in each _sd array (including real disclosures)
    ///   - maximum: Optional maximum number of additional random decoys per _sd array.
    ///              If specified, a cryptographically random number of extra decoys
    ///              (0 to maximum) will be added beyond the minimum.
    ///
    /// ## Example
    /// If an object has 2 disclosed claims and configuration is `.perObject(minimum: 5, maximum: 3)`:
    /// - Guaranteed: 2 real + 3 decoy = 5 total digests (minimum met)
    /// - Random: 0-3 additional decoys added
    /// - Final: 5-8 total digests in the _sd array
    case perObject(minimum: Int, maximum: Int?)
  }

  // MARK: - Properties

  /// The decoy generation strategy
  public let strategy: Strategy

  // MARK: - Initialization

  /// Creates a decoy configuration with the specified strategy
  ///
  /// - Parameter strategy: The decoy generation strategy to use
  public init(strategy: Strategy = .none) {
    self.strategy = strategy
  }

  // MARK: - Convenience Initializers

  /// No decoys will be generated
  public static var none: DecoyConfiguration {
    DecoyConfiguration(strategy: .none)
  }

  /// Global limit across entire credential (deprecated)
  ///
  /// - Parameter limit: Maximum total number of decoys
  /// - Warning: Use `.perObject` instead for better privacy protection
  @available(*, deprecated, message: "Use .perObject for better privacy guarantees")
  public static func globalLimit(_ limit: Int) -> DecoyConfiguration {
    DecoyConfiguration(strategy: .globalLimit(limit))
  }

  /// Minimum digests per object (recommended)
  ///
  /// - Parameters:
  ///   - minimum: Minimum number of digests in each _sd array
  ///   - maximum: Optional maximum additional random decoys per _sd array
  /// - Returns: A DecoyConfiguration with per-object minimum guarantees
  public static func perObject(minimum: Int, maximum: Int? = nil) -> DecoyConfiguration {
    DecoyConfiguration(strategy: .perObject(minimum: minimum, maximum: maximum))
  }
}
