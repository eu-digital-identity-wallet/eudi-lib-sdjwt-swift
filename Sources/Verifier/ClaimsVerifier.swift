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

public class ClaimsVerifier: VerifierProtocol {
  
  // MARK: - Properties
  let iat: Date?
  let iatValidWindow: TimeRange?
  
  let nbf: Date?
  let exp: Date?
  
  let auds: [String]?
  let expectedAud: String?
  
  let currentDate: Date
  
  // MARK: - Lifecycle
  
  public init(
    iat: Int? = nil,
    iatValidWindow: TimeRange? = nil,
    nbf: Int? = nil,
    exp: Int? = nil,
    audClaim: String? = nil,
    expectedAud: String? = nil,
    currentDate: Date = Date()) {
      self.iat = Date(timestamp: iat)
      self.iatValidWindow = iatValidWindow
      self.nbf = Date(timestamp: nbf)
      self.exp = Date(timestamp: exp)
      self.auds = {
        guard let audClaim else { return nil }
        /**
         Try to parse string as JSON array of strings, which may come from `JWS.aud()` function.
         */
        let audArray = JSON(parseJSON: audClaim)
        return audArray == JSON.null ? [audClaim] : audArray.array?.compactMap { $0.stringValue }
      }()
      self.expectedAud = expectedAud
      self.currentDate = currentDate
    }
  
  // MARK: - Methods
  @discardableResult
  public func verify() throws -> Bool {
    if let iat,
       let iatValidWindow,
       !iatValidWindow.contains(date: iat) {
      throw SDJWTVerifierError.invalidJwt
    }
    
    if let nbf {
      try self.verifyNotBefore(nbf: nbf)
    }
    
    if let exp {
      try self.verifyNotExpired(exp: exp)
    }
    
    if let expectedAud,
       let auds {
      try self.verifyAud(audiences: auds, expectedAudience: expectedAud)
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
  
  func verifyAud(audiences: [String], expectedAudience: String) throws {
    guard audiences.contains(expectedAudience) else {
      throw SDJWTVerifierError.keyBindingFailed(description: "Expected Audience Missmatch")
    }
  }
}

private extension Date {
  init?(timestamp: Int?) {
    guard let timestamp else { return nil }
    self.init(timeIntervalSince1970: TimeInterval(timestamp))
  }
}
