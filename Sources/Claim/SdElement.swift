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

public typealias SDJWTObject = [String: SdElement]

public enum SdElement: Encodable {
  // Basic Building Blocks
  case object([String: SdElement])
  case plain(JSON)
  case flat(JSON)
  case array([SdElement])

  // Advanced UseCases
  //  case structuredObject([String: SdElement])
  case recursiveObject([String: SdElement])
  case recursiveArray([SdElement])

  private init(sdElement: SdElement) {
    self = sdElement
  }

  // MARK: - Builder Methods
  // so we don't expose external dependencies to separate classes

  static func plain(value: Any) -> SdElement {
    return SdElement.plain(JSON(value))
  }

  static func flat(value: Any) -> SdElement {
    return SdElement.flat(JSON(value))
  }

  static func object(@SDJWTBuilder _ builder: () -> SdElement) -> SdElement {
    return SdElement.object(builder().asObject ?? [:])
  }

  static func array(@SDJWTArrayBuilder _ builder: () -> [SdElement]) -> SdElement {
    return SdElement.array(builder())
  }

  // MARK: - Encodable

  public func encode(to encoder: Encoder) {
    switch self {
    case .object(let object), .recursiveObject(let object):
      try? object.encode(to: encoder)
    case .plain(let plain):
      try? plain.encode(to: encoder)
    case .flat(let flat):
      try? flat.encode(to: encoder)
    case .array(let array), .recursiveArray(let array):
      try? array.encode(to: encoder)
    }
  }
}

extension SdElement {

  // MARK: - Helpers

  var jsonString: String? {
    try? self.toJSONString()
  }

  var asObject: SDJWTObject? {
    switch self {
    case .object(let object), .recursiveObject(let object):
      return object
    default:
      return nil
    }
  }

  var asJSON: JSON {
    switch self {
    case .object(let object), .recursiveObject(let object):
      return JSON(object.mapValues({$0.asJSON}))
    case .plain(let primitive), .flat(let primitive):
      return primitive
    case .array(let array), .recursiveArray(let array):
      return JSON(array.map({$0.asJSON}))
    }
  }
}
