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


final class TypeMetadataLookupTests: XCTestCase {
  
  let networkingBundleMock = NetworkingBundleMock(
    filenameResolver: { url in
    url.lastPathComponent
  })
  
  func test_getTypeMetadata_withBaseUri_returnsSingleEntryWithExpectedFields() async throws {
    
    // Given
    let vct = try Vct(uri: "https://mock.local/base_type_metadata")
    let fetcher = TypeMetadataFetcher(session: networkingBundleMock)
    let sut = TypeMetadataLookupDefault(vct: vct, fetcher: fetcher)
    
    // When
    let metadataArray = try await sut.getTypeMetadata()
    
    // Then
    XCTAssertEqual(metadataArray.count, 1)
    guard let metadata = metadataArray.first else {
      XCTFail("No metadata found")
      return
    }
    
    XCTAssertEqual(metadata.vct, "https://mock.local/base_type_metadata")
    XCTAssertEqual(metadata.name, "Betelgeuse Education Credential - Preliminary Version")
    XCTAssertEqual(metadata.description, "This is our development version of the education credential. Don't panic.")
    
    XCTAssertEqual(metadata.display?.count, 2)
    XCTAssertEqual(metadata.display?.first?.lang, "en-US")
    XCTAssertEqual(metadata.display?.first?.name, "Betelgeuse Education Credential")
    XCTAssertEqual(metadata.display?.first?.description, "An education credential for all carbon-based life forms on Betelgeusians",
                   "rendering")
    XCTAssertEqual(metadata.display?.first?.rendering?.simple?.logo?.uri, URL(string:"https://betelgeuse.example.com/public/education-logo.png"))
    XCTAssertEqual(metadata.display?.first?.rendering?.simple?.logo?.uriIntegrity, "sha256-LmXfh-9cLlJNXN-TsMk-PmKjZ5t0WRL5ca_xGgX3c1V")
    XCTAssertEqual(metadata.display?.first?.rendering?.simple?.logo?.altText, "Betelgeuse Ministry of Education logo")
    XCTAssertEqual(metadata.display?.first?.rendering?.simple?.backgroundColor, "#12107c")
    XCTAssertEqual(metadata.display?.first?.rendering?.simple?.textColor, "#FFFFFF")
    XCTAssertEqual(metadata.display?.first?.rendering?.svgTemplates?.first?.uri, URL(string:"https://betelgeuse.example.com/public/credential-english.svg"))
    XCTAssertEqual(metadata.display?.first?.rendering?.svgTemplates?.first?.uriIntegrity, "sha256-8cLlJNXN-TsMk-PmKjZ5t0WRL5ca_xGgX3c1VLmXfh-9c")
    XCTAssertEqual(metadata.display?.first?.rendering?.svgTemplates?.first?.properties?.orientation, "landscape")
    XCTAssertEqual(metadata.display?.first?.rendering?.svgTemplates?.first?.properties?.colorScheme, "light")
    XCTAssertEqual(metadata.display?.first?.rendering?.svgTemplates?.first?.properties?.contrast, "high")
    
    XCTAssertEqual(metadata.claims?.count, 4)
    XCTAssertEqual(metadata.claims?.first?.path.value.count, 1)
    XCTAssertEqual(metadata.claims?.first?.path.value.first, .claim(name: "name"))
    XCTAssertEqual(metadata.claims?.first?.display?.first?.lang, "de-DE")
    XCTAssertEqual(metadata.claims?.first?.display?.first?.label, "Vor- und Nachname")
    XCTAssertEqual(metadata.claims?.first?.display?.first?.description, "Der Name des Studenten")
    
    
    XCTAssertEqual(metadata.claims?[2].path.value.count, 2)
    XCTAssertEqual(metadata.claims?[3].path.value.count, 2)
  }
  
  func test_getTypeMetadata_returnsSingleEntryWithExpectedFields() async throws {
    
    let typeMetadataString = """
    {
      "vct": "https://mock.local/base_type_metadata",
      "name": "Betelgeuse Education Credential - Preliminary Version",
      "description": "This is our development version of the education credential. Don't panic."
    }
    """
    
    guard let typeMetadataData = typeMetadataString.data(using: .utf8) , let typeMetadataJSON = try? JSON(data: typeMetadataData) else {
      XCTFail("Failed to convert String to Data")
      return
    }
    
    // Given
    let vct = try Vct(uri: "https://mock.local/type_metadata_with_extend")
    let fetcher = TypeMetadataFetcher(session: NetworkingJSONMock(json: typeMetadataJSON))
    let sut = TypeMetadataLookupDefault(vct: vct, fetcher: fetcher)
    
    // When
    let metadataArray = try await sut.getTypeMetadata()
    
    XCTAssertEqual(metadataArray.count, 1)
    guard let metadata = metadataArray.first else {
      XCTFail("No metadata found")
      return
    }
  }
  
  func test_getTypeMetadata_withSingleExtend_returnsTwoEntries() async throws {
    
    // Given
    let vct = try Vct(uri: "https://mock.local/type_metadata_with_extend")
    let fetcher = TypeMetadataFetcher(session: networkingBundleMock)
    let sut = TypeMetadataLookupDefault(vct: vct, fetcher: fetcher)
    
    // When
    let metadataArray = try await sut.getTypeMetadata()
    
    // Then
    XCTAssertEqual(metadataArray.count, 2)
  }
  
  func test_getTypeMetadata_withDoubleExtend_returnsThreeEntries() async throws {
    
    // Given
    let vct = try Vct(uri: "https://mock.local/type_metadata_double_extend")
    let fetcher = TypeMetadataFetcher(session: networkingBundleMock)
    let sut = TypeMetadataLookupDefault(vct: vct, fetcher: fetcher)
    
    // When
    let metadataArray = try await sut.getTypeMetadata()
    
    // Then
    XCTAssertEqual(metadataArray.count, 3)
  }
  
  func test_getTypeMetadata_withCircularReference_throwsCircularReferenceError() async throws {
    let child: JSON = [
      "vct": "https://mock.local/type_metadata_with_extend",
      "name": "Betelgeuse Education Credential - Preliminary Version",
      "description": "This is our development version of the education credential. Don't panic.",
      "extends": "https://mock.local/type_metadata_with_extend", // same as vct
      "extends#integrity": "sha256-9cLlJNXN-TsMk-PmKjZ5t0WRL5ca_xGgX3c1VLmXfh-WRL5"
    ]
    
    // Given
    let vct = try Vct(uri: "https://mock.local/type_metadata_with_extend")
    let fetcher = TypeMetadataFetcher(session: NetworkingJSONMock(json: child))
    let sut = TypeMetadataLookupDefault(vct: vct, fetcher: fetcher)
    
    do {
      // When
      _ = try await sut.getTypeMetadata()
      XCTFail("Expected to throw, but did not throw")
      
    } catch let error as TypeMetadataError {
      
      // Then
      XCTAssertEqual(error, .circularReference)
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }
  
  
  func test_getTypeMetadata_withMissingIntegrityInExtend_ignoresExtendAndReturnsSingleEntry() async throws {
    
    let child: JSON = [
      "vct": "https://mock.local/type_metadata_with_extend",
      "name": "Betelgeuse Education Credential - Preliminary Version",
      "description": "This is our development version of the education credential. Don't panic.",
      "extends": "https://mock.local/base_type_metadata",
    ]
    
    // Given
    let vct = try Vct(uri: "https://mock.local/type_metadata_with_extend")
    let fetcher = TypeMetadataFetcher(session: NetworkingJSONMock(json: child))
    let sut = TypeMetadataLookupDefault(vct: vct, fetcher: fetcher)
    
    // When
    let metadataArray = try await sut.getTypeMetadata()
    
    // Then
    XCTAssertEqual(metadataArray.count, 1)
  }
}
