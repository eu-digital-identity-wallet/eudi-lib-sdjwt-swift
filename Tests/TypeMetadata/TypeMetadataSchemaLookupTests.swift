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
import XCTest

@testable import eudi_lib_sdjwt_swift

final class TypeMetadataSchemaLookupTests: XCTestCase {
  
  let networkingBundleMock = NetworkingBundleMock(
    filenameResolver: { url in
    url.lastPathComponent
  })
  
  func test_getSchemas_withTwoMedata_withSchemaByValue_returnSchemaArray_withTwoEntries() async throws {
    
    let fetcher = SchemaFetcher(
      session: networkingBundleMock
    )
    
    let schemaLookup = TypeMetadataSchemaLookupDefault(
      schemaFetcher: fetcher
    )
    
    let schemaJson1: JSON = [
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "type": "object",
      "properties": [
        "vct":  ["type": "string"],
        "iss": ["type": "string"],
        "birthdate": ["type": "string"]
      ]
    ]
    
    let schemaJson2: JSON = [
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "type": "object",
      "properties": [
        "familyName":  ["type": "string"],
        "givenName": ["type": "string"],
        "email": ["type": "string"]
      ]
    ]
    
    let metadata = try SdJwtVcTypeMetadata(
      vct: "testVct1",
      schemaSource: .byValue(schemaJson1)
    )
    
    let metadata2 = try SdJwtVcTypeMetadata(
      vct: "testVct2",
      schemaSource: .byValue(schemaJson2)
    )
    
    let schemasArray = try await schemaLookup.getSchemas(metadataArray: [metadata, metadata2])
    XCTAssertEqual(schemasArray.count, 2)
  }
  
  func test_getSchemas_withTwoMedata_withSchemaByValueAndByReference_returnSchemaArray_withTwoEntries() async throws {
    
    let fetcher = SchemaFetcher(
      session: networkingBundleMock
    )
    
    let schemaLookup = TypeMetadataSchemaLookupDefault(
      schemaFetcher: fetcher
    )
    
    let schemaJson1: JSON = [
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "type": "object",
      "properties": [
        "vct":  ["type": "string"],
        "iss": ["type": "string"],
        "birthdate": ["type": "string"]
      ]
    ]

    let metadata = try SdJwtVcTypeMetadata(
      vct: "testVct1",
      schemaSource: .byValue(schemaJson1)
    )
    
    let metadata2 = try SdJwtVcTypeMetadata(
      vct: "testVct2",
      schemaSource: .byReference(
        url: URL(string: "https://mock.local/schema")!,
        integrity: nil
      )
    )
    
    let schemasArray = try await schemaLookup.getSchemas(metadataArray: [metadata, metadata2])
    XCTAssertEqual(schemasArray.count, 2)
  }
}
