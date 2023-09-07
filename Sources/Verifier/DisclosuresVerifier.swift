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

  let disclosuresReceivedInSDJWT: [Disclosure]
  let digestsFoundOnPayload: [DigestType]
  let digestCreator: DigestCreator

  init(sdJwt: SDJWT) throws {
    self.disclosuresReceivedInSDJWT = sdJwt.disclosures
    self.digestsFoundOnPayload = sdJwt.jwt.payload.findDigests()

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
    // Create the digest for the enveloped disclosures
    // Convert the base64 string to the hash, Digests we got passed
    // Base64 [salt, key, value]
    let digestsOfDisclosures = disclosuresReceivedInSDJWT.compactMap { string in
      return digestCreator.hashAndBase64Encode(input: string)
    }

    let disclosureForDigestDict = try matchDigests(disclosuresDigestsInPayload: digestsFoundOnPayload, digestsOfDisclosures: digestsOfDisclosures)

    try digestsFoundOnPayload.forEach { digestType in
      if let disclosureForDigest = disclosureForDigestDict[digestType.rawValue] {
        try verifyDigestsStructure(digestType: digestType, disclosure: disclosureForDigest)
      }
    }

    return true
  }


  func matchDigests(disclosuresDigestsInPayload: [DigestType], digestsOfDisclosures: [DisclosureDigest]) throws -> [DisclosureDigest: Disclosure] {

    // Retrieve the value for each collected digest and create a set to remove
    // any potential duplicates
    // Digests found in JSON
    let setOfCollectedDigests = Set(disclosuresDigestsInPayload.compactMap({$0.rawValue}))
    guard setOfCollectedDigests.count == disclosuresDigestsInPayload.count else {
      throw SDJWTVerifierError.nonUniqueDisclosureDigests
    }
    // Create a set of the digests of the enveloped disclosures
    // Digests we got passed
    let setOfDisclosuresDigests = Set(digestsOfDisclosures)

    guard setOfDisclosuresDigests.count == digestsOfDisclosures.count else {
      throw SDJWTVerifierError.nonUniqueDisclosures
    }
    // Find the common elements
    let commonElements = setOfCollectedDigests.intersection(setOfDisclosuresDigests)

    guard commonElements.count == setOfDisclosuresDigests.count else {
      throw SDJWTVerifierError.missingDigests(disclosures: Array(setOfDisclosuresDigests.subtracting(commonElements)))
    }

    return try dictionaryOfCommonElements(commonElements)
  }

  fileprivate func dictionaryOfCommonElements(_ commonElements: Set<DisclosureDigest>) throws -> [DisclosureDigest : Disclosure] {
    let digestsOfDisclosuresDict = try disclosuresReceivedInSDJWT.reduce(into: [DisclosureDigest: Disclosure]()) { partialResult, string in
      guard let digest = digestCreator.hashAndBase64Encode(input: string) else {
        throw SDJWTVerifierError.failedToCreateVerifier
      }

      partialResult[digest] = string
    }

    return commonElements.reduce(into: [DisclosureDigest: Disclosure]()) { partialResult, key in
      partialResult[key] = digestsOfDisclosuresDict[key]
    }
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
