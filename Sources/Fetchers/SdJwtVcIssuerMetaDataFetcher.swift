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
import JSONWebKey

public protocol SdJwtVcIssuerMetaDataFetching {
  var session: Networking { get }
  func fetchIssuerMetaData(issuer: URL) async throws -> SdJwtVcIssuerMetaData?
}

public class SdJwtVcIssuerMetaDataFetcher: SdJwtVcIssuerMetaDataFetching {
  
  public let session: Networking
  
  public init(session: Networking) {
    self.session = session
  }
  
  public func fetchIssuerMetaData(issuer: URL) async throws -> SdJwtVcIssuerMetaData? {
    let issuerMetadataUrl = issuerMetadataUrl(for: issuer)
    let metadata: SdJwtVcIssuerMetadataTO = try await fetch(
      from: issuerMetadataUrl,
      with: session
    )
    
    guard issuer == URL(string: metadata.issuer) else {
      throw SDJWTVerifierError.invalidJwt
    }
    
    try xorValues(metadata.jwksUri, metadata.jwks)
    
    if let jwks = metadata.jwks {
      return .init(
        issuer: issuer,
        jwks: jwks.keys
      )
    } else if metadata.jwksUri != nil {
      let jwks: JWKSet = try await fetch(
        from: issuerMetadataUrl,
        with: session
      )
      return .init(
        issuer: issuer,
        jwks: jwks.keys
      )
    }
    
    return nil
  }
}

private extension SdJwtVcIssuerMetaDataFetcher {
  private func issuerMetadataUrl(for issuer: URL) -> URL {
    var components = URLComponents(url: issuer, resolvingAgainstBaseURL: false)!
    components.path = "/.well-known/jwt-vc-issuer" + components.path
    return components.url!
  }
  
  func fetch<T: Decodable>(from url: URL, with session: Networking) async throws -> T {
    
    let (data, response) = try await session.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
    
    // Decode the JSON data into the Codable struct
    let decoder = JSONDecoder()
    let metadata = try decoder.decode(T.self, from: data)
    
    return metadata
  }
  
  func xorValues(_ first: Any?, _ second: Any?) throws {
    // Ensure that one is non-nil and the other is nil, but not both non-nil or both nil
    guard (first != nil) != (second != nil) else {
      throw SDJWTVerifierError.invalidJwt
    }
  }
}
