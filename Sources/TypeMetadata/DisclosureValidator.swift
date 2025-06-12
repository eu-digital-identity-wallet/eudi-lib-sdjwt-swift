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


package protocol DisclosureValidatorType {
  
  /**
   Validates that the given disclosures satisfy the selectively disclosable constraints
   defined in the resolved type metadata.
   
   - Parameters:
   - metadata: The resolved type metadata containing claim definitions and constraints.
   - disclosures: A dictionary of disclosures keyed by claim path.
   - Throws: A `TypeMetadataError` if any disclosure constraint is violated.
   */
  func validate(_ metadata: ResolvedTypeMetadata?, _ disclosures: DisclosuresPerClaimPath?) throws
}


struct DisclosureValidator: DisclosureValidatorType {
  func validate(_ metadata: ResolvedTypeMetadata?, _ disclosures: DisclosuresPerClaimPath?) throws {
    
    guard let metadata = metadata else {
      throw TypeMetadataError.missingTypeMetadata
    }
    
    guard let disclosures = disclosures else {
      throw TypeMetadataError.missingDisclosuresForValidation
    }
    
    for claim in metadata.claims {
      
      let claimPath = claim.path
      switch claim.selectivelyDisclosable {
      case .always:
        let hasDirectDisclosure = disclosures[claimPath]?.isEmpty == false
        let hasWildcardDisclosure = disclosures.first { disclosedPath, _ in
          claimPath.contains(disclosedPath)
        } != nil
        
        guard hasDirectDisclosure || hasWildcardDisclosure else {
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
