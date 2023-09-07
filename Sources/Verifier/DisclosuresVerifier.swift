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

class DisclosuresVerifier: VerifierProtocol {

  var sdJwt: SDJWT
  let digestCreator: DigestCreator

  init(sdJwt: SDJWT) throws {
    self.sdJwt = sdJwt

    if sdJwt.jwt.payload[Keys.sdAlg.rawValue].exists() {
      let stringValue = sdJwt.jwt.payload[Keys.sdAlg.rawValue].stringValue
      let algorithIdentifier = HashingAlgorithmIdentifier.allCases.first(where: {$0.rawValue == stringValue})
      guard let algorithIdentifier else {
        throw SDJWTVerifierError.missingOrUnknownHashingAlgorithm
      }
      self.digestCreator = DigestCreator(hashingAlgorithm: algorithIdentifier.hashingAlgorithm())
    } else {
      self.digestCreator = DigestCreator(hashingAlgorithm: SHA256Hashing())
    }
  }

  func verify() throws -> Bool {

    let embededDigests = sdJwt.jwt.payload.findDigests()
    let disclosureForDigestDict = try matchDigests(disclosuresDigests: embededDigests)

    try embededDigests.forEach { digestType in
      guard let disclosureForDigest = disclosureForDigestDict[digestType.rawValue] else {
        throw SDJWTVerifierError.missingDigests(disclosures: [digestType.rawValue])
      }
      try verifyDigestsStructure(digestType: digestType, disclosure: disclosureForDigest)
    }

    return true
  }

  func matchDigests(disclosuresDigests: [DigestType]) throws -> [DisclosureDigest: Disclosure] {

    let digestsOfDisclosures = self.sdJwt.disclosures.compactMap { string in
      return digestCreator.hashAndBase64Encode(input: string)
    }

    let setOfCollectedDigests = Set(disclosuresDigests.compactMap({$0.rawValue}))
    let setOfDisclosuresDigests = Set(digestsOfDisclosures)
    let commonElements = setOfCollectedDigests.intersection(setOfDisclosuresDigests)

    guard commonElements.count == sdJwt.disclosures.count else {
      throw SDJWTVerifierError.missingDigests(disclosures: Array(commonElements.subtracting(setOfDisclosuresDigests)))
    }

    let digestsOfDisclosuresDict = try self.sdJwt.disclosures.reduce(into: [DisclosureDigest: Disclosure]()) { partialResult, string in
      guard let digest = digestCreator.hashAndBase64Encode(input: string) else {
        throw SDJWTVerifierError.failedToCreateVerifier
      }

      partialResult[digest] = string
    }

    return digestsOfDisclosuresDict
  }

  func verifyDigestsStructure(digestType: DigestType, disclosure: Disclosure) throws {
    // Decode the base64 string
    guard let decodedFromBase64 = disclosure.base64URLDecode() else {
      throw SDJWTVerifierError.invalidDisclosure(disclosures: [disclosure])
    }
    // form an array of the components
    let jsonArray = JSON(parseJSON: decodedFromBase64)
    // compare against the expected components for each use case
    guard jsonArray.arrayValue.count == digestType.components else {
      throw SDJWTVerifierError.invalidDisclosure(disclosures: [disclosure])
    }
  }

}
