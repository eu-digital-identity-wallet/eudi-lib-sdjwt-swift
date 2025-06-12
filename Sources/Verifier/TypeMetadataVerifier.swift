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
import JSONSchema


public protocol TypeMetadataVerifierType {
  
  /**
   Verifies that a SignedSDJWT's claims and disclosures match the expected type metadata and schemas.
   
   - Parameter sdJwt: The signed SD-JWT to verify.
   - Throws: Various validation errors depending on the step that fails.
   */
  func verifyTypeMetadata(sdJwt: SignedSDJWT) async throws
}

public class TypeMetadataVerifier: TypeMetadataVerifierType {
  
  let metadataLookup: TypeMetadataLookup
  let schemaLookup: TypeMetadataSchemaLookup
  var typeMetadataMerger: TypeMetadataMergerType
  let schemaValidator: SchemaValidatorType
  let disclosedValidator: DisclosureValidatorType
  let claimsValidator: TypeMetadataClaimsValidatorType
  
  public init(
    metadataLookup: TypeMetadataLookup,
    schemaLookup: TypeMetadataSchemaLookup
  ) {
    self.metadataLookup = metadataLookup
    self.schemaLookup = schemaLookup
    self.typeMetadataMerger = TypeMetadataMerger()
    self.schemaValidator = SchemaValidator()
    self.disclosedValidator = DisclosureValidator()
    self.claimsValidator = TypeMetadataClaimsValidator()
  }
  
  init(
    metadataLookup: TypeMetadataLookup,
    schemaLookup: TypeMetadataSchemaLookup,
    typeMetadataMerger: TypeMetadataMergerType = TypeMetadataMerger(),
    schemaValidator: SchemaValidatorType = SchemaValidator(),
    disclosedValidator: DisclosureValidatorType = DisclosureValidator(),
    claimsValidator: TypeMetadataClaimsValidatorType = TypeMetadataClaimsValidator()
  ) {
    self.metadataLookup = metadataLookup
    self.schemaLookup = schemaLookup
    self.typeMetadataMerger = typeMetadataMerger
    self.schemaValidator = schemaValidator
    self.disclosedValidator = disclosedValidator
    self.claimsValidator = claimsValidator
  }
  
  public func verifyTypeMetadata(
    sdJwt: SignedSDJWT
  ) async throws  {
    
    let result = try sdJwt.recreateClaims()
    let disclosuresPerClaimPath = result.disclosuresPerClaimPath
    let metadataArray = try await metadataLookup.getTypeMetadata()
    let finalData = typeMetadataMerger.mergeMetadata(from: metadataArray.map { $0.toResolvedTypeMetadata() })
    try claimsValidator.validate(result.recreatedClaims, finalData)
    let schemas = try await schemaLookup.getSchemas(metadataArray: metadataArray)
    try schemaValidator.validate(result.recreatedClaims, schemas)
    try disclosedValidator.validate(finalData, disclosuresPerClaimPath)
  }
}
