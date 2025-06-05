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

public protocol TypeMetadataLookup {
  var vct: Vct { get }
  func getTypeMetadata() async throws -> [SdJwtVcTypeMetadata]
}


struct TypeMetadataLookupDefault: TypeMetadataLookup {
  
  let vct: Vct
  let fetcher: TypeMetadataFetching
  
  public init(vct: Vct, fetcher: TypeMetadataFetching) {
    self.vct = vct
    self.fetcher = fetcher
  }
  
  func getTypeMetadata() async throws -> [SdJwtVcTypeMetadata] {
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
