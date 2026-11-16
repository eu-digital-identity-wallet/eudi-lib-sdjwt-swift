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
  func validate(
    _ metadata: ResolvedTypeMetadata?,
    _ disclosures: DisclosuresPerClaimPath?
  ) throws
}


struct DisclosureValidator: DisclosureValidatorType {
  func validate(
    _ metadata: ResolvedTypeMetadata?,
    _ disclosures: DisclosuresPerClaimPath?
  ) throws {
    
    guard let metadata = metadata else {
      throw TypeMetadataError.missingTypeMetadata
    }
    
    guard let disclosures = disclosures else {
      throw TypeMetadataError.missingDisclosuresForValidation
    }

    // registered claims (iss, exp, nbf, cnf, vct, vct#integrity,
    // status) are defined at the JWT top level and must never be selectively
    // disclosable. The check keys off the ROOT of the claim path (not the
    // leaf) and treats placeholder (empty-string) entries as "not actually
    // disclosed".
    for (claimPath, disclosureList) in disclosures {
      guard let root = claimPath.value.first,
            case .claim(let rootName) = root,
            SdJwtSpec.registeredNonDisclosableClaims.contains(rootName) else {
        continue
      }
      if Self.hasRealDisclosure(disclosureList) {
        throw TypeMetadataError.unexpectedDisclosurePresent(path: claimPath)
      }
    }

    for claim in metadata.claims {

      let claimPath = claim.path
      switch claim.selectivelyDisclosable {
      case .always:
        // hasRealDisclosure ignores the empty-string placeholders
        // the visitor records for plain primitives. Both the direct and
        // the containment ("wildcard") fallback must independently require
        // at least one real disclosure for the constraint to be satisfied.
        let hasDirectDisclosure = Self.hasRealDisclosure(disclosures[claimPath])
        let hasWildcardDisclosure = disclosures.contains { disclosedPath, list in
          claimPath.contains(disclosedPath) && Self.hasRealDisclosure(list)
        }

        guard hasDirectDisclosure || hasWildcardDisclosure else {
          throw TypeMetadataError.expectedDisclosureMissing(path: claimPath)
        }

      case .never:
        let hasForbiddenDisclosure = disclosures.contains { disclosedPath, list in
          claimPath.contains(disclosedPath) && Self.hasRealDisclosure(list)
        }
        if hasForbiddenDisclosure {
          throw TypeMetadataError.unexpectedDisclosurePresent(path: claimPath)
        }
      case .allowed:
        continue
      }
    }
    
    return
  }

  // Only non-empty entries count as actual disclosures.
  private static func hasRealDisclosure(_ list: [Disclosure]?) -> Bool {
    guard let list = list else { return false }
    return list.contains(where: { !$0.isEmpty })
  }
}
