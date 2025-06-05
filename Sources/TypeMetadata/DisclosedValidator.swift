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


package protocol DisclosedValidatorType {
  func validate(_ metadata: ResolvedTypeMetadata?, _ disclosures: DisclosuresPerClaimPath?) throws
}

struct DisclosedValidator: DisclosedValidatorType {
  func validate(_ metadata: ResolvedTypeMetadata?, _ disclosures: DisclosuresPerClaimPath?) throws {
    
    guard let metadata = metadata else {
      throw TypeMetadataError.missingTypeMetadataForDisclosureValidation
    }
    
    guard let disclosures = disclosures else {
      throw TypeMetadataError.missingDisclosuresForValidation
    }
    
    for claim in metadata.claims {
      
      let claimPath = claim.path

      switch claim.selectivelyDisclosable {
      case .always:
        guard let claimDisclosures = disclosures[claimPath], !claimDisclosures.isEmpty else {
          throw TypeMetadataError.expectedDisclosureMissing(path: claimPath)
        }
      case .never:
        if disclosures[claimPath] != nil {
          throw TypeMetadataError.unexpectedDisclosurePresent(path: claimPath)
        }
      case .allowed:
        continue
      }
    }
    
    return
  }
}
                                
                                
                                
                              
