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

public protocol ClaimVisitor: Sendable {
  func call(pointer: JSONPointer, disclosure: Disclosure)
}

public final class Visitor: ClaimVisitor {
  
  nonisolated(unsafe) var disclosuresPerClaim: [JSONPointer: [Disclosure]] = [:]
  nonisolated(unsafe) var disclosures: [Disclosure] {
    disclosuresPerClaim.flatMap { $0.value }
  }
  
  public init() {
  }
  
  public func call(pointer: JSONPointer, disclosure: Disclosure) {
    // Ensure that the path (pointer) does not already exist in disclosuresPerClaim
    guard disclosuresPerClaim[pointer] == nil else {
      fatalError("Disclosures for \(pointer.pointer) have already been calculated.")
    }
    
    // Calculate claimDisclosures
    let claimDisclosures: [Disclosure] = {
      let containerPath = pointer.parent() // Assuming pointer has a parent() method
      let containerDisclosures = containerPath.flatMap { disclosuresPerClaim[$0] } ?? []
      
      return containerDisclosures + [disclosure]
    }()
    
    // Insert the claimDisclosures only if the pointer doesn't already exist
    disclosuresPerClaim[pointer] = disclosuresPerClaim[pointer] ?? claimDisclosures
    
    
    print("Visitor: \(pointer.pointer) \(disclosure)")
  }
}

