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

public class EnvelopedParser: ParserProtocol {

  // MARK: - Properties
  
  let compactParser: ParserProtocol
  
  // MARK: - Lifecycle

  public init(
    compactParser: ParserProtocol = CompactParser()
  ) {
    self.compactParser = compactParser
  }

  // MARK: - Methods

  public func getSignedSdJwt(using serialiserProtocol: any SerialiserProtocol) throws -> SignedSDJWT {
    let jsonDecoder = JSONDecoder()
    let envelopedJwt = try jsonDecoder.decode(EnvelopedJwt.self, from: serialiserProtocol.data)
    return try compactParser.getSignedSdJwt(serialisedString: envelopedJwt.sdJwt)
  }
  
  public func getSignedSdJwt(serialisedString: String) throws -> SignedSDJWT {
    let jsonDecoder = JSONDecoder()
    let envelopedJwt = try jsonDecoder.decode(
      EnvelopedJwt.self, from: serialisedString.data(using: .utf8) ?? Data()
    )
    return try compactParser.getSignedSdJwt(serialisedString: envelopedJwt.sdJwt)
  }
  
  public func fromJwsJsonObject(_ json: JSON) throws -> SignedSDJWT {
    guard let compactString = try? (compactParser as? CompactParser)?.stringFromJwsJsonObject(json) else {
      throw SDJWTVerifierError.parsingError
    }
    return try compactParser.getSignedSdJwt(serialisedString: compactString)
  }
}

public struct EnvelopedJwt: Codable {
    let aud: String
    let iat: Int
    let nonce: String
    let sdJwt: String

    enum CodingKeys: String, CodingKey {
        case aud
        case iat
        case nonce
        case sdJwt = "_sd_jwt"
    }
}
