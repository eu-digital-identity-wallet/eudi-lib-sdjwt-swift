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

public typealias KBJWT = JWT

public struct SDJWT {
  
  // MARK: - Properties
  
  public internal(set) var jwt: JWT
  public internal(set) var disclosures: [Disclosure]
  public internal(set) var kbJwt: JWT?
  
  // MARK: - Lifecycle
  
  init(
    jwt: JWT,
    disclosures: [Disclosure],
    kbJWT: KBJWT? = nil
  ) throws {
    self.jwt = jwt
    self.disclosures = disclosures
    self.kbJwt = kbJWT
  }
  
  func extractDigestCreator() throws -> DigestCreator {
    if jwt.payload[Keys.sdAlg.rawValue].exists() {
      let stringValue = jwt.payload[Keys.sdAlg.rawValue].stringValue
      let algorithIdentifier = HashingAlgorithmIdentifier.allCases.first(where: {$0.rawValue == stringValue})
      guard let algorithIdentifier else {
        throw SDJWTVerifierError.missingOrUnknownHashingAlgorithm
      }
      return DigestCreator(hashingAlgorithm: algorithIdentifier.hashingAlgorithm())
    } else {
      throw SDJWTVerifierError.missingOrUnknownHashingAlgorithm
    }
  }
  
  func recreateClaims() throws -> ClaimExtractorResult {
    let digestCreator = try extractDigestCreator()
    var digestsOfDisclosuresDict = [DisclosureDigest: Disclosure]()
    for disclosure in self.disclosures {
      let hashed = digestCreator.hashAndBase64Encode(input: disclosure)
      if let hashed {
        digestsOfDisclosuresDict[hashed] = disclosure
      } else {
        throw SDJWTVerifierError.failedToCreateVerifier
      }
    }
    
    let visitor = Visitor()
    return try ClaimExtractor(
      digestsOfDisclosuresDict: digestsOfDisclosuresDict
    ).findDigests(
      payload: jwt.payload,
      disclosures: disclosures,
      visitor: visitor
    )
  }
}
