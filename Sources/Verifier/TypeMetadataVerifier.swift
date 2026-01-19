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


public protocol TypeMetadataVerifierType {
  
  /**
   Verifies that a SignedSDJWT's claims and disclosures match the expected type metadata and schemas.
   
   - Parameter sdJwt: The signed SD-JWT to verify.
   - Throws: Various validation errors depending on the step that fails.
   */
  func verifyTypeMetadata(sdJwt: SignedSDJWT) async throws
  
  
  /**
   Verifies that a SignedSDJWT's claims and disclosures match the expected type metadata and schemas.
   
   - Parameter sdJwt: The signed SD-JWT to verify.
   - Parameter vcts: Array of required vcts
   - Throws: Various validation errors depending on the step that fails.
   */
  func verifyTypeMetadata(for vcts:Set<String>, sdJwt: SignedSDJWT) async throws
}

public class TypeMetadataVerifier: TypeMetadataVerifierType {
  
  let metadataLookup: TypeMetadataLookup
  var typeMetadataMerger: TypeMetadataMergerType
  let disclosedValidator: DisclosureValidatorType
  let claimsValidator: TypeMetadataClaimsValidatorType
  
  public init(
    metadataLookup: TypeMetadataLookup
  ) {
    self.metadataLookup = metadataLookup
    self.typeMetadataMerger = TypeMetadataMerger()
    self.disclosedValidator = DisclosureValidator()
    self.claimsValidator = TypeMetadataClaimsValidator()
  }
  
  init(
    metadataLookup: TypeMetadataLookup,
    typeMetadataMerger: TypeMetadataMergerType = TypeMetadataMerger(),
    disclosedValidator: DisclosureValidatorType = DisclosureValidator(),
    claimsValidator: TypeMetadataClaimsValidatorType = TypeMetadataClaimsValidator()
  ) {
    self.metadataLookup = metadataLookup
    self.typeMetadataMerger = typeMetadataMerger
    self.disclosedValidator = disclosedValidator
    self.claimsValidator = claimsValidator
  }
  
  public func verifyTypeMetadata(
    sdJwt: SignedSDJWT
  ) async throws  {
    
    let result = try sdJwt.recreateClaims()
    let claims = result.recreatedClaims
    let disclosuresPerClaimPath = result.disclosuresPerClaimPath

    guard let vctUri = claims["vct"].string else {
      throw TypeMetadataError.missingOrInvalidVCT
    }
    
    let vct = try Vct(uri: vctUri, integrityHash: claims["vct#integrity"].string)
    let metadataArray = try await metadataLookup.getTypeMetadata(vct: vct)
    let finalData = try typeMetadataMerger.mergeMetadata(from: metadataArray.map { $0.toResolvedTypeMetadata() })
    try claimsValidator.validate(claims, finalData)
    try disclosedValidator.validate(finalData, disclosuresPerClaimPath)
  }
  
  public func verifyTypeMetadata(
    for vcts:Set<String>,
    sdJwt: SignedSDJWT
  ) async throws {
    let result = try sdJwt.recreateClaims()
    let claims = result.recreatedClaims
    let disclosuresPerClaimPath = result.disclosuresPerClaimPath
    guard let vctUri = claims["vct"].string else {
      throw TypeMetadataError.missingOrInvalidVCT
    }
    guard !vcts.isEmpty else {
      throw TypeMetadataError.emptyRequiredVcts
    }
  
    let vct = try Vct(uri: vctUri, integrityHash: claims["vct#integrity"].string)
    let metadataArray = try await metadataLookup.getTypeMetadata(vct: vct)
    
    // Filter only required metadata based on VCTs
    let requiredMetadata = metadataArray.filter { vcts.contains($0.vct) }
    
    // If no required metadata matches, skip validations
    guard !requiredMetadata.isEmpty else { return }
    
    let finalData = try typeMetadataMerger.mergeMetadata(from: requiredMetadata.map { $0.toResolvedTypeMetadata() })
    try claimsValidator.validate(result.recreatedClaims, finalData)
    try disclosedValidator.validate(finalData, disclosuresPerClaimPath)
  }
}
