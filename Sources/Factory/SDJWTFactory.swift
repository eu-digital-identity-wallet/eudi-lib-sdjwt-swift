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

typealias ClaimSet = (value: JSON, disclosures: [Disclosure])

class SDJWTFactory {

  // MARK: - Properties

  let digestCreator: DigestCreator
  let saltProvider: SaltProvider
  let decoysLimit: Int

  var decoyCounter = 0
  // MARK: - LifeCycle

  init(digestCreator: DigestCreator = DigestCreator(), saltProvider: SaltProvider, decoysLimit: Int = 0) {
    self.digestCreator = digestCreator
    self.saltProvider = saltProvider
    self.decoysLimit = decoysLimit
  }

  // MARK: - Methods - Public

  func createJWT(sdjwtObject: [String: SdElement]?) -> Result<ClaimSet, Error> {
    do {
      return .success(try self.encodeObject(sdjwtObject: addSdAlgClaim(object: sdjwtObject)))
    } catch {
      return .failure(error)
    }
  }

  // MARK: - Methods - Private

  private func encodeObject(sdjwtObject: [String: SdElement]?) throws -> ClaimSet {
    guard let sdjwtObject else {
      throw SDJWTError.nonObjectFormat(ofElement: sdjwtObject)
    }

    var outputDisclosures: [Disclosure] = []
    var outputJson = JSON()

    try sdjwtObject.forEach { claimKey, claimValue in
      var (json, disclosures) = try self.encodeClaim(key: claimKey, value: claimValue)
      outputDisclosures.append(contentsOf: disclosures)
      //      let (key, output) = mergeDictionaries(claimKey: claimKey, jsonToMerge: json, outputJson: outputJson)
      switch claimValue {
      case .flat, .recursiveArray, .recursiveObject:
        outputJson[Keys.sd.rawValue] = JSON(outputJson[Keys.sd].arrayValue + json[Keys.sd].arrayValue)
      default:
        outputJson[claimKey] = json
      }
    }

    return (outputJson, outputDisclosures)
  }

  private func encodeClaim(key: String, value: SdElement) throws -> ClaimSet {
    switch value {
    case .plain(let plain):
      return (plain, [])
      // ...........
    case .flat(let json):
      let (disclosure, digest) = try self.flatDisclose(key: key, value: json)
      var decoys = self.addDecoy()
      let output: JSON = [Keys.sd.rawValue: ([digest] + decoys).sorted()]
      return(output, [disclosure])
      // ...........
    case .object(let object):
      return try self.encodeObject(sdjwtObject: object)
      // ...........
    case .array(let array):
      var disclosures: [Disclosure] = []
      let output = try array.reduce(into: JSON([Disclosure]())) { partialResult, element in
        switch element {
        case .plain(let json):
          partialResult.arrayObject?.append(json)
        default:
          var (disclosure, digest) = try self.discloseArrayElement(value: element.asJSON)
          var decoys = self.addDecoy()
            .sorted()
            .map {JSON([Keys.dots.rawValue: $0])}
          let dottedKeyJson: JSON = [Keys.dots.rawValue: digest.sorted()]
          partialResult.arrayObject?.append(dottedKeyJson)
          partialResult.arrayObject?.append(contentsOf: decoys)
          disclosures.append(disclosure)
        }
      }

      return (output, disclosures)
      // ...........
    case .recursiveObject(let object):
      let encodedObject = try self.encodeObject(sdjwtObject: object)
      let sdElement = try self.encodeClaim(key: key, value: .flat(encodedObject.value))
      return (sdElement.value, encodedObject.disclosures + sdElement.disclosures)
      // ...........
    case .recursiveArray(let array):
      let encodedArray = try self.encodeClaim(key: key, value: .array(array))
      let sdElement = try self.encodeClaim(key: key, value: .flat(encodedArray.value))
      return (sdElement.value, encodedArray.disclosures + sdElement.disclosures)
      // ...........
    }
  }

  private func flatDisclose(key: String, value: JSON) throws -> (Disclosure, DisclosureDigest) {
    let saltString = saltProvider.saltString
    let jsonArray = JSON(arrayLiteral: saltString, key, value)
    let stringToEncode = try jsonArray
      .toJSONString(outputFormatting: .withoutEscapingSlashes)
    // TODO: Remove before flight
    //      .replacingOccurrences(of: ",", with: ", ")
    guard let urlEncoded = stringToEncode.toBase64URLEncoded(),
          let digest = digestCreator.hashAndBase64Encode(input: urlEncoded) else {
      throw SDJWTError.encodingError
    }

    return (urlEncoded, digest)
  }

  private func discloseArrayElement(value: JSON) throws -> (Disclosure, DisclosureDigest) {
    let saltString = saltProvider.saltString
    let jsonArray = JSON(arrayLiteral: saltString, value)
    let stringToEncode = try jsonArray
      .toJSONString(outputFormatting: .withoutEscapingSlashes)
    // TODO: Remove before flight
    //      .replacingOccurrences(of: ",", with: ", ")
    guard let urlEncoded = stringToEncode.toBase64URLEncoded(),
          let digest = digestCreator.hashAndBase64Encode(input: urlEncoded) else {
      throw SDJWTError.encodingError
    }

    return (urlEncoded, digest)
  }

  // MARK: - Methods - Helpers

  private func addDecoy() -> [DisclosureDigest] {
    if decoyCounter < decoysLimit {
      let rand = Array(repeating: "", count: .random(in: 0...decoysLimit-decoyCounter))
        .compactMap {_ in digestCreator.decoy()}

      decoyCounter += rand.count
      return rand
    }
    return []
  }

  private func addSdAlgClaim(object: [String: SdElement]?) -> [String: SdElement]? {
    var object = object
    object?[Keys.sdAlg.rawValue] = SdElement.plain(value: digestCreator.hashingAlgorithm.identifier)
    return object
  }
}
