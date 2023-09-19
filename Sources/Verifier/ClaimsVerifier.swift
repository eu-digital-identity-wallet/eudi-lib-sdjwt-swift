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

class ClaimsVerifier: VerifierProtocol {

  // MARK: - Properties
  var iat: Date?
  var iatValidWindow: TimeRange?

  var nbf: Date?
  var exp: Date?

  var audClaim: JSON?
  var expectedAud: String?

  let currentDate: Date
  // MARK: - Lifecycle

  init(iat: Int? = nil,
       iatValidWindow: TimeRange? = nil,
       nbf: Int? = nil,
       exp: Int? = nil,
       audClaim: String? = nil,
       expectedAud: String? = nil,
       currentDate: Date = Date()) {

    if let iat {
      self.iat = Date(timeIntervalSince1970: TimeInterval(iat))
    }
    if let nbf {
      self.nbf = Date(timeIntervalSince1970: TimeInterval(nbf))
    }
    if let exp {
      self.exp = Date(timeIntervalSince1970: TimeInterval(exp))
    }

    self.audClaim = JSON(parseJSON: audClaim ?? "")
    self.expectedAud = expectedAud
    self.currentDate = currentDate
  }

  // MARK: - Methods
  @discardableResult
  func verify() throws -> Bool {
    if let iat,
       let iatValidWindow,
       iatValidWindow.contains(date: iat) {
      throw SDJWTVerifierError.invalidJwt
    }

    if let nbf {
      try self.verifyNotBefore(nbf: nbf)
    }

    if let exp {
      try self.verifyNotExpired(exp: exp)
    }

    if let expectedAud,
       let audClaim {
      try self.verifyAud(aud: audClaim, expectedAudience: expectedAud)
    }

    return true
  }

  private func verifyNotBefore(nbf: Date) throws {
    switch nbf.compare(currentDate) {
    case .orderedDescending:
      throw SDJWTVerifierError.notValidYetJwt
    case .orderedAscending, .orderedSame:
      break
    }
  }

  private func verifyNotExpired(exp: Date) throws {
    switch exp.compare(currentDate) {
    case .orderedAscending, .orderedSame:
      throw SDJWTVerifierError.expiredJwt
    case .orderedDescending:
      break
    }
  }

  func verifyAud(aud: JSON, expectedAudience: String) throws {
    if let array = aud.array {
      guard array
        .compactMap({$0.stringValue})
        .contains(where: { $0 == expectedAudience} )
      else {
        throw SDJWTVerifierError.keyBindingFailed(description: "Expected Audience Missmatch")
      }
    } else if let string = aud.string {
      guard string == expectedAudience else {
        throw SDJWTVerifierError.keyBindingFailed(description: "Expected Audience Missmatch")
      }
    }
  }
}
