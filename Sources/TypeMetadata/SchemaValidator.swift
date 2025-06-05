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

import SwiftyJSON
import Foundation
import JSONSchema

package protocol SchemaValidatorType {
  func validate(_ payload: JSON, _ schemas: [JSON]) throws
}

struct SchemaValidator: SchemaValidatorType {
  func validate(
    _ payload: JSON,
    _ schemas: [JSON]
  ) throws {
    
    guard let payloadDict = payload.dictionaryObject else {
      throw TypeMetadataError.invalidPayload
    }
    
    for schemaJSON in schemas {
      guard let schemaDict = schemaJSON.dictionaryObject else {
        throw TypeMetadataError.invalidSchema
      }
      
      let result = try JSONSchema.validate(payloadDict, schema:schemaDict )
      
      switch result {
      case .valid:
        continue
      case .invalid(let errors):
        throw TypeMetadataError.schemaValidationFailed(description: errors.map(\.description).joined(separator: ", "))
      }
    }
  }
}
