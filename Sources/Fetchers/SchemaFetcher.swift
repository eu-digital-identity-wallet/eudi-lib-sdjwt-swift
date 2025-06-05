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
import SwiftyJSON

public protocol SchemaFetching {
  func fetchSchema(
    from url: URL,
    expectedIntegrityHash: String?
  ) async throws -> JSON?
}

public protocol SchemaIntegrityChecking {
  func verify(schema: JSON?, expectedHash: String?) throws
}

public struct SchemaIntegrityChecker: SchemaIntegrityChecking {
  public init() {}

  public func verify(schema: JSON?, expectedHash: String?) throws {
    if let schema, let expectedHash {
      // compute and validate schema hash
      // throw TypeMetadataError.schemaIntegrityCheckFailed if invalid
    }
  }
}


public class SchemaFetcher: SchemaFetching {
  
  public let session: Networking
  let integrityChecker: SchemaIntegrityChecking?
  
  public init(session: Networking, integrityChecker: SchemaIntegrityChecking? = nil) {
    self.session = session
    self.integrityChecker = integrityChecker
  }
  
  public func fetchSchema(
    from url: URL,
    expectedIntegrityHash: String? = nil) async throws -> JSON? {
      
      guard url.scheme == "https" else {
        throw TypeMetadataError.invalidSchemaURL
      }
      
      let schema = try await session.fetch(from: url) as JSON?
      if let integrityChecker {
        try integrityChecker.verify(schema: schema, expectedHash: expectedIntegrityHash)
      }
      return schema
    }
}


