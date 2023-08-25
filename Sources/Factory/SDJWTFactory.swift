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

class SDJWTFactory {

  // MARK: - Properties

  let digestCreator: DigestCreator
  let saltProvider: SaltProvider

  // MARK: - LifeCycle

  init(digestCreator: DigestCreator = DigestCreator(), saltProvider: SaltProvider) {
    self.digestCreator = digestCreator
    self.saltProvider = saltProvider
  }

  func createJWT(sdjwtObject: [String: SdElement]?) -> Result<(JSON, [Disclosure]), Error> {
    do {
      return .success(try self.encodeObject(sdjwtObject: sdjwtObject))
    } catch {
      return .failure(error)
    }
  }

  // MARK: - Methods

  private func encodeObject(sdjwtObject: [String: SdElement]?) throws -> (JSON, [Disclosure]) {
    guard let sdjwtObject else {
      throw SDJWTError.NonObjectFormat(ofElement: sdjwtObject)
    }

    var disclosures: [Disclosure] = []
    var outputJson = JSON()

    try sdjwtObject.forEach { key, claimValue in
      let (json, disclosure) = try self.encodeClaim(key: key, value: claimValue)
      disclosures.appendOptional(disclosure)

      let previousSdElement = outputJson[Keys._sd.rawValue]
      let currentObjectSdArray = json[Keys._sd.rawValue]
      
      if previousSdElement.exists(), currentObjectSdArray.exists() {
        outputJson[Keys._sd.rawValue] = try previousSdElement.merged(with: currentObjectSdArray)
      }
      else if currentObjectSdArray.exists() {
        outputJson[Keys._sd.rawValue] = currentObjectSdArray
      } else {
        outputJson[key] = json
      }
    }

    return (outputJson, disclosures)
  }

  private func encodeClaim(key: String, value: SdElement) throws -> (JSON, Disclosure?) {
    switch value {
    case .plain(let plain):
      return (plain, nil)
      //...........
    case .flat(let json):
      let (disclosure, digest) = try self.flatDisclose(key: key, value: json)
      let output: JSON = [Keys._sd.rawValue: [digest]]
      return(output, disclosure)
      //...........
    case .object(_):
      return (JSON(), nil)
      //...........
    case .array(_):
      return (JSON(), nil)
      //...........
    case .structuredObject:
      return (JSON(), nil)
      //...........
    case .recursiveObject:
      return (JSON(), nil)
      //...........
    case .recursiveArray:
      return (JSON(), nil)
      //...........
    }
  }

  private func mergeSdArrays(merge: (String) -> ()) {

  }

  private func flatDisclose(key: String, value: JSON) throws -> (Disclosure, DisclosureDigest) {
    let saltString = saltProvider.saltString
    let jsonArray = JSON(arrayLiteral: saltString, key, value)
    let stringToEncode = try jsonArray
      .toJSONString(outputFormatting: .withoutEscapingSlashes)
      .replacingOccurrences(of: ",", with: ", ")
    guard let urlEncoded = stringToEncode.toBase64URLEncoded(),
          let digest = digestCreator.hashAndBase64Encode(input: urlEncoded) else {
      throw SDJWTError.encodingError
    }

    return (urlEncoded, digest)
  }

}

