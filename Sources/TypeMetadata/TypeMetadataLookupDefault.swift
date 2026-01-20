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

/**
 A protocol for retrieving  type metadata for a given VCT.
 */
public protocol TypeMetadataLookup {
  
  /**
   Retrieves  type metadata using Vct.
   
   - Returns: An array of `SdJwtVcTypeMetadata`
   - Note: Get Vct Object
   - Throws: `TypeMetadataError` if resolution fails or a circular reference is detected.
   */
  
  func getTypeMetadata(
    vct: Vct
  ) async throws -> [SdJwtVcTypeMetadata]
}

public struct TypeMetadataLookupDefault: TypeMetadataLookup {
  
  let fetcher: TypeMetadataFetching
  
  public init(
    fetcher: TypeMetadataFetching
  ) {
    self.fetcher = fetcher
  }
  
  public func getTypeMetadata(vct: Vct) async throws -> [SdJwtVcTypeMetadata] {
    
    guard let vctURL = URL(string: vct.uri) else {
      throw TypeMetadataError.invalidTypeMetadataURL
    }
    
    let metadataArray = try await getTypeMetadata(
      from: vctURL,
      expectedIntegrityHash: vct.integrityHash,
      typeMetadataFetcher: fetcher,
      visitedUrls: [],
      typeMetadataArray: [])
    
    return metadataArray
  }
  
  
  /**
   Recursively retrieves and resolves type metadata documents starting from the given URL.

   - Parameters:
     - url: The URL to fetch the initial metadata from.
     - expectedIntegrityHash: An optional hash to verify the integrity of the fetched metadata.
     - typeMetadataFetcher: A fetcher used to retrieve the metadata content.
     - visitedUrls: A set of URLs already visited to detect and prevent circular references.
     - typeMetadataArray: The array accumulating the resolved metadata in order.

   - Returns: An array of resolved `SdJwtVcTypeMetadata`

   - Note: If the metadata includes an `extends` URL, the function will recursively resolve and append that metadata as well.
           The integrity check is optional and only applied if a hash is provided.
   - Throws: `TypeMetadataError.circularReference` if a circular reference is detected.
   */
  @discardableResult
  private func getTypeMetadata(
    from url: URL,
    expectedIntegrityHash: String?,
    typeMetadataFetcher: TypeMetadataFetching,
    visitedUrls: Set<URL>,
    typeMetadataArray: [SdJwtVcTypeMetadata]
  ) async throws -> [SdJwtVcTypeMetadata] {

    var currentUrls = visitedUrls
    var metadataArray = typeMetadataArray

    guard !currentUrls.contains(url) else {
      throw TypeMetadataError.circularReference
    }
    currentUrls.insert(url)

    let typeMetadata = try await typeMetadataFetcher.fetchTypeMetadata(from: url, expectedIntegrityHash: expectedIntegrityHash)
    metadataArray.append(typeMetadata)

    if let extendsURL = typeMetadata.extends, let extendsIntegrity = typeMetadata.extendsIntegrity {
      return try await getTypeMetadata(
        from: extendsURL,
        expectedIntegrityHash: extendsIntegrity,
        typeMetadataFetcher: typeMetadataFetcher,
        visitedUrls: currentUrls,
        typeMetadataArray: metadataArray
      )
    }
    return metadataArray
  }
}
