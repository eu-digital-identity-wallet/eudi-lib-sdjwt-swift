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

/** A protocol for validating a JSON payload against one or more JSON Schemas. */
public protocol SchemaValidatorType {
  
  /**
   Validates a payload against a set of JSON schemas.
   
   - Parameters:
   - payload: The JSON document to validate.
   - schemas: An array of JSON Schema definitions.
   - Throws: A `TypeMetadataError` if the payload or schemas are invalid or do not match.
   */
  func validate(_ payload: JSON, _ schemas: [JSON]) throws
}


