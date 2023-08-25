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

    var outputDisclosures: [Disclosure] = []
    var outputJson = JSON([:])

    try sdjwtObject.forEach { key, claimValue in
      var (json, disclosures) = try self.encodeClaim(key: key, value: claimValue)
      outputDisclosures.append(contentsOf: disclosures)

      
      if json["_sd"].arrayValue.isEmpty {
        outputJson[key] = json
      } else {
        json.dictionaryObject?.removeValue(forKey: key)
        outputJson[key] = json
        let prevArray = outputJson["_sd"].arrayValue
        let claims = prevArray + json["_sd"].arrayValue
        outputJson["_sd"].arrayObject = claims
      }
      

    }

    return (outputJson, outputDisclosures)
  }

  private func encodeClaim(key: String, value: SdElement) throws -> (JSON, [Disclosure]) {
    switch value {
    case .plain(let plain):
      return (plain, [])
      //...........
    case .flat(let json):
      let (disclosure, digest) = try self.flatDisclose(key: key, value: json)
      let output: JSON = [Keys._sd.rawValue: [digest]]
      return(output, [disclosure])
      //...........
    case .object(let object):
      return try self.encodeObject(sdjwtObject: object)
      //...........
    case .array(_):
      return (JSON(), [])
      //...........
    case .structuredObject:
      return (JSON(), [])
      //...........
    case .recursiveObject:
      return (JSON(), [])
      //...........
    case .recursiveArray:
      return (JSON(), [])
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

