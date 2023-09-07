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

    let pk = try! ECPublicKey(data: JSON(parseJSON: key).rawData())
    // Copied from Spec https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-05.html#name-example-3-complex-structure
    let ComplexStructureSDJWTString =
                """
                eyJhbGciOiAiRVMyNTYifQ
                
                .ewogICJpc3MiOiAiaHR0cHM6Ly9leGFtcGxlLmNvbS9pc3N3NXIiLAogICJpYXQiOiAxNjgzMDAwMDAwLAogICJleHAiOiAxODgzMDAwMDAwLAogICJAY29udGV4dCI6IFsKICAgICJodHRwczovL3d3dy53My5vcmcvMjAxOC9jcmVkZW50aWFscy92MSIsCiAgICAiaHR0cHM6Ly93M2lkLm9yZy92YWNjaW5hdGlvbi92MSIKICBdLAogICJ0eXBlIjogWwogICAgIlZlcmlmaWFibGVDcmVkZW50aWFsIiwKICAgICJWYWNjaW5hdGlvbkNlcnRpZmljYXRlIgogIF0sCiAgImlzc3VlciI6ICJodHRwczovL2V4YW1wbGUuY29tL2lzc3VlciIsCiAgImlzc3VhbmNlRGF0ZSI6ICIyMDIzLTAyLTA5VDExOjAxOjU5WiIsCiAgImV4cGlyYXRpb25EYXRlIjogIjIwMjgtMDItMDhUMTE6MDE6NTlaIiwKICAibmFtZSI6ICJDT1ZJRC0xOSBWYWNjaW5hdGlvbiBDZXJ0aWZpY2F0ZSIsCiAgImRlc2NyaXB0aW9uIjogIkNPVklELTE5IFZhY2NpbmF0aW9uIENlcnRpZmljYXRlIiwKICAiY3JlZGVudGlhbFN1YmplY3QiOiB7CiAgICAiX3NkIjogWwogICAgICAiMVZfSy04bERROGlGWEJGWGJaWTllaHFSNEhhYldDaTVUMHliSXpaUGV3dyIsCiAgICAgICJKempMZ3RQMjlkUC1CM3RkMTJQNjc0Z0ZtSzJ6eTgxSE10QmdmNkNKTldnIiwKICAgICAgIlIyZkdiZkEwN1pfWWxrcW1OWnltYTF4eXl4MVhzdElpUzZCMVlibDJKWjQiLAogICAgICAiVENtenJsN0syZ2V2X2R1N3BjTUl5elJMSHAtWWVnLUZsX2N4dHJVdlB4ZyIsCiAgICAgICJWN2tKQkxLNzhUbVZET21yZko3WnVVUEh1S18yY2M3eVpSYTRxVjF0eHdNIiwKICAgICAgImIwZVVzdkdQLU9ERGRGb1k0Tmx6bFhjM3REc2xXSnRDSkY3NU53OE9qX2ciLAogICAgICAiekpLX2VTTVhqd004ZFhtTVpMbkk4RkdNMDh6SjNfdWJHZUVNSi01VEJ5MCIKICAgIF0sCiAgICAidmFjY2luZSI6IHsKICAgICAgIl9zZCI6IFsKICAgICAgICAiMWNGNWhMd2toTU5JYXFmV0pyWEk3Tk1XZWRMLTlmNlkyUEE1MnlQalNaSSIsCiAgICAgICAgIkhpeTZXV3VlTEQ1Ym4xNjI5OHRQdjdHWGhtbGRNRE9UbkJpLUNaYnBoTm8iLAogICAgICAgICJMYjAyN3E2OTFqWFhsLWpDNzN2aThlYk9qOXNteDNDLV9vZzdnQTRUQlFFIgogICAgICBdLAogICAgICAidHlwZSI6ICJWYWNjaW5lIgogICAgfSwKICAgICJyZWNpcGllbnQiOiB7CiAgICAgICJfc2QiOiBbCiAgICAgICAgIjFsU1FCTlkyNHEwVGg2T0d6dGhxLTctNGw2Y0FheHJZWE9HWnBlV19sbkEiLAogICAgICAgICIzbnpMcTgxTTJvTjA2d2R2MXNoSHZPRUpWeFo1S0xtZERrSEVESkFCV0VJIiwKICAgICAgICAiUG4xc1dpMDZHNExKcm5uLV9SVDBSYk1fSFRkeG5QSlF1WDJmeld2X0pPVSIsCiJQbjFzV2kwNkc0TEpybm4tX1JUMFJiTV9IVGR4blBKUXVYMmZ6V3ZfSk9zIiwKICAgICAgICAibEY5dXpkc3c3SHBsR0xjNzE0VHI0V083TUdKemE3dHQ3UUZsZUNYNEl0dyIKICAgICAgXSwKICAgICAgInR5cGUiOiAiVmFjY2luZVJlY2lwaWVudCIKICAgIH0sCiAgICAidHlwZSI6ICJWYWNjaW5hdGlvbkV2ZW50IgogIH0sCiAgIl9zZF9hbGciOiAic2hhLTI1NiIKfQ.tKnLymr8fQfupOgvMgBK3GCEIDEzhgta4MgnxY
                m9fWGMkqrz2R5PSkv0I-AXKXtIF6bdZRbjL-t43vC87jVoZQ

                ~WyIyR0xDNDJzS1F2ZUNmR2Z
                yeU5STjl3IiwgImF0Y0NvZGUiLCAiSjA3QlgwMyJd~WyJlbHVWNU9nM2dTTklJOEVZbn
                N4QV9BIiwgIm1lZGljaW5hbFByb2R1Y3ROYW1lIiwgIkNPVklELTE5IFZhY2NpbmUgTW
                9kZXJuYSJd~WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgIm1hcmtldGluZ0F1dGhvc
                ml6YXRpb25Ib2xkZXIiLCAiTW9kZXJuYSBCaW90ZWNoIl0~WyJlSThaV205UW5LUHBOU
                GVOZW5IZGhRIiwgIm5leHRWYWNjaW5hdGlvbkRhdGUiLCAiMjAyMS0wOC0xNlQxMzo0M
                DoxMloiXQ~WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgImNvdW50cnlPZlZhY2Npbm
                F0aW9uIiwgIkdFIl0~WyJBSngtMDk1VlBycFR0TjRRTU9xUk9BIiwgImRhdGVPZlZhY2
                NpbmF0aW9uIiwgIjIwMjEtMDYtMjNUMTM6NDA6MTJaIl0~WyJQYzMzSk0yTGNoY1VfbE
                hnZ3ZfdWZRIiwgIm9yZGVyIiwgIjMvMyJd~WyJHMDJOU3JRZmpGWFE3SW8wOXN5YWpBI
                iwgImdlbmRlciIsICJGZW1hbGUiXQ~WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgIm
                JpcnRoRGF0ZSIsICIxOTYxLTA4LTE3Il0~WyJuUHVvUW5rUkZxM0JJZUFtN0FuWEZBIi
                wgImdpdmVuTmFtZSIsICJNYXJpb24iXQ~WyI1YlBzMUlxdVpOYTBoa2FGenp6Wk53Iiw
                gImZhbWlseU5hbWUiLCAiTXVzdGVybWFubiJd~WyI1YTJXMF9OcmxFWnpmcW1rXzdQcS
                13IiwgImFkbWluaXN0ZXJpbmdDZW50cmUiLCAiUHJheGlzIFNvbW1lcmdhcnRlbiJd~W
                yJ5MXNWVTV3ZGZKYWhWZGd3UGdTN1JRIiwgImJhdGNoTnVtYmVyIiwgIjE2MjYzODI3M
                zYiXQ~WyJIYlE0WDhzclZXM1FEeG5JSmRxeU9BIiwgImhlYWx0aFByb2Zlc3Npb25hbC
                IsICI4ODMxMTAwMDAwMTUzNzYiXQ~
                """
      .replacingOccurrences(of: "\n", with: "")
      .replacingOccurrences(of: " ", with: "")

    let verifier = SdJwtVerifier()

    let parser = Parser(serialisedString: ComplexStructureSDJWTString, serialisationFormat: .serialised)

    let signedSDJWT = try parser.getSignedSdJwt()
    let sdJWT = try signedSDJWT.toSDJWT()

    let result = verifier.unsingedVerify(parser: parser) {
      try DisclosuresVerifier(sdJwt: sdJWT)
    }
//    let result = verifier.un(parser: parser) {
//      try SignatureVerifier(signedJWT: signedSDJWT.jwt, publicKey: pk.converted(to: SecKey.self))
//    } disclosuresVerifier: {
//      try DisclosuresVerifier(sdJwt: sdJWT)
//    }

    XCTAssertNoThrow(try result.get())
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
