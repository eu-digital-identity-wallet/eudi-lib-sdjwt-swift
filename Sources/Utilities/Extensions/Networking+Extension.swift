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

extension Networking {
  func fetch<T: Decodable>(from url: URL) async throws -> T {
    let (data, _) = try await self.data(from: url)
    return try JSONDecoder().decode(T.self, from: data)
  }
}


public extension Networking {
    /// Fetches and decodes JSON data with optional SRI validation
    /// - Parameters:
    ///   - url: The URL to fetch from
    ///   - validator: Optional SRI validator for integrity checking
    ///   - expectedIntegrity: Expected integrity hash (required if validator is provided)
    /// - Returns: Decoded object of type T
    func fetch<T: Decodable>(
        from url: URL,
        validator: SRIValidatorProtocol? = nil,
        expectedIntegrity: String? = nil
    ) async throws -> T {
        let (data, _) = try await self.data(from: url)
        
        // Validate integrity if validator and expected hash are provided
        if let validator = validator, let expectedIntegrity = expectedIntegrity {
            let documentIntegrity = try DocumentIntegrity(expectedIntegrity)
            guard validator.isValid(expectedIntegrity: documentIntegrity, content: data) else {
                throw TypeMetadataError.integrityValidationFailed
            }
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Fetches raw data with optional SRI validation
    /// - Parameters:
    ///   - url: The URL to fetch from
    ///   - validator: Optional SRI validator for integrity checking
    ///   - expectedIntegrity: Expected integrity hash (required if validator is provided)
    /// - Returns: Raw data
    func fetchData(
        from url: URL,
        validator: SRIValidatorProtocol? = nil,
        expectedIntegrity: String? = nil
    ) async throws -> Data {
        let (data, _) = try await self.data(from: url)
        
        // Validate integrity if validator and expected hash are provided
        if let validator = validator, let expectedIntegrity = expectedIntegrity {
            let documentIntegrity = try DocumentIntegrity(expectedIntegrity)
            guard validator.isValid(expectedIntegrity: documentIntegrity, content: data) else {
                throw TypeMetadataError.integrityValidationFailed
            }
        }
        
        return data
    }
}
