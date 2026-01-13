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



public protocol TypeMetadataFetching {
  var session: Networking { get }
  func fetchTypeMetadata(
    from url: URL,
    expectedIntegrityHash: String?
  ) async throws -> SdJwtVcTypeMetadata
}

public protocol SRIValidatorProtocol {
  func isValid(expectedIntegrity: DocumentIntegrity, content: Data) -> Bool
}


public class TypeMetadataFetcher: TypeMetadataFetching {
  
  public let session: Networking
  let integrityValidator: SRIValidatorProtocol?
  
  public init(
    session: Networking,
    integrityValidator: SRIValidatorProtocol? = nil) {
      self.session = session
      self.integrityValidator = integrityValidator
    }
  
  public func fetchTypeMetadata(
    from url: URL,
    expectedIntegrityHash: String? = nil
  ) async throws -> SdJwtVcTypeMetadata {
    
//    guard url.scheme == "https" else {
//      throw TypeMetadataError.invalidTypeMetadataURL
//    }
    
    let metadata: SdJwtVcTypeMetadata = try await session.fetch(
      from: url,
      validator: integrityValidator,
      expectedIntegrity: expectedIntegrityHash
    )
    
    return metadata
  }
}
