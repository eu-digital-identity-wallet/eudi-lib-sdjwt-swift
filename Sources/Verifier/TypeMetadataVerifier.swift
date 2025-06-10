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
  func verifyTypeMetadata(sdJwt: SignedSDJWT) async throws
}

public class TypeMetadataVerifier: TypeMetadataVerifierType {
  
  let metadataLookup: TypeMetadataLookup
  let schemaLookup: TypeMetadataSchemaLookup
  let typeMetadataMerger: TypeMetadataMergerType = TypeMetadataMerger()
  let schemaValidator: SchemaValidatorType = SchemaValidator()
  let disclosedValidator: DisclosedValidatorType = DisclosedValidator()
  let claimsValidator: TypeMetadataClaimsValidatorType = TypeMetadataClaimsValidator()
  
  public init(
    metadataLookup: TypeMetadataLookup,
    schemaLookup: TypeMetadataSchemaLookup
  ) {
    self.metadataLookup = metadataLookup
    self.schemaLookup = schemaLookup
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

