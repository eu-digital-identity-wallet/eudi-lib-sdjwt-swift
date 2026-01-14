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

public protocol ClaimVisitorType: Sendable {
  func call(
    pointer: JSONPointer,
    disclosure: Disclosure,
    value: String?
  )
  
  func call(
    path: ClaimPath?,
    disclosure: Disclosure,
    value: String?
  )
  
  func call(
    pointer: JSONPointer,
    path: ClaimPath?,
    disclosure: Disclosure,
    value: String?
  )
}

public final class ClaimVisitor: ClaimVisitorType {
  
  nonisolated(unsafe) var disclosuresPerClaim: [JSONPointer: [Disclosure]] = [:]
  nonisolated(unsafe) var disclosuresPerClaimPath: [ClaimPath: [Disclosure]] = [:]
  nonisolated(unsafe) var disclosures: [Disclosure] {
    disclosuresPerClaim.flatMap { $0.value }
  }
  
  public init() {
  }
  
  public func call(
    pointer: JSONPointer,
    path: ClaimPath?,
    disclosure: Disclosure = "",
    value: String? = nil
  ) {
    
    let registered: [ClaimPathElement] = SdJwtSpec.registeredNonDisclosableClaims.map {
      .claim(name: $0)
    }

    if let first = path?.value.first, registered.contains(first) {
      return
    }
    
    call(pointer: pointer, disclosure: disclosure, value: value)
    call(path: path, disclosure: disclosure, value: value)
  }
  
  public func call(
    pointer: JSONPointer,
    disclosure: Disclosure,
    value: String? = nil
  ) {

    // Calculate claimDisclosures
    let claimDisclosures: [Disclosure] = {
      let containerPath = pointer.parent()
      let containerDisclosures = containerPath.flatMap { disclosuresPerClaim[$0] } ?? []
      return containerDisclosures + [disclosure]
    }()
    
    // Insert the claimDisclosures only if the pointer doesn't already exist
    disclosuresPerClaim[pointer] = disclosuresPerClaim[pointer] ?? claimDisclosures
  }
  
  public func call(
    path: ClaimPath?,
    disclosure: Disclosure,
    value: String?
  ) {
    guard let path = path else { return }
    
    // Calculate claimDisclosures
    let claimDisclosures: [Disclosure] = {
      let containerPath = path.parent()
      let containerDisclosures = containerPath.flatMap { disclosuresPerClaimPath[$0] } ?? []
      return containerDisclosures + [disclosure]
    }()
    
    // Insert the claimDisclosures only if the pointer doesn't already exist
    disclosuresPerClaimPath[path] = disclosuresPerClaimPath[path] ?? claimDisclosures
  }
}

