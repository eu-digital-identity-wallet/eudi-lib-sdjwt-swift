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

final class SchemaValidatorTests: XCTestCase {
  
  func test_schemaValidator_whenValidateValidPayload_shouldNotThrow() async throws {
    
    // Given
    let payload = """
      {
        "vct": "https://mock.local/credentialType",
        "iss": "https://issuer.example.com",
        "nbf": 1685558400,
        "exp": 1717094400,
        "cnf": {
          "jwk": {
            "kty": "EC",
            "crv": "P-256",
            "x": "f83OJ3D2xF4tCewWQZ5JrQ...",
            "y": "x_FEzRu9AK1a9zxJgZ1-Ny..."
          }
        },
        "status": {
          "type": "active"
        },
        "given_name": "Alice",
        "family_name": "Smith",
        "email": "alice.smith@example.com",
        "phone_number": "+1234567890",
        "address": {
          "street_address": "123 Main Street",
          "locality": "Springfield",
          "region": "CA",
          "country": "USA"
        },
        "birthdate": "1990-01-01",
        "is_over_18": true,
        "is_over_21": true,
        "is_over_65": false
      }
  """
    
    let payloadData = payload.data(using: .utf8)!
    let payloadJSON = try! JSON(data: payloadData)
    let schemas = try await getSchemas()
    
    // When/Then
    XCTAssertNoThrow(try SchemaValidator().validate(payloadJSON, schemas))
  }
  
  
  func test_schemaValidator_whenValidateInvalidPayload_witMissingProperty_shouldThrow() async throws {
    
    // Given
    let payload = """
      {
        "vct": "https://mock.local/credentialType",
        "nbf": 1685558400,
        "exp": 1717094400,
        "cnf": {
          "jwk": {
            "kty": "EC",
            "crv": "P-256",
            "x": "f83OJ3D2xF4tCewWQZ5JrQ...",
            "y": "x_FEzRu9AK1a9zxJgZ1-Ny..."
          }
        },
        "status": {
          "type": "active"
        },
        "given_name": "Alice", 
        "family_name": "Smith",
        "email": "alice.smith@example.com",
        "phone_number": "+1234567890",
        "address": {
          "street_address": "123 Main Street",
          "locality": "Springfield",
          "region": "CA",
          "country": "USA"
        },
        "birthdate": "1990-01-01",
        "is_over_18": true,
        "is_over_21": true,
        "is_over_65": false
      }
  """
    
    let payloadData = payload.data(using: .utf8)!
    let payloadJSON = try! JSON(data: payloadData)
    let schemas = try await getSchemas()
    
    do {
      // When
      _ = try SchemaValidator().validate(payloadJSON, schemas)
      XCTFail("Expected to throw, but did not throw")
      
    } catch let error as TypeMetadataError {
      
      // Then
      XCTAssertEqual(error, .schemaValidationFailed(description: "Required property 'iss' is missing at #"))
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }
  
  func test_schemaValidator_whenValidateInvalidPayload_with_InvalidType_shouldThrow() async throws {
    
    // Given
    let payload = """
      {
        "vct": "https://mock.local/credentialType",
        "iss": "https://issuer.example.com",
        "nbf": 1685558400,
        "exp": 1717094400,
        "cnf": {
          "jwk": {
            "kty": "EC",
            "crv": "P-256",
            "x": "f83OJ3D2xF4tCewWQZ5JrQ...",
            "y": "x_FEzRu9AK1a9zxJgZ1-Ny..."
          }
        },
        "address": {
          "street_address": 2,
          "locality": "Springfield",
          "region": "CA",
          "country": "USA"
        },
        "birthdate": "1990-01-01",
      }
  """
    
    let payloadData = payload.data(using: .utf8)!
    let payloadJSON = try! JSON(data: payloadData)
    let schemas = try await getSchemas()
    
    do {
      // When
      _ = try SchemaValidator().validate(payloadJSON, schemas)
      XCTFail("Expected to throw, but did not throw")
      
    } catch let error as TypeMetadataError {
      
      // Then
      XCTAssertEqual(error, .schemaValidationFailed(description: "Validation failed for keyword 'properties' at #, Validation failed for keyword 'properties' at #/address, Expected type '[SwiftJSONSchema.JSONType.string]' but found 'integer' at #/address/street_address"))
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }

  
  private func getSchemas() async throws -> [JSON] {
    let fetcher = SchemaFetcher(
      session: NetworkingBundleMock(
        filenameResolver: { url in
        url.lastPathComponent
      })
    )
    
    let schemaLookup = TypeMetadataSchemaLookupDefault(
      schemaFetcher: fetcher
    )
    
    let metadata = try SdJwtVcTypeMetadata(
      vct: "testVct2",
      schemaSource: .byReference(
        url: URL(string: "https://mock.local/schema")!,
        integrity: nil
      )
    )
    
    let schemas = try await schemaLookup.getSchemas(metadataArray: [metadata])
    return schemas
  }
}
