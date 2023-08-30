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

/// Building block for the SD-JWT
protocol ClaimRepresentable: Encodable {

  var key: String { get set }
  var value: SdElement { get set }

  func checkKeyValidity() throws -> Result<Bool, SDJWTError>
}

struct ConstantClaims: ClaimRepresentable {
  // MARK: - Properties

  var key: String
  var value: SdElement

  // MARK: - Lifecycle

  private init(_ key: String, value: SdElement) {
    self.key = key
    self.value = value
  }

  // MARK: - Methods

  static func iat(time: Date) -> ConstantClaims {
    let currentDate = Date()
    let timestamp = Int(currentDate.timeIntervalSince1970.rounded())

    return ConstantClaims(Keys.iat.rawValue, value: .plain(value: timestamp))
  }

  static func exp(time: Date) -> ConstantClaims {
    let timestamp = Int(time.timeIntervalSince1970.rounded())

    return ConstantClaims(Keys.exp.rawValue, value: .plain(value: timestamp))
  }

  static func iss(domain: String) -> ConstantClaims {
    return ConstantClaims(Keys.iss.rawValue, value: .plain(value: domain))
  }

}

extension ClaimRepresentable {

  // MARK: - helpers

  var flatString: String {
    guard let string = self.value.jsonString else {
      return ""
    }
    return string
  }

  @discardableResult
  func checkKeyValidity() -> Result<Bool, SDJWTError> {
    guard
      key != Keys.sd.rawValue,
      key != Keys.sdAlg.rawValue else {
      return .failure(.sdAsKey)
    }
    return .success(true)
  }
  // MARK: - Encodable

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: RawCodingKey.self)
    try container.encode(self.value, forKey: .init(string: self.key))
  }

}
