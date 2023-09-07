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
import JOSESwift
import XCTest

@testable import eudi_lib_sdjwt_swift

final class VerifierTest: XCTestCase {
  func testVerifier() throws {
    let key =
      """
      {
        "kty": "EC",
        "crv": "P-256",
        "x": "b28d4MwZMjw8-00CG4xfnn9SLMVMM19SlqZpVb_uNtQ",
        "y": "Xv5zWwuoaTgdS6hV43yI6gBwTnjukmFQQnJ_kCxzqk8"
      }
      """
      .replacingOccurrences(of: "\n", with: "")
      .replacingOccurrences(of: " ", with: "")

    var pk = try! ECPublicKey(data: JSON(parseJSON: key).rawData())
    // Copied from Spec https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-05.html#name-example-3-complex-structure
    let ComplexStructureSDJWTString =
                """
                eyJhbGciOiAiRVMyNTYifQ.eyJfc2QiOiBbIi1hU3puSWQ5bVdNOG9jdVFvbENsbHN4V
                mdncTEtdkhXNE90bmhVdFZtV3ciLCAiSUticllObjN2QTdXRUZyeXN2YmRCSmpERFVfR
                XZRSXIwVzE4dlRScFVTZyIsICJvdGt4dVQxNG5CaXd6TkozTVBhT2l0T2w5cFZuWE9hR
                UhhbF94a3lOZktJIl0sICJpc3MiOiAiaHR0cHM6Ly9leGFtcGxlLmNvbS9pc3N1ZXIiL
                CAiaWF0IjogMTY4MzAwMDAwMCwgImV4cCI6IDE4ODMwMDAwMDAsICJ2ZXJpZmllZF9jb
                GFpbXMiOiB7InZlcmlmaWNhdGlvbiI6IHsiX3NkIjogWyI3aDRVRTlxU2N2REtvZFhWQ
                3VvS2ZLQkpwVkJmWE1GX1RtQUdWYVplM1NjIiwgInZUd2UzcmFISUZZZ0ZBM3hhVUQyY
                U14Rno1b0RvOGlCdTA1cUtsT2c5THciXSwgInRydXN0X2ZyYW1ld29yayI6ICJkZV9hb
                WwiLCAiZXZpZGVuY2UiOiBbeyIuLi4iOiAidFlKMFREdWN5WlpDUk1iUk9HNHFSTzV2a
                1BTRlJ4RmhVRUxjMThDU2wzayJ9XX0sICJjbGFpbXMiOiB7Il9zZCI6IFsiUmlPaUNuN
                l93NVpIYWFka1FNcmNRSmYwSnRlNVJ3dXJSczU0MjMxRFRsbyIsICJTXzQ5OGJicEt6Q
                jZFYW5mdHNzMHhjN2NPYW9uZVJyM3BLcjdOZFJtc01vIiwgIldOQS1VTks3Rl96aHNBY
                jlzeVdPNklJUTF1SGxUbU9VOHI4Q3ZKMGNJTWsiLCAiV3hoX3NWM2lSSDliZ3JUQkppL
                WFZSE5DTHQtdmpoWDFzZC1pZ09mXzlsayIsICJfTy13SmlIM2VuU0I0Uk9IbnRUb1FUO
                EptTHR6LW1oTzJmMWM4OVhvZXJRIiwgImh2RFhod21HY0pRc0JDQTJPdGp1TEFjd0FNc
                ERzYVUwbmtvdmNLT3FXTkUiXX19LCAiX3NkX2FsZyI6ICJzaGEtMjU2In0.Xtpp8nvAq
                22k6wNRiYHGRoRnkn3EBaHdjcaa0sf0sYjCiyZnmSRlxv_C72gRwfVQkSA36ID_I46QS
                TZvBrgm3g~WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgInRpbWUiLCAiMjAxMi0wNC
                0yM1QxODoyNVoiXQ~WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgeyJfc2QiOiBbIjl
                3cGpWUFd1RDdQSzBuc1FETDhCMDZsbWRnVjNMVnliaEh5ZFFwVE55TEkiLCAiRzVFbmh
                PQU9vVTlYXzZRTU52ekZYanBFQV9SYy1BRXRtMWJHX3djYUtJayIsICJJaHdGcldVQjY
                zUmNacTl5dmdaMFhQYzdHb3doM08ya3FYZUJJc3dnMUI0IiwgIldweFE0SFNvRXRjVG1
                DQ0tPZURzbEJfZW11Y1lMejJvTzhvSE5yMWJFVlEiXX1d~WyJlSThaV205UW5LUHBOUG
                VOZW5IZGhRIiwgIm1ldGhvZCIsICJwaXBwIl0~WyJHMDJOU3JRZmpGWFE3SW8wOXN5YW
                pBIiwgImdpdmVuX25hbWUiLCAiTWF4Il0~WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIi
                wgImZhbWlseV9uYW1lIiwgIk1cdTAwZmNsbGVyIl0~WyJ5MXNWVTV3ZGZKYWhWZGd3UG
                dTN1JRIiwgImFkZHJlc3MiLCB7ImxvY2FsaXR5IjogIk1heHN0YWR0IiwgInBvc3RhbF
                9jb2RlIjogIjEyMzQ0IiwgImNvdW50cnkiOiAiREUiLCAic3RyZWV0X2FkZHJlc3MiOi
                AiV2VpZGVuc3RyYVx1MDBkZmUgMjIifV0~
                """
      .replacingOccurrences(of: "\n", with: "")
      .replacingOccurrences(of: " ", with: "")

    let verifier = SdJwtVerifier()

    let parser = Parser(serialisedString: ComplexStructureSDJWTString, serialisationFormat: .serialised)

    let signedSDJWT = try parser.getSignedSdJwt()
    let sdJWT = try signedSDJWT.toSDJWT()

    XCTAssertNoThrow(
        try verifier.verify(parser: parser) {
        try SignatureVerifier(signedJWT: signedSDJWT.jwt, publicKey: pk.converted(to: SecKey.self))
      } disclosuresVerifier: {
        try DisclosuresVerifier(sdJwt: sdJWT)
      }
    )
  }

  func testClaims() throws {
    // .......
    @SDJWTBuilder
    var evidenceObject: SdElement {
      PlainClaim("type", "document")
      FlatDisclosedClaim("method", "pipp")
      FlatDisclosedClaim("time", "2012-04-22T11:30Z")
      ObjectClaim("document") {
        PlainClaim("type", "idcard")
        ObjectClaim("issuer") {
          FlatDisclosedClaim("name", "Stadt Augsburg")
          PlainClaim("country", "DE")
        }
      }
    }
    // ..........

    @SDJWTBuilder
    var claim: SdElement {
      SdArrayClaim("evidence", array: [
        evidenceObject
      ])

    }
    let factory = SDJWTFactory(saltProvider: DefaultSaltProvider())
    let claimset = try factory.createJWT(sdJwtObject: claim.asObject).get()

    let disclosures = claimset.disclosures.map({$0.base64URLDecode()})

    let digests = claimset.value.findDigests()
    print(digests)
  }
}
