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
import JSONWebKey
import JSONWebSignature
import JSONWebToken
import SwiftyJSON
import XCTest
import CryptoKit

@testable import eudi_lib_sdjwt_swift


final class VcVerifierTest: XCTestCase {
  
  private let x509Verifier = SDJWTVCVerifier(verificationMethod: .x509(
    trust: X509SDJWTVCCertificateChainVerifier(rootCertificates: try! SDJWTConstants.loadRootCertificates())
  ))
  
  private let metadataVerifier = SDJWTVCVerifier(
    verificationMethod: .metadata(fetcher: SdJwtVcIssuerMetaDataFetcher(
      session: NetworkingBundleMock(
        path: "issuer_meta_data",
        extension: "json"
      ))))
  
  override func setUp() async throws {
  }
  
  override func tearDown() async throws {
  }
  
  func testVerifyIssuance_WithValidSDJWT_Withx509Header_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    
    // When
    let result = try await x509Verifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWT_Withx509Header_WithoutDisclosures_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    
    // When
    let result = try await x509Verifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWT_Withx509Header_PrimaryIssuer_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    
    // When
    let result = try await x509Verifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWT_Withx509Header_SecondaryIssuer_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    
    // When
    let result = try await x509Verifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWT_Withx509Header_AndConfiguration_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    
    // When
    let result = try await x509Verifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
    
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWT_WithIssuerMetaData_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.issuer_metadata_sd_jwt.clean()
    
    // When
    let result = try await metadataVerifier.verifyIssuance(
      unverifiedSdJwt: sdJwtString
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWT_WithIssuerMetaData_AndConfiguration_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.issuer_metadata_sd_jwt.clean()
    
    // When
    let result = try await metadataVerifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWTFlattendedJSON_Withx509Header_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    let parser = CompactParser()
    let sdJwt = try! parser.getSignedSdJwt(serialisedString: sdJwtString)
    
    // When
    let json = try sdJwt.asJwsJsonObject(
      option: .flattened,
      kbJwt: sdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    let result = try await x509Verifier.verifyIssuance(unverifiedSdJwt: json)
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWTGeneralJSON_Withx509Header_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    let parser = CompactParser()
    let sdJwt = try! parser.getSignedSdJwt(serialisedString: sdJwtString)
    
    // When
    let json = try sdJwt.asJwsJsonObject(
      option: .general,
      kbJwt: sdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    let result = try await x509Verifier.verifyIssuance(unverifiedSdJwt: json)
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithValidSDJWTFlattended_WithIssuerMetaData_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.issuer_metadata_sd_jwt.clean()
    let parser = CompactParser()
    let sdJwt = try! parser.getSignedSdJwt(serialisedString: sdJwtString)
    
    // When
    let json = try sdJwt.asJwsJsonObject(
      option: .general,
      kbJwt: sdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    let result = try await metadataVerifier.verifyIssuance(unverifiedSdJwt: json)
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyPresentation_WithValidSDJWTPresentation_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.presentation_sd_jwt.clean()
    
    // When
    let result = try await metadataVerifier.verifyPresentation(
      unverifiedSdJwt: sdJwtString,
      claimsVerifier: ClaimsVerifier(),
      keyBindingVerifier: KeyBindingVerifier()
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyPresentation_WithValidSDJWT_AsFlattendedJSON_Presentation_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.presentation_sd_jwt.clean()
    let parser = CompactParser()
    let sdJwt = try! parser.getSignedSdJwt(serialisedString: sdJwtString)
    
    // When
    let json = try sdJwt.asJwsJsonObject(
      option: .general,
      kbJwt: sdJwt.kbJwt?.compactSerialization,
      getParts: parser.extractJWTParts
    )
    
    let result = try await metadataVerifier.verifyPresentation(
      unverifiedSdJwt: json,
      claimsVerifier: ClaimsVerifier(),
      keyBindingVerifier: KeyBindingVerifier()
    )
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyPresentation_WithDSLBuiltValidSDJWT_WithIssuerMetaData_Presentation_ShouldSucceed() async throws {
    
    let issuersKey = issuersKeyPair.public
    let issuerJwk = try issuersKey.jwk
    
    let holdersKey = holdersKeyPair.public
    let holdersJwk = try holdersKey.jwk
    
    let jsonObject: JSON = [
      "issuer": "https://example.com/issuer",
      "jwks": [
        "keys": [
          [
            "crv": "P-256",
            "kid": "Ao50Swzv_uWu805LcuaTTysu_6GwoqnvJh9rnc44U48",
            "kty": "EC",
            "x": issuerJwk.x?.base64URLEncode(),
            "y": issuerJwk.y?.base64URLEncode()
          ]
        ]
      ]
    ]
    
    let issuerSignedSDJWT = try await SDJWTIssuer.issue(
      issuersPrivateKey: issuersKeyPair.private,
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        keyID: "Ao50Swzv_uWu805LcuaTTysu_6GwoqnvJh9rnc44U48"
      )
    ) {
      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date() + 3600)
      ConstantClaims.iss(domain: "https://example.com/issuer")
      FlatDisclosedClaim("sub", "6c5c0a49-b589-431d-bae7-219122a9ec2c")
      FlatDisclosedClaim("given_name", "太郎")
      FlatDisclosedClaim("family_name", "山田")
      FlatDisclosedClaim("email", "\"unusual email address\"@example.jp")
      FlatDisclosedClaim("phone_number", "+81-80-1234-5678")
      ObjectClaim("address") {
        FlatDisclosedClaim("street_address", "東京都港区芝公園４丁目２−８")
        FlatDisclosedClaim("locality", "東京都")
        FlatDisclosedClaim("region", "港区")
        FlatDisclosedClaim("country", "JP")
      }
      FlatDisclosedClaim("birthdate", "1940-01-01")
      ObjectClaim("cnf") {
        ObjectClaim("jwk") {
          PlainClaim("kid", "Ao50Swzv_uWu805LcuaTTysu_6GwoqnvJh9rnc44U48")
          PlainClaim("kty", "EC")
          PlainClaim("y", holdersJwk.y!.base64URLEncode())
          PlainClaim("x", holdersJwk.x!.base64URLEncode())
          PlainClaim("crv", "P-256")
        }
      }
    }
    
    let sdHash = DigestCreator()
      .hashAndBase64Encode(
        input: CompactSerialiser(
          signedSDJWT: issuerSignedSDJWT
        ).serialised
      )!
    
    let nonce = UUID().uuidString
    let aud = "aud"
    let timestamp = Int(Date().timeIntervalSince1970.rounded())
    let holder = try await SDJWTIssuer
      .presentation(
        holdersPrivateKey: holdersKeyPair.private,
        signedSDJWT: issuerSignedSDJWT,
        disclosuresToPresent: issuerSignedSDJWT.disclosures,
        keyBindingJWT: KBJWT(
          header: DefaultJWSHeaderImpl(algorithm: .ES256),
          kbJwtPayload: .init([
            Keys.nonce.rawValue: nonce,
            Keys.aud.rawValue: aud,
            Keys.iat.rawValue: timestamp,
            Keys.sdHash.rawValue: sdHash
          ])
        )
      )
    
    let serialized: String = CompactSerialiser(signedSDJWT: holder).serialised
    
    let metadataVerifier = SDJWTVCVerifier(
      verificationMethod: .metadata(fetcher: SdJwtVcIssuerMetaDataFetcher(
        session: NetworkingJSONMock(json: jsonObject)
      )
    )
   )
          
    let result = try await metadataVerifier.verifyPresentation(
      unverifiedSdJwt: serialized,
      claimsVerifier: ClaimsVerifier(),
      keyBindingVerifier: KeyBindingVerifier()
    )
    
    XCTAssertEqual(sdHash, holder.delineatedCompactSerialisation)
    XCTAssertNoThrow(try result.get())
  }
  
  
  func testVerifyIssuance_WithPolicyNotUsed_ShouldSucceed() async throws {
    
    // Given
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    
    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(
        trust: X509SDJWTVCCertificateChainVerifier(
          rootCertificates: try! SDJWTConstants.loadRootCertificates()
        )),
      typeMetadataPolicy: .notUsed
    )
    
    // When
    let result = try await verifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
    
    // Then
    XCTAssertNoThrow(try result.get())
  }

  
  func testVerifyIssuance_WithPolicyOptionalAndRealRemoteUrl_ShouldSucceed() async throws {
    
    // Given
    let keyData = Data(
      base64Encoded: SDJWTConstants.anIssuerPrivateKey
    )!
    
    let vct = try! Vct(uri: "https://dev.issuer-backend.eudiw.dev/type-metadata/urn:eudi:pid:1")
    let typeMetadataVerifier = typeMetadataVerifierFactory(useMock: false)
    let sdJwtString = try await SDJWTIssuer.issue(
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
      PlainClaim("vct", "urn:eudi:pid:1")
      FlatDisclosedClaim("family_name", "disclosedName")
      FlatDisclosedClaim("given_name", "disclosedName")
      FlatDisclosedClaim("birthdate", "birthdate")
      FlatDisclosedClaim("picture", "birthdate")
      FlatDisclosedClaim("birth_family_name", "birthdate")
      FlatDisclosedClaim("birth_given_name", "birthdate")
      FlatDisclosedClaim("email", "birthdate")
      FlatDisclosedClaim("phone_number", "birthdate")
      FlatDisclosedClaim("date_of_expiry", "birthdate")
      FlatDisclosedClaim("date_of_issuance", "date_of_issuance")
      FlatDisclosedClaim("sex", 1)
      RecursiveObject("age_equal_or_over") {
        FlatDisclosedClaim("18", true)
      }
      FlatDisclosedClaim("issuing_authority", "auth")
      FlatDisclosedClaim("document_number", "auth")
      FlatDisclosedClaim("issuing_country", "auth")
      FlatDisclosedClaim("issuing_jurisdiction", "auth")
      FlatDisclosedClaim("personal_administrative_number", "birthdate")
      FlatDisclosedClaim("place_of_birth",[
        "country": "IS",
        "locality": "Þykkvabæjarklaustur"
        ]
      )
      RecursiveObject("address") {
        FlatDisclosedClaim("street_address", "Schulstr. 12")
        FlatDisclosedClaim("locality", "Schulpforta")
        FlatDisclosedClaim("region", "Sachsen-Anhalt")
        FlatDisclosedClaim("country", "DE")
      }
      FlatDisclosedClaim("attestation_legal_category", "a_actegory")
      FlatDisclosedClaim("nationalities", ["DE", "FR", "EN"])
      FlatDisclosedClaim("age_in_years", 34)
      FlatDisclosedClaim("age_birth_year", "1990")
      FlatDisclosedClaim("trust_anchor", "https://trust.anchor.de")
    }.serialisation
    
    let verifier = SDJWTVCVerifier(
      verificationMethod: 
          .x509(
            trust: X509CertificateTrustFactory.trust
          ),
      typeMetadataPolicy: 
          .alwaysRequired(
            verifier: typeMetadataVerifier
          )
      )
    
    // When
    do {
      let result = try await verifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
      
      // Then
      XCTAssertNoThrow(try result.get())
    } catch {
      XCTExpectFailure()
      XCTFail()
    }
  }
  
  func testVerifyIssuance_WithPolicyOptional_ShouldSucceed() async throws {
    
    // Given
    let typeMetadataVerifier = typeMetadataVerifierFactory()
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    
    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(
      trust: X509SDJWTVCCertificateChainVerifier(
        rootCertificates: try! SDJWTConstants.loadRootCertificates()
      )),
      typeMetadataPolicy: .optional(verifier: typeMetadataVerifier)
      )
    
    // When
    let result = try await verifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
    
    // Then
    XCTAssertNoThrow(try result.get())
  }
  
  func testVerifyIssuance_WithPolicyAlwaysRequired_ValidMetadata_ShouldSucceed() async throws {
    
    // Given
    let typeMetadataVerifier = typeMetadataVerifierFactory()
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
      
      PlainClaim("vct", "https://mock.local/type_meta_data_pid")
      
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
    
    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(
        trust: X509CertificateTrustFactory.trust
      ),
      typeMetadataPolicy: .alwaysRequired(verifier: typeMetadataVerifier)
      )
    
    let sdJwtString =  issuerSignedSDJWT.serialisation
    // When
    let result = try await verifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
    
    // Then
    XCTAssertNoThrow(try result.get())
  
  }
  
  func testVerifyIssuance_WithPolicyRequiredForVcts_MissingDisclosure_ShouldFail() async throws {
    
    // Given
    let typeMetadataVerifier = typeMetadataVerifierFactory()
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
      
      PlainClaim("vct", "https://mock.local/type_meta_data_pid")
      
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
      //FlatDisclosedClaim("sex", 1) // Remove Disclosure
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
    
    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(
      trust: X509SDJWTVCCertificateChainVerifier(
        rootCertificates: try! SDJWTConstants.loadRootCertificates()
      )),
      typeMetadataPolicy: .requiredFor(vcts: ["https://mock.local/type_meta_data_pid", "other_metadata"], verifier: typeMetadataVerifier))
    
    let sdJwtString =  issuerSignedSDJWT.serialisation
  
    do {
      // When
      _ = try await verifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
      XCTFail("Verification should not be succeeded")
    } catch {
      let missingClaimPath = ClaimPath([.claim(name: "sex")])
      XCTAssertEqual(error as? TypeMetadataError, .expectedDisclosureMissing(path: missingClaimPath))
    }
  }
  
  // MARK: - Integrity Validation Tests

  func testVerifyIssuance_WithValidTypeMetadataIntegrity_ShouldSucceed() async throws {
    // Given: Create a type metadata mock with integrity hash
    let typeMetadataJSON = """
    {
      "vct": "https://mock.local/type_meta_data_with_integrity",
      "name": "Test Metadata with Integrity",
      "claims": [
        {
          "path": ["family_name"],
          "sd": "always"
        },
        {
          "path": ["given_name"],
          "sd": "always"
        }
      ]
    }
    """

    let metadataData = typeMetadataJSON.data(using: .utf8)!
    let sha256Hash = Data(SHA256.hash(data: metadataData)).base64EncodedString()
    let integrityHash = "sha256-\(sha256Hash)"

    let keyData = Data(base64Encoded: SDJWTConstants.anIssuerPrivateKey)!

    // Issue SD-JWT with vct and vct#integrity
    let issuerSignedSDJWT = try await SDJWTIssuer.issue(
      issuersPrivateKey: extractECKey(from: keyData),
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        x509CertificateChain: [SDJWTConstants.anIssuersPrivateKeySignedcertificate]
      )
    ) {
      ConstantClaims.iss(domain: "https://example.com/issuer")
      ConstantClaims.iat(time: Date())
      PlainClaim("vct", "https://mock.local/type_meta_data_with_integrity")
      PlainClaim("vct#integrity", integrityHash)
      FlatDisclosedClaim("family_name", "Doe")
      FlatDisclosedClaim("given_name", "John")
    }

    // Create verifier with SRI validator
    let sriValidator = try SRIValidator()
    let session = NetworkingDataMock(data: metadataData)

    let metadataFetcher = TypeMetadataFetcher(
      session: session,
      integrityValidator: sriValidator
    )

    let typeMetadataVerifier = TypeMetadataVerifier(
      metadataLookup: TypeMetadataLookupDefault(fetcher: metadataFetcher),
      schemaLookup: TypeMetadataSchemaLookupDefault(schemaFetcher: SchemaFetcher(session: session)),
      schemaValidator: SchemaValidator()
    )

    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateTrustFactory.trust),
      typeMetadataPolicy: .alwaysRequired(verifier: typeMetadataVerifier)
    )

    // When
    let result = try await verifier.verifyIssuance(unverifiedSdJwt: issuerSignedSDJWT.serialisation)

    // Then
    XCTAssertNoThrow(try result.get())
  }

  func testVerifyIssuance_WithInvalidTypeMetadataIntegrity_ShouldFail() async throws {
    // Given: Issue SD-JWT with incorrect integrity hash
    let keyData = Data(base64Encoded: SDJWTConstants.anIssuerPrivateKey)!
    let wrongIntegrityHash = "sha256-wronghash123456789ABCDEF="

    let issuerSignedSDJWT = try await SDJWTIssuer.issue(
      issuersPrivateKey: extractECKey(from: keyData),
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        x509CertificateChain: [SDJWTConstants.anIssuersPrivateKeySignedcertificate]
      )
    ) {
      ConstantClaims.iss(domain: "https://example.com/issuer")
      ConstantClaims.iat(time: Date())
      PlainClaim("vct", "https://mock.local/type_meta_data_pid")
      PlainClaim("vct#integrity", wrongIntegrityHash)
      FlatDisclosedClaim("family_name", "Doe")
      FlatDisclosedClaim("given_name", "John")
    }

    // Create verifier with SRI validator
    let sriValidator = try SRIValidator()
    let session = NetworkingBundleMock(
      filenameResolver: { url in url.lastPathComponent }
    )

    let metadataFetcher = TypeMetadataFetcher(
      session: session,
      integrityValidator: sriValidator
    )

    let typeMetadataVerifier = TypeMetadataVerifier(
      metadataLookup: TypeMetadataLookupDefault(fetcher: metadataFetcher),
      schemaLookup: TypeMetadataSchemaLookupDefault(schemaFetcher: SchemaFetcher(session: session)),
      schemaValidator: SchemaValidator()
    )

    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateTrustFactory.trust),
      typeMetadataPolicy: .alwaysRequired(verifier: typeMetadataVerifier)
    )

    // When & Then
    do {
      _ = try await verifier.verifyIssuance(unverifiedSdJwt: issuerSignedSDJWT.serialisation)
      XCTFail("Verification should fail with invalid integrity hash")
    } catch let error as TypeMetadataError {
      XCTAssertEqual(error, .integrityValidationFailed)
    } catch {
      XCTFail("Expected TypeMetadataError.integrityValidationFailed, got \(error)")
    }
  }

  func testVerifyIssuance_WithMultipleIntegrityHashes_SelectsStrongest() async throws {
    // Given: Create metadata with multiple integrity hashes (SHA-256, SHA-384, SHA-512)
    let typeMetadataJSON = """
    {
      "vct": "https://mock.local/test_metadata",
      "name": "Test Metadata",
      "claims": [{"path": ["test_claim"], "sd": "allowed"}]
    }
    """

    let metadataData = typeMetadataJSON.data(using: .utf8)!
    let sha256Hash = Data(SHA256.hash(data: metadataData)).base64EncodedString()
    let sha512Hash = Data(SHA512.hash(data: metadataData)).base64EncodedString()

    // Multiple hashes: SRI validator should select strongest (SHA-512)
    let multipleHashes = "sha256-\(sha256Hash) sha512-\(sha512Hash)"

    let keyData = Data(base64Encoded: SDJWTConstants.anIssuerPrivateKey)!

    let issuerSignedSDJWT = try await SDJWTIssuer.issue(
      issuersPrivateKey: extractECKey(from: keyData),
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        x509CertificateChain: [SDJWTConstants.anIssuersPrivateKeySignedcertificate]
      )
    ) {
      ConstantClaims.iss(domain: "https://example.com/issuer")
      ConstantClaims.iat(time: Date())
      PlainClaim("vct", "https://mock.local/test_metadata")
      PlainClaim("vct#integrity", multipleHashes)
      FlatDisclosedClaim("test_claim", "test_value")
    }

    let sriValidator = try SRIValidator()
    let session = NetworkingDataMock(data: metadataData)

    let metadataFetcher = TypeMetadataFetcher(
      session: session,
      integrityValidator: sriValidator
    )

    let typeMetadataVerifier = TypeMetadataVerifier(
      metadataLookup: TypeMetadataLookupDefault(fetcher: metadataFetcher),
      schemaLookup: TypeMetadataSchemaLookupDefault(schemaFetcher: SchemaFetcher(session: session)),
      schemaValidator: SchemaValidator()
    )

    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateTrustFactory.trust),
      typeMetadataPolicy: .alwaysRequired(verifier: typeMetadataVerifier)
    )

    // When
    let result = try await verifier.verifyIssuance(unverifiedSdJwt: issuerSignedSDJWT.serialisation)

    // Then: Should succeed by validating against strongest algorithm (SHA-512)
    XCTAssertNoThrow(try result.get())
  }

  func testVerifyIssuance_WithSchemaUriIntegrity_ShouldSucceed() async throws {
    // Given: Create type metadata with inline schema (testing metadata integrity, not schema URI)
    let metadataJSON = """
    {
      "vct": "https://mock.local/metadata_with_schema",
      "name": "Metadata with Inline Schema",
      "schema": {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "type": "object",
        "properties": {
          "family_name": {"type": "string"},
          "given_name": {"type": "string"}
        },
        "required": ["family_name", "given_name"]
      },
      "claims": [
        {"path": ["family_name"], "sd": "always"},
        {"path": ["given_name"], "sd": "always"}
      ]
    }
    """

    let keyData = Data(base64Encoded: SDJWTConstants.anIssuerPrivateKey)!

    let issuerSignedSDJWT = try await SDJWTIssuer.issue(
      issuersPrivateKey: extractECKey(from: keyData),
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        x509CertificateChain: [SDJWTConstants.anIssuersPrivateKeySignedcertificate]
      )
    ) {
      ConstantClaims.iss(domain: "https://example.com/issuer")
      ConstantClaims.iat(time: Date())
      PlainClaim("vct", "https://mock.local/metadata_with_schema")
      FlatDisclosedClaim("family_name", "Doe")
      FlatDisclosedClaim("given_name", "John")
    }

    let metadataData = metadataJSON.data(using: .utf8)!

    let sriValidator = try SRIValidator()
    let session = NetworkingDataMock(data: metadataData)

    let metadataFetcher = TypeMetadataFetcher(
      session: session,
      integrityValidator: sriValidator
    )

    let typeMetadataVerifier = TypeMetadataVerifier(
      metadataLookup: TypeMetadataLookupDefault(fetcher: metadataFetcher),
      schemaLookup: TypeMetadataSchemaLookupDefault(schemaFetcher: SchemaFetcher(session: session)),
      schemaValidator: SchemaValidator()
    )

    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateTrustFactory.trust),
      typeMetadataPolicy: .alwaysRequired(verifier: typeMetadataVerifier)
    )

    // When
    let result = try await verifier.verifyIssuance(unverifiedSdJwt: issuerSignedSDJWT.serialisation)

    // Then
    XCTAssertNoThrow(try result.get())
  }

  func testVerifyIssuance_WithExtendsIntegrity_ShouldValidateParentMetadata() async throws {
    // Given: Parent and child metadata with extends#integrity
    let parentMetadataJSON = """
    {
      "vct": "https://mock.local/parent_metadata",
      "name": "Parent Metadata",
      "claims": [
        {"path": ["base_claim"], "sd": "always"}
      ]
    }
    """

    let parentData = parentMetadataJSON.data(using: .utf8)!
    let parentHash = Data(SHA256.hash(data: parentData)).base64EncodedString()
    let parentIntegrity = "sha256-\(parentHash)"

    let childMetadataJSON = """
    {
      "vct": "https://mock.local/child_metadata",
      "name": "Child Metadata",
      "extends": "https://mock.local/parent_metadata",
      "extends#integrity": "\(parentIntegrity)",
      "claims": [
        {"path": ["child_claim"], "sd": "always"}
      ]
    }
    """

    let keyData = Data(base64Encoded: SDJWTConstants.anIssuerPrivateKey)!

    let issuerSignedSDJWT = try await SDJWTIssuer.issue(
      issuersPrivateKey: extractECKey(from: keyData),
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        x509CertificateChain: [SDJWTConstants.anIssuersPrivateKeySignedcertificate]
      )
    ) {
      ConstantClaims.iss(domain: "https://example.com/issuer")
      ConstantClaims.iat(time: Date())
      PlainClaim("vct", "https://mock.local/child_metadata")
      FlatDisclosedClaim("base_claim", "base_value")
      FlatDisclosedClaim("child_claim", "child_value")
    }

    let childData = childMetadataJSON.data(using: .utf8)!

    let sriValidator = try SRIValidator()
    let session = NetworkingMultiDataMock { url in
      if url.absoluteString.contains("parent") {
        return parentData
      }
      return childData
    }

    let metadataFetcher = TypeMetadataFetcher(
      session: session,
      integrityValidator: sriValidator
    )

    let typeMetadataVerifier = TypeMetadataVerifier(
      metadataLookup: TypeMetadataLookupDefault(fetcher: metadataFetcher),
      schemaLookup: TypeMetadataSchemaLookupDefault(schemaFetcher: SchemaFetcher(session: session)),
      schemaValidator: SchemaValidator()
    )

    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateTrustFactory.trust),
      typeMetadataPolicy: .alwaysRequired(verifier: typeMetadataVerifier)
    )

    // When
    let result = try await verifier.verifyIssuance(unverifiedSdJwt: issuerSignedSDJWT.serialisation)

    // Then: Should succeed with parent metadata integrity validated
    XCTAssertNoThrow(try result.get())
  }

  func testVerifyPresentation_WithIntegrityValidation_ShouldSucceed() async throws {
    // Given: Full presentation flow with integrity validation
    let typeMetadataJSON = """
    {
      "vct": "https://mock.local/simple_type_metadata",
      "name": "Simple Metadata",
      "claims": [
        {"path": ["family_name"], "sd": "always"},
        {"path": ["given_name"], "sd": "always"},
        {"path": ["birthdate"], "sd": "always"}
      ]
    }
    """
    let metadataData = typeMetadataJSON.data(using: .utf8)!

    let keyData = Data(base64Encoded: SDJWTConstants.anIssuerPrivateKey)!
    let issuersKey = issuersKeyPair.public
    let issuerJwk = try issuersKey.jwk

    let holdersKey = holdersKeyPair.public
    let holdersJwk = try holdersKey.jwk

    // Issue SD-JWT
    let issuerSignedSDJWT = try await SDJWTIssuer.issue(
      issuersPrivateKey: extractECKey(from: keyData),
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        x509CertificateChain: [SDJWTConstants.anIssuersPrivateKeySignedcertificate]
      )
    ) {
      ConstantClaims.iss(domain: "https://example.com/issuer")
      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date() + 3600)
      PlainClaim("vct", "https://mock.local/simple_type_metadata")
      FlatDisclosedClaim("family_name", "Doe")
      FlatDisclosedClaim("given_name", "John")
      FlatDisclosedClaim("birthdate", "1990-01-01")

      // Add holder's public key
      ObjectClaim("cnf") {
        ObjectClaim("jwk") {
          PlainClaim("kty", "EC")
          PlainClaim("crv", "P-256")
          PlainClaim("y", holdersJwk.y!.base64URLEncode())
          PlainClaim("x", holdersJwk.x!.base64URLEncode())
        }
      }
    }

    // Create presentation
    let sdHash = DigestCreator().hashAndBase64Encode(
      input: CompactSerialiser(signedSDJWT: issuerSignedSDJWT).serialised
    )!

    let nonce = UUID().uuidString
    let aud = "verifier_id"

    let holderPresentation = try await SDJWTIssuer.presentation(
      holdersPrivateKey: holdersKeyPair.private,
      signedSDJWT: issuerSignedSDJWT,
      disclosuresToPresent: issuerSignedSDJWT.disclosures,
      keyBindingJWT: KBJWT(
        header: DefaultJWSHeaderImpl(algorithm: .ES256),
        kbJwtPayload: .init([
          Keys.nonce.rawValue: nonce,
          Keys.aud.rawValue: aud,
          Keys.iat.rawValue: Int(Date().timeIntervalSince1970),
          Keys.sdHash.rawValue: sdHash
        ])
      )
    )

    // Create verifier with SRI validation
    let sriValidator = try SRIValidator()
    let session = NetworkingDataMock(data: metadataData)

    let metadataFetcher = TypeMetadataFetcher(
      session: session,
      integrityValidator: sriValidator
    )

    let typeMetadataVerifier = TypeMetadataVerifier(
      metadataLookup: TypeMetadataLookupDefault(fetcher: metadataFetcher),
      schemaLookup: TypeMetadataSchemaLookupDefault(schemaFetcher: SchemaFetcher(session: session)),
      schemaValidator: SchemaValidator()
    )

    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateTrustFactory.trust),
      typeMetadataPolicy: .alwaysRequired(verifier: typeMetadataVerifier)
    )

    // When
    let result = try await verifier.verifyPresentation(
      unverifiedSdJwt: CompactSerialiser(signedSDJWT: holderPresentation).serialised,
      claimsVerifier: ClaimsVerifier(),
      keyBindingVerifier: KeyBindingVerifier()
    )

    // Then
    XCTAssertNoThrow(try result.get())
  }

  func testVerifyIssuance_WithIntegrityValidationDisabled_ShouldSucceed() async throws {
    // Given: Verifier without SRI validator (integrity validation disabled)
    let typeMetadataJSON = """
    {
      "vct": "https://mock.local/simple_metadata",
      "name": "Simple Metadata",
      "claims": [
        {"path": ["family_name"], "sd": "always"},
        {"path": ["given_name"], "sd": "always"}
      ]
    }
    """
    let metadataData = typeMetadataJSON.data(using: .utf8)!

    let keyData = Data(base64Encoded: SDJWTConstants.anIssuerPrivateKey)!

    let issuerSignedSDJWT = try await SDJWTIssuer.issue(
      issuersPrivateKey: extractECKey(from: keyData),
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256,
        x509CertificateChain: [SDJWTConstants.anIssuersPrivateKeySignedcertificate]
      )
    ) {
      ConstantClaims.iss(domain: "https://example.com/issuer")
      ConstantClaims.iat(time: Date())
      PlainClaim("vct", "https://mock.local/simple_metadata")
      PlainClaim("vct#integrity", "sha256-wronghash123=") // Wrong hash, but validator is disabled
      FlatDisclosedClaim("family_name", "Doe")
      FlatDisclosedClaim("given_name", "John")
    }

    // Create verifier WITHOUT SRI validator
    let session = NetworkingDataMock(data: metadataData)

    let metadataFetcher = TypeMetadataFetcher(
      session: session,
      integrityValidator: nil  // No integrity validator
    )

    let typeMetadataVerifier = TypeMetadataVerifier(
      metadataLookup: TypeMetadataLookupDefault(fetcher: metadataFetcher),
      schemaLookup: TypeMetadataSchemaLookupDefault(schemaFetcher: SchemaFetcher(session: session)),
      schemaValidator: SchemaValidator()
    )

    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(trust: X509CertificateTrustFactory.trust),
      typeMetadataPolicy: .alwaysRequired(verifier: typeMetadataVerifier)
    )

    // When
    let result = try await verifier.verifyIssuance(unverifiedSdJwt: issuerSignedSDJWT.serialisation)

    // Then: Should succeed even with wrong hash because validation is disabled
    XCTAssertNoThrow(try result.get())
  }
  
  
  func testVerifyIssuance_WithPolicyRequiredForVcts_EmptyRequiredSet_ShouldFail() async throws {
    
    // Given
    let typeMetadataVerifier = typeMetadataVerifierFactory()
    let sdJwtString = SDJWTConstants.secondary_issuer_sd_jwt.clean()
    
    let verifier = SDJWTVCVerifier(
      verificationMethod: .x509(
      trust: X509SDJWTVCCertificateChainVerifier(
        rootCertificates: try! SDJWTConstants.loadRootCertificates()
      )),
      typeMetadataPolicy: .requiredFor(vcts: [], verifier: typeMetadataVerifier)
      )
    
    do {
      // When
      _ = try await verifier.verifyIssuance(unverifiedSdJwt: sdJwtString)
      XCTFail("Verification should not be succeeded")
    } catch {
      XCTAssertEqual(error as? TypeMetadataError, .emptyRequiredVcts)
    }
  }
  
  
  private func typeMetadataVerifierFactory(
    useMock: Bool = true
  ) -> TypeMetadataVerifierType {
    let session: Networking = useMock ? (
      NetworkingBundleMock(
        filenameResolver: { url in
          url.lastPathComponent
        })
    ) : URLSession.shared
    
    let metadataFetcher = TypeMetadataFetcher(session: session)
    
    let metadataLookup = TypeMetadataLookupDefault(
      fetcher: metadataFetcher
    )
    
    let verifier = TypeMetadataVerifier(
      metadataLookup: metadataLookup)
    
    return verifier
  }
}

