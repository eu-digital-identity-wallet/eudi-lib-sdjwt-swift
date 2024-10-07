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
import JSONWebSignature

fileprivate let JWS_JSON_HEADER = "header"
fileprivate let JWS_JSON_DISCLOSURES = "disclosures"
fileprivate let JWS_JSON_KB_JWT = "kb_jwt"
fileprivate let JWS_JSON_PROTECTED = "protected"
fileprivate let JWS_JSON_SIGNATURE = "signature"
fileprivate let JWS_JSON_SIGNATURES = "signatures"
fileprivate let JWS_JSON_PAYLOAD = "payload"

public enum JwsJsonSupportOption {
  case general, flattened
}

internal extension JwsJsonSupportOption {
  
  func buildJwsJson(
    protected: String,
    payload: String,
    signature: String,
    disclosures: Set<String>,
    kbJwt: JWTString?
  ) -> JSON {
    let headersAndSignature = JSONObject {
      [
        JWS_JSON_HEADER: JSONObject {
          [
            JWS_JSON_DISCLOSURES: JSONArray {
              disclosures.map { JSON($0) }
            },
            JWS_JSON_KB_JWT: kbJwt == nil ? nil : JSON(kbJwt!)
          ]
        },
        JWS_JSON_PROTECTED: JSON(protected),
        JWS_JSON_SIGNATURE: JSON(signature)
      ]
    }
    
    switch self {
    case .general:
      return JSONObject {
        [
          JWS_JSON_PAYLOAD: JSON(payload),
          JWS_JSON_SIGNATURES: JSONArray {
            [headersAndSignature]
          }
        ]
      }
    case .flattened:
      return JSONObject {
        [
          JWS_JSON_PAYLOAD: JSON(payload),
        ]
        headersAndSignature
      }
    }
  }
}

internal class JwsJsonSupport {
  
  static func parseJWSJson(unverifiedSdJwt: JSON) throws -> (jwt: JWS, disclosures: [String], kbJwt: JWS?) {
    
    let signatureContainer: JSON = unverifiedSdJwt[JWS_JSON_SIGNATURES]
      .array?
      .first ?? unverifiedSdJwt
    
    let unverifiedJwt = try createUnverifiedJwt(
      signatureContainer: signatureContainer,
      unverifiedSdJwt: unverifiedSdJwt
    )
    
    let unprotectedHeader = extractUnprotectedHeader(from: signatureContainer)
    
    return try extractUnverifiedValues(
      unprotectedHeader: unprotectedHeader,
      unverifiedJwt: unverifiedJwt
    )
  }
  
  static private func createUnverifiedJwt(signatureContainer: JSON, unverifiedSdJwt: JSON) throws -> String {
    guard let protected = signatureContainer[JWS_JSON_PROTECTED].string else {
      throw SDJWTVerifierError.invalidJwt
    }
    
    guard let signature = signatureContainer[JWS_JSON_SIGNATURE].string else {
      throw SDJWTVerifierError.invalidJwt
    }
    
    guard let payload = unverifiedSdJwt[JWS_JSON_PAYLOAD].string else {
      throw SDJWTVerifierError.invalidJwt
    }
    
    return "\(protected).\(payload).\(signature)"
  }
  
  static private func extractUnprotectedHeader(from signatureContainer: JSON) -> JSON? {
    if let jsonObject = signatureContainer[JWS_JSON_HEADER].dictionary {
      return JSON(jsonObject)
    }
    return nil
  }
  
  static func extractUnverifiedValues(unprotectedHeader: JSON?, unverifiedJwt: String) throws -> (JWS, [String], JWS?) {
    
    let unverifiedDisclosures: [String] = unprotectedHeader?[JWS_JSON_DISCLOSURES]
      .array?
      .compactMap { element in
        return element.string
      } ?? []
    
    let jws: JWS? = if let unverifiedKBJwt = unprotectedHeader?[JWS_JSON_KB_JWT].string {
      try JWS(jwsString: unverifiedKBJwt)
    } else {
      nil
    }
    
    return (
      try JWS(jwsString: unverifiedJwt),
      unverifiedDisclosures,
      jws
    )
  }
}


