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
import JSONSchema

@testable import eudi_lib_sdjwt_swift


struct SchemaValidator: SchemaValidatorType {
  func validate(
    _ payload: JSON,
    _ schemas: [JSON]
  ) throws {
    
    guard #available(iOS 16.0, *) else {
      throw TypeMetadataError.schemaValidationFailed(
        description: "Schema validation requires iOS 16 and above"
      )
    }
    
    // Convert payload JSON to String
    guard let payloadString = payload.stringified else {
      throw TypeMetadataError.invalidPayload
    }
    
    for schemaJSON in schemas {
      guard let schemaString = schemaJSON.stringified else {
        throw TypeMetadataError.invalidSchema
      }
      
      let schema = try Schema(instance: schemaString)
      let result = try schema.validate(instance: payloadString)
      
      if !result.isValid {
        let descriptions = (result.errors?.flatMap { flattenErrors($0) } ?? [])
          .map { "\($0.message) at \($0.instanceLocation)" }
          .joined(separator: ", ")
        
        throw TypeMetadataError.schemaValidationFailed(description: descriptions)
      }
    }
  }

    private func flattenErrors(_ error: ValidationError) -> [ValidationError] {
    var all: [ValidationError] = [error]
    if let nested = error.errors {
      all += nested.flatMap(flattenErrors)
    }
    return all
  }
}
