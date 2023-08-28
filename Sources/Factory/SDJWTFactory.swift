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

  // MARK: - LifeCycle

  init(digestCreator: DigestCreator = DigestCreator(), saltProvider: SaltProvider) {
    self.digestCreator = digestCreator
    self.saltProvider = saltProvider
  }

  func createJWT(sdjwtObject: [String: SdElement]?) -> Result<ClaimSet, Error> {
    do {
      return .success(try self.encodeObject(sdjwtObject: sdjwtObject))
    } catch {
      return .failure(error)
    }
  }

  // MARK: - Methods

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
        outputJson["_sd"] = JSON(outputJson["_sd"].arrayValue + json["_sd"].arrayValue)
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
      let output: JSON = [Keys._sd.rawValue: [digest]]
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
          let (disclosure, digest) = try self.discloseArrayElement(value: element.asJSON)
          let dottedKeyJson: JSON = [Keys.dots.rawValue: digest]
          partialResult.arrayObject?.append(dottedKeyJson)
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
}
