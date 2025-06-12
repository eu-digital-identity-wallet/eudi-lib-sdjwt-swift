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

import SwiftyJSON

/**
 A protocol for retrieving JSON Schema definitions associated with type metadata.
 */
public protocol TypeMetadataSchemaLookup {
  
  /**
   Retrieves all schema definitions (by value or by reference) from the provided metadata.
   
   - Parameter metadataArray: An array of type metadata entries.
   - Returns: An array of JSON Schema definitions.
   - Throws: An error if schema fetching fails.
   */
  func getSchemas(metadataArray: [SdJwtVcTypeMetadata]) async throws -> [JSON]
}

struct TypeMetadataSchemaLookupDefault: TypeMetadataSchemaLookup {
  
  let schemaFetcher: SchemaFetching
  
  init(schemaFetcher: SchemaFetching) {
    self.schemaFetcher = schemaFetcher
  }
  
  func getSchemas(metadataArray: [SdJwtVcTypeMetadata]) async throws -> [JSON] {
    try await getAllSchemas(from: metadataArray, schemaFetcher: schemaFetcher)
  }
  
  
  private func getAllSchemas(
    from metadataArray: [SdJwtVcTypeMetadata],
    schemaFetcher: SchemaFetching
  ) async throws -> [JSON]  {
    
    var schemas:[JSON] = []
    
    for metadata in metadataArray {
      if let schemaSource = metadata.schemaSource {
        switch schemaSource {
        case .byValue(let schema):
          schemas.append(schema)
        case .byReference(let url, let integrity):
          if let fetchedSchema = try await schemaFetcher.fetchSchema(from: url, expectedIntegrityHash: integrity) {
            schemas.append(fetchedSchema)
          }
        }
      }
    }
    return schemas
  }
}
