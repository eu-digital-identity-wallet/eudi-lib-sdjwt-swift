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

public enum JwsJsonSupportOption {
  
  case general, flattened
  
  private static let JWS_JSON_HEADER = "header"
  private static let JWS_JSON_DISCLOSURES = "disclosures"
  private static let JWS_JSON_KB_JWT = "kb_jwt"
  private static let JWS_JSON_PROTECTED = "protected"
  private static let JWS_JSON_SIGNATURE = "signature"
  private static let JWS_JSON_SIGNATURES = "signatures"
  private static let JWS_JSON_PAYLOAD = "payload"
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
        Self.JWS_JSON_HEADER: JSONObject {
          [
            Self.JWS_JSON_DISCLOSURES: JSONArray {
              disclosures.map { JSON($0) }
            },
            Self.JWS_JSON_KB_JWT: kbJwt == nil ? nil : JSON(kbJwt!)
          ]
        },
        Self.JWS_JSON_PROTECTED: JSON(protected),
        Self.JWS_JSON_SIGNATURE: JSON(signature)
      ]
    }
    
    switch self {
    case .general:
      return JSONObject {
        [
          Self.JWS_JSON_PAYLOAD: JSON(payload),
          Self.JWS_JSON_SIGNATURES: JSONArray {
            [headersAndSignature]
          }
        ]
      }
    case .flattened:
      return JSONObject {
        [
          Self.JWS_JSON_PAYLOAD: JSON(payload),
        ]
        headersAndSignature
      }
    }
  }
}


