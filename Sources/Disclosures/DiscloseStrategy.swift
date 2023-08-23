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

typealias SDJWTElement = (claim: Claim, disclosure: Disclosure?)

protocol DiscloseStrategyProtocol: ClaimConvertible {

  var claim: Claim { get }

  func asJWTElement() -> SDJWTElement
}

protocol ClaimConvertible {
  func asJWTElement() -> SDJWTElement
}

struct FlatDisclose: DiscloseStrategyProtocol {

  // MARK: - Properties

  var claim: Claim
  var digestCreator: DigestCreator
  // MARK: - LifeCycle

  init(digestCreator: DigestCreator? = nil,
       builder: () -> Claim) {
    self.claim = builder()

    if let digestCreator = digestCreator {
      self.digestCreator = digestCreator
    } else {
      self.digestCreator = DigestCreator()
    }

  }

  // MARK: - Methods

  func asJWTElement() -> SDJWTElement {
    let disclosed = DisclosedClaim(claim.key, .init(claim.flatString))
    let digest = disclosed.base64Encode(saltProvider: digestCreator.saltProvider).flatString
    guard let disclosed = self.flatDisclose(claim: disclosed, digestCreator: digestCreator) else {
      return (disclosed, digest)
    }
    return (disclosed, digest)
  }

  func flatDisclose(claim: Claim, digestCreator: DigestCreator) -> Claim? {
    var claim = claim
    guard let encoded = try? claim.base64Encode(saltProvider: digestCreator.saltProvider) else {
      return nil
    }

    guard let hashedValue = try? claim.hashValue(digestCreator: digestCreator, base64EncodedValue: encoded.value) else {
      return nil
    }

    switch claim.value {
    case .array(let array):
      claim.value = .array(array + [hashedValue])
    case .object, . base:
      claim.key = "_sd"
      claim.value  = .array([hashedValue])
    }

    return claim
  }
}
