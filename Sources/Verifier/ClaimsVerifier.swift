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

class ClaimsVerifier: VerifierProtocol {

  // MARK: - Properties
  var iat: Date?
  var iatValidWindow: TimeRange?

  var nbf: Date?
  var exp: Date?

  let currentDate: Date
  // MARK: - Lifecycle

  init(iat: Int? = nil,
       iatValidWindow: TimeRange? = nil,
       nbf: Int? = nil,
       exp: Int? = nil,
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
    self.currentDate = currentDate
  }

  // MARK: - Methods

  func verify() throws -> Bool {
    if let iat,
       let iatValidWindow,
       !isDateInTimeRange(dateToCheck: iat, startTime: iatValidWindow.startTime, endTime: iatValidWindow.endTime) {
      throw SDJWTVerifierError.invalidJwt
    }

    if let nbf {
      try self.verifyNotBefore(nbf: nbf)
    }

    if let exp {
      try self.verifyNotExpired(exp: exp)
    }

    return true
  }

  func isDateInTimeRange(dateToCheck: Date, startTime: Date, endTime: Date?) -> Bool {
    if let endTime {
      return dateToCheck >= startTime && dateToCheck <= endTime
    } else {
      return dateToCheck == startTime
    }

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
}
