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

import Foundation
import SwiftyJSON
import XCTest

@testable import eudi_lib_sdjwt_swift

final class VerifierTest: XCTestCase {
  func testVerifier() throws {
    var keyPair = generateES256KeyPair()

    let string = "eyJhbGciOiJFUzI1NiJ9.eyJjbmYiOnsiY3J2IjoiUC0yNTYiLCJ5IjoialNqclVVRlREdW90T2dCblFjbUxTQVF2TnVmaVNVdUFOd19BNDZLZ0tJTSIsImt0eSI6IkVDIiwieCI6IjhGemxvWHF2bW82RE5ZdVVTZUpqUmZ0N1QtaU1nWmRsX2otUUdaQTV1TzQifSwiX3NkIjpbImJ3VUJFZEFNNWo2SDdmeEVlUWdmOFVWQlV1bjMwRENRVFN4azVzUWhaU2ciLCJfVXd3amlmQmNpaC00NFc5b01TaGF2bFdoMFF0WE9nT21lQTMxNmZxTnYwIl0sImlzcyI6Imh0dHBzOlwvXC9leGFtcGxlLmNvbVwvaXNzdWVyIiwiZXhwIjoxNjkzOTkxNjM3LCJpYXQiOjE2OTM5ODgwMzcsIl9zZF9hbGciOiJzaGEtMjU2In0.britNkDZ9XRqq9ocPa4y2eTH2mz-YHzn1WB_EBDexU3D_XR9Cd90ewounxVVuNvy5KOKNRqE2-T-RUdF24JOgw~WyJENkV6eUlKYm13UUE4eG9zaTVmMHNnIiwiZ2l2ZW5fbmFtZSIsIuWkqumDjiJd~WyJKVEI5ajlFeGNzc1pnTlJYX1pQZmdRIiwic3ViIiwiNmM1YzBhNDktYjU4OS00MzFkLWJhZTctMjE5MTIyYTllYzJjIl0~eyJhbGciOiJFUzI1NiJ9.eyJpYXQiOjE2OTM5ODgwMzYuNzUxMTkxMSwibm9uY2UiOiIxMjM0NTY3ODkwIiwiYXVkIjoiaHR0cHM6XC9cL2V4YW1wbGUuY29tXC92ZXJpZmllciJ9.w0w8iK5idQdZVJj-Aj6HmJsdX5CUwEbLXOQBUdKqu61vQVyGMzNnQazN3DBRRLeyGZjQ1Hs5BPy0DtuWDWRrzQ"

    let verifier = SdJwtVerifier()

    let parser = Parser(serialisedString: string, serialisationFormat: .serialised)
    let result = try verifier.verify(parser: parser) {
      return try SignatureVerifier(signedJWT: parser.getSignedSdJwt().jwt, publicKey: keyPair.public)
    } disclosuresVerifier: {

    }

    XCTAssert(Result<(), Error>.success(()) == result)
  }
}
