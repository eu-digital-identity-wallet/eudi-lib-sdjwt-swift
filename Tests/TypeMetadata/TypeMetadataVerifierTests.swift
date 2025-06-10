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
import XCTest
import JSONWebKey
import JSONWebSignature
import SwiftyJSON

@testable import eudi_lib_sdjwt_swift

final class TypeMetadataVerifierTests: XCTestCase {

  func testVerifier_validateWithValidData_NoThrowsError() async {
    
    //Given
    
    let session = NetworkingBundleMock(
      filenameResolver: { url in
      url.lastPathComponent
    })
    
    let metadataFetcher = TypeMetadataFetcher(session: session)
    let schemafetcher = SchemaFetcher(session: session)
    
    let vct = try! Vct(uri: "https://mock.local/type_meta_data_pid_light")
    
    let metadataLookup = TypeMetadataLookupDefault(
      vct: vct,
      fetcher: metadataFetcher)
    
    let schemaLookup = TypeMetadataSchemaLookupDefault(
      schemaFetcher: schemafetcher
    )
    
    let sut = TypeMetadataVerifier(
      metadataLookup: metadataLookup,
      schemaLookup: schemaLookup
    )
    
    
    let keyData = Data(
      base64Encoded: SDJWTConstants.anIssuerPrivateKey
    )!
    
    let issuerSignedSDJWT = try! await SDJWTIssuer.issue(
      issuersPrivateKey: extractECKey(
        from: keyData
      ),
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        x509CertificateChain: [
          SDJWTConstants.anIssuersPrivateKeySignedcertificate
        ]
      )
    ) {
      ConstantClaims.iss(domain: "https://www.example.com")
      ConstantClaims.iat(time: Date())
      ConstantClaims.sub(subject: "123456789")
      
      PlainClaim("vct", "https://mock.local/type_meta_data_pid_light")
      
      FlatDisclosedClaim("family_name", "Doe")
      FlatDisclosedClaim("given_name", "John")
      FlatDisclosedClaim("birthdate", "1990-01-01")
      
      RecursiveObject("place_of_birth") {
        FlatDisclosedClaim("locality", "Berlin")
        FlatDisclosedClaim("region", "Berlin")
        FlatDisclosedClaim("country", "DE")
      }
      
      RecursiveArrayClaim("nationalities") {
        SdElement.flat("DE")
        SdElement.flat("GR")
      }
      
      RecursiveObject("address") {
        FlatDisclosedClaim("house_number", "12")
        FlatDisclosedClaim("street_address", "Schulstr.")
        FlatDisclosedClaim("locality", "Berlin")
        FlatDisclosedClaim("region", "Berlin")
        FlatDisclosedClaim("postal_code", "10115")
        FlatDisclosedClaim("country", "DE")
        FlatDisclosedClaim("formatted", "Schulstr. 12, 10115 Berlin, Germany")
      }
      
      FlatDisclosedClaim("personal_administrative_number", "1234567890")
      FlatDisclosedClaim("picture", "testPicture")
      FlatDisclosedClaim("birth_family_name", "Doe")
      FlatDisclosedClaim("birth_given_name", "John")
      FlatDisclosedClaim("sex", 1)
      FlatDisclosedClaim("email", "john.doe@example.com")
      FlatDisclosedClaim("phone_number", "+491234567890")
      FlatDisclosedClaim("date_of_expiry", "2030-01-01")
      FlatDisclosedClaim("issuing_authority", "Authority XYZ")
      FlatDisclosedClaim("issuing_country", "DE")
      FlatDisclosedClaim("document_number", "ABC123456")
      FlatDisclosedClaim("issuing_jurisdiction", "DE")
      FlatDisclosedClaim("date_of_issuance", "2020-01-01")
      
      RecursiveObject("age_equal_or_over") {
        FlatDisclosedClaim("18", true)
      }
      
      FlatDisclosedClaim("age_in_years", 34)
      FlatDisclosedClaim("age_birth_year", "1990")
      FlatDisclosedClaim("trust_anchor", "https://trust.anchor.de")
    }
    
    do {
      // When
      _ = try await sut.verifyTypeMetadata(sdJwt: issuerSignedSDJWT)
      XCTAssertTrue(true, "Verification succeeded")
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }
}


