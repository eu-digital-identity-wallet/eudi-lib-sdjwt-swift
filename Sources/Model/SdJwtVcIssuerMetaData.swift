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
@preconcurrency import JSONWebKey
import SwiftyJSON

struct SdJwtVcIssuerMetadataTO: Decodable, Sendable {
  let issuer: String
  let jwksUri: String?
  let jwks: JWKSet?
  
  enum CodingKeys: String, CodingKey {
    case issuer
    case jwksUri = "jwks_uri"
    case jwks
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    issuer = try container.decode(String.self, forKey: .issuer)
    jwksUri = try container.decodeIfPresent(String.self, forKey: .jwksUri)
    
    if let jwksData = try container.decodeIfPresent(JWKSet.self, forKey: .jwks) {
      jwks = jwksData
    } else {
      jwks = nil
    }
  }
}

public struct SdJwtVcIssuerMetaData {
  public let issuer: URL
  public let jwks: [JWK]
  
  public init(issuer: URL, jwks: [JWK]) {
    self.issuer = issuer
    self.jwks = jwks
  }
}
