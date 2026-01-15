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
import CryptoKit

// MARK: - Models

/// Represents a Subresource Integrity (SRI) value.
///
/// An SRI value consists of one or more cryptographic hashes that can be used
/// to verify that fetched resources have not been tampered with.
/// When multiple hashes are present, the validator selects the strongest algorithm
/// for validation (SHA-512 > SHA-384 > SHA-256).
///
public struct DocumentIntegrity {
  let value: String
  
  public init(_ value: String) throws {
    guard value.range(of: Self.sriPattern, options: .regularExpression) != nil else {
      throw SRIError.invalidFormat("not a valid sub-resource integrity value")
    }
    self.value = value
  }
  
  var hashes: [DocumentHash] {
    let hashesWithOptions = value
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespaces)
      .split(separator: " ")
      .map(String.init)
    
    return hashesWithOptions.compactMap { hashSpec in
      let (algorithmAndEncodedHash, options): (String, String?) = {
        if let questionMarkIndex = hashSpec.firstIndex(of: "?") {
          let algorithm = String(hashSpec[..<questionMarkIndex])
          let opts = String(hashSpec[hashSpec.index(after: questionMarkIndex)...])
          return (algorithm, opts)
        } else {
          return (hashSpec, nil)
        }
      }()
      
      let components = algorithmAndEncodedHash.split(separator: "-", maxSplits: 1).map(String.init)
      guard components.count == 2,
            let algorithm = IntegrityAlgorithm(rawValue: components[0]) else {
        return nil
      }
      
      let encodedHash = components[1]
      return DocumentHash(algorithm: algorithm, encodedHash: encodedHash, options: options)
    }
  }
  
  private static let sriPattern = """
        ^\\s*(sha(?:256|384|512)-[A-Za-z0-9+/]+={0,2}(?:\\?[\\x21-\\x7E]*)?)(?:\\s+(sha(?:256|384|512)-[A-Za-z0-9+/]+={0,2}(?:\\?[\\x21-\\x7E]*)?))*\\s*$
        """
}

/// Represents a single hash within a Subresource Integrity (SRI) value.
///
/// Each hash consists of an algorithm identifier, a base64-encoded hash value,
/// and optional parameters (e.g., "sha256-abc123==?option=value").
struct DocumentHash {
  let algorithm: IntegrityAlgorithm
  let encodedHash: String
  let options: String?
}

/// Hash algorithms supported for Subresource Integrity (SRI) validation.
///
/// These algorithms are used to compute cryptographic hashes of fetched resources.
/// When multiple hashes are present, the validator selects the strongest algorithm
/// based on the `strength` property.
///
/// **Algorithm Strength Ordering:** SHA-512 (strongest) > SHA-384 > SHA-256
public enum IntegrityAlgorithm: String {
  case sha256 = "sha256"
  case sha384 = "sha384"
  case sha512 = "sha512"
  
  var strength: Int {
    switch self {
    case .sha256: return 1
    case .sha384: return 2
    case .sha512: return 3
    }
  }
}

// MARK: - Validator

/// Validates content integrity using Subresource Integrity (SRI) standard.
///
/// This validator supports:
/// - **SHA-256, SHA-384, SHA-512** hash algorithms
/// - **Multiple hashes** with automatic strongest algorithm selection
/// - **Configurable algorithm restrictions** for security policies
///
public class SRIValidator: SRIValidatorProtocol {
  private let allowedAlgorithms: Set<IntegrityAlgorithm>
  
  public init(allowedAlgorithms: Set<IntegrityAlgorithm> = [.sha256, .sha384, .sha512]) throws {
    guard !allowedAlgorithms.isEmpty else {
      throw SRIError.noAlgorithmsAllowed
    }
    self.allowedAlgorithms = allowedAlgorithms
  }
  
  /// Validates content against expected integrity
  /// - Parameters:
  ///   - expectedIntegrity: The expected SRI value
  ///   - content: The data to validate
  /// - Returns: `true` if validation passes, `false` otherwise
  public func isValid(expectedIntegrity: DocumentIntegrity, content: Data) -> Bool {
    let expectedHashesByAlgorithm = Dictionary(grouping: expectedIntegrity.hashes) { $0.algorithm }
    
    let maybeStrongestAlgorithm = expectedHashesByAlgorithm.keys
      .filter { allowedAlgorithms.contains($0) }
      .max { $0.strength < $1.strength }
    
    guard let strongestAlgorithm = maybeStrongestAlgorithm else {
      return false
    }
    
    guard let strongestExpectedHashes = expectedHashesByAlgorithm[strongestAlgorithm] else {
      return false
    }
    
    let actualEncodedHash = computeHash(algorithm: strongestAlgorithm, data: content)
    
    return strongestExpectedHashes.contains { $0.encodedHash == actualEncodedHash }
  }
  
  // MARK: - Private
  
  private func computeHash(algorithm: IntegrityAlgorithm, data: Data) -> String {
    let digest: Data
    
    switch algorithm {
    case .sha256:
      let hash = SHA256.hash(data: data)
      digest = Data(hash)
    case .sha384:
      let hash = SHA384.hash(data: data)
      digest = Data(hash)
    case .sha512:
      let hash = SHA512.hash(data: data)
      digest = Data(hash)
    }
    
    return digest.base64EncodedString()
  }
}

// MARK: - Errors

/// Errors related to Subresource Integrity (SRI) validation.
enum SRIError: LocalizedError {
  case invalidFormat(String)
  case noAlgorithmsAllowed
  
  var errorDescription: String? {
    switch self {
    case .invalidFormat(let message):
      return message
    case .noAlgorithmsAllowed:
      return "At least one integrity algorithm must be provided"
    }
  }
}

