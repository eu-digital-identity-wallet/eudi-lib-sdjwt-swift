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

import XCTest

@testable import eudi_lib_sdjwt_swift

final class SignedJwtTest: XCTestCase {
  func testSignedJwt() {
    @SDJWTBuilder
    var plainJWT: SdElement {
      // Constant claims
      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date().addingTimeInterval(3600))
      ConstantClaims.iss(domain: "https://example.com/issuer")
      // Payload
      FlatDisclosedClaim("string", "name")
      FlatDisclosedClaim("number", 36524)
      FlatDisclosedClaim("bool", true)
      FlatDisclosedClaim("array", ["GR", "DE"])
    }

    let factory = SDJWTFactory(saltProvider: DefaultSaltProvider())
    
    validateObjectResults(factoryResult: factory.createJWT(sdjwtObject: plainJWT.asObject), expectedDigests: plainJWT.expectedDigests)
  }
}
