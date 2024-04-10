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
public protocol ClaimRepresentable: Encodable {

  var key: String { get set }
  var value: SdElement { get set }

  func checkKeyValidity() -> Result<Bool, SDJWTError>
}

public struct ConstantClaims: ClaimRepresentable {

  // MARK: - Properties

  public var key: String
  public var value: SdElement

  // MARK: - Lifecycle

  public init(_ key: String, value: SdElement) {
    self.key = key
    self.value = value
  }

  // MARK: - Methods

  public static func iat(time: Date) -> ConstantClaims {
    let currentDate = Date()
    let timestamp = Int(currentDate.timeIntervalSince1970.rounded())

    return ConstantClaims(Keys.iat.rawValue, value: .plain(value: timestamp))
  }

  public static func exp(time: Date) -> ConstantClaims {
    let timestamp = Int(time.timeIntervalSince1970.rounded())

    return ConstantClaims(Keys.exp.rawValue, value: .plain(value: timestamp))
  }

  public static func nbf(time: Date) -> ConstantClaims {
    let timestamp = Int(time.timeIntervalSince1970.rounded())

    return ConstantClaims(Keys.nbf.rawValue, value: .plain(value: timestamp))
  }

  public static func iat(time: TimeInterval) -> ConstantClaims {
    return ConstantClaims(Keys.iat.rawValue, value: .plain(value: Int(time.rounded())))
  }

  public static func exp(time: TimeInterval) -> ConstantClaims {
    return ConstantClaims(Keys.exp.rawValue, value: .plain(value: Int(time.rounded())))
  }

  public static func iss(domain: String) -> ConstantClaims {
    return ConstantClaims(Keys.iss.rawValue, value: .plain(value: domain))
  }

  public static func sub(subject: String) -> ConstantClaims {
    return ConstantClaims(Keys.sub.rawValue, value: .plain(value: subject))
  }
}

extension ClaimRepresentable {

  // MARK: - helpers

  var flatString: String? {
    return self.value.jsonString
  }

  @discardableResult
  public func checkKeyValidity() -> Result<Bool, SDJWTError> {
    guard
      key != Keys.sd.rawValue,
      key != Keys.dots.rawValue else {
      // https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-05.html#section-5.1
      return .failure(.sdAsKey)
    }
    return .success(true)
  }
  // MARK: - Encodable

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: RawCodingKey.self)
    try container.encode(self.value, forKey: .init(string: self.key))
  }

}
