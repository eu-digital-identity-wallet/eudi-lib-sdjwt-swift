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
import JOSESwift
import XCTest

@testable import eudi_lib_sdjwt_swift

final class VerifierTest: XCTestCase {

  func testVerifierBehaviour_WhenPassedValidSignatures_ThenExpectToPassAllCriterias() throws {
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
                eyJhbGciOiAiRVMyNTYifQ.eyJfc2QiOiBbIkM5aW5wNllvUmFFWFI0Mjd6WUpQN1Fya
                zFXSF84YmR3T0FfWVVyVW5HUVUiLCAiS3VldDF5QWEwSElRdlluT1ZkNTloY1ZpTzlVZ
                zZKMmtTZnFZUkJlb3d2RSIsICJNTWxkT0ZGekIyZDB1bWxtcFRJYUdlcmhXZFVfUHBZZ
                kx2S2hoX2ZfOWFZIiwgIlg2WkFZT0lJMnZQTjQwVjd4RXhad1Z3ejd5Um1MTmNWd3Q1R
                Ew4Ukx2NGciLCAiWTM0em1JbzBRTExPdGRNcFhHd2pCZ0x2cjE3eUVoaFlUMEZHb2ZSL
                WFJRSIsICJmeUdwMFdUd3dQdjJKRFFsbjFsU2lhZW9iWnNNV0ExMGJRNTk4OS05RFRzI
                iwgIm9tbUZBaWNWVDhMR0hDQjB1eXd4N2ZZdW8zTUhZS08xNWN6LVJaRVlNNVEiLCAic
                zBCS1lzTFd4UVFlVTh0VmxsdE03TUtzSVJUckVJYTFQa0ptcXhCQmY1VSJdLCAiaXNzI
                jogImh0dHBzOi8vZXhhbXBsZS5jb20vaXNzdWVyIiwgImlhdCI6IDE2ODMwMDAwMDAsI
                CJleHAiOiAxODgzMDAwMDAwLCAiYWRkcmVzcyI6IHsiX3NkIjogWyI2YVVoelloWjdTS
                jFrVm1hZ1FBTzN1MkVUTjJDQzFhSGhlWnBLbmFGMF9FIiwgIkF6TGxGb2JrSjJ4aWF1c
                FJFUHlvSnotOS1OU2xkQjZDZ2pyN2ZVeW9IemciLCAiUHp6Y1Z1MHFiTXVCR1NqdWxmZ
                Xd6a2VzRDl6dXRPRXhuNUVXTndrclEtayIsICJiMkRrdzBqY0lGOXJHZzhfUEY4WmN2b
                mNXN3p3Wmo1cnlCV3ZYZnJwemVrIiwgImNQWUpISVo4VnUtZjlDQ3lWdWIyVWZnRWs4a
                nZ2WGV6d0sxcF9KbmVlWFEiLCAiZ2xUM2hyU1U3ZlNXZ3dGNVVEWm1Xd0JUdzMyZ25Vb
                GRJaGk4aEdWQ2FWNCIsICJydkpkNmlxNlQ1ZWptc0JNb0d3dU5YaDlxQUFGQVRBY2k0M
                G9pZEVlVnNBIiwgInVOSG9XWWhYc1poVkpDTkUyRHF5LXpxdDd0NjlnSkt5NVFhRnY3R
                3JNWDQiXX0sICJfc2RfYWxnIjogInNoYS0yNTYifQ.rFsowW-KSZe7EITlWsGajR9nnG
                BLlQ78qgtdGIZg3FZuZnxtapP0H8CUMnffJAwPQJmGnpFpulTkLWHiI1kMmw~WyJHMDJ
                OU3JRZmpGWFE3SW8wOXN5YWpBIiwgInJlZ2lvbiIsICJcdTZlMmZcdTUzM2EiXQ~WyJs
                a2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgImNvdW50cnkiLCAiSlAiXQ~
                """
      .replacingOccurrences(of: "\n", with: "")
      .replacingOccurrences(of: " ", with: "")

    let result = SDJWTVerifier(serialisedString: ComplexStructureSDJWTString, serialisationFormat: .serialised)
      .verifyIssuance { jws in
      try SignatureVerifier(signedJWT: jws, publicKey: pk.converted(to: SecKey.self))
    } disclosuresVerifier: { parser in
      try DisclosuresVerifier(parser: parser)
    }

    XCTAssertNoThrow(try result.get())
  }

  func testVerifierBehaviour_WhenPassedNoSignature_ThenExpectToPassAllCriterias() throws {
    let ComplexStructureSDJWTString =
                """
                eyJhbGciOiAiRVMyNTYifQ.ewogICJpc3MiOiAiaHR0cHM6Ly9leGFtcGxlLmNvbS9pc3N3NXIiLAogICJpYXQiOiAxNjgzMDAwMDAwLAogICJleHAiOiAxODgzMDAwMDAwLAogICJAY29udGV4dCI6IFsKICAgICJodHRwczovL3d3dy53My5vcmcvMjAxOC9jcmVkZW50aWFscy92MSIsCiAgICAiaHR0cHM6Ly93M2lkLm9yZy92YWNjaW5hdGlvbi92MSIKICBdLAogICJ0eXBlIjogWwogICAgIlZlcmlmaWFibGVDcmVkZW50aWFsIiwKICAgICJWYWNjaW5hdGlvbkNlcnRpZmljYXRlIgogIF0sCiAgImlzc3VlciI6ICJodHRwczovL2V4YW1wbGUuY29tL2lzc3VlciIsCiAgImlzc3VhbmNlRGF0ZSI6ICIyMDIzLTAyLTA5VDExOjAxOjU5WiIsCiAgImV4cGlyYXRpb25EYXRlIjogIjIwMjgtMDItMDhUMTE6MDE6NTlaIiwKICAibmFtZSI6ICJDT1ZJRC0xOSBWYWNjaW5hdGlvbiBDZXJ0aWZpY2F0ZSIsCiAgImRlc2NyaXB0aW9uIjogIkNPVklELTE5IFZhY2NpbmF0aW9uIENlcnRpZmljYXRlIiwKICAiY3JlZGVudGlhbFN1YmplY3QiOiB7CiAgICAiX3NkIjogWwogICAgICAiMVZfSy04bERROGlGWEJGWGJaWTllaHFSNEhhYldDaTVUMHliSXpaUGV3dyIsCiAgICAgICJKempMZ3RQMjlkUC1CM3RkMTJQNjc0Z0ZtSzJ6eTgxSE10QmdmNkNKTldnIiwKICAgICAgIlIyZkdiZkEwN1pfWWxrcW1OWnltYTF4eXl4MVhzdElpUzZCMVlibDJKWjQiLAogICAgICAiVENtenJsN0syZ2V2X2R1N3BjTUl5elJMSHAtWWVnLUZsX2N4dHJVdlB4ZyIsCiAgICAgICJWN2tKQkxLNzhUbVZET21yZko3WnVVUEh1S18yY2M3eVpSYTRxVjF0eHdNIiwKICAgICAgImIwZVVzdkdQLU9ERGRGb1k0Tmx6bFhjM3REc2xXSnRDSkY3NU53OE9qX2ciLAogICAgICAiekpLX2VTTVhqd004ZFhtTVpMbkk4RkdNMDh6SjNfdWJHZUVNSi01VEJ5MCIKICAgIF0sCiAgICAidmFjY2luZSI6IHsKICAgICAgIl9zZCI6IFsKICAgICAgICAiMWNGNWhMd2toTU5JYXFmV0pyWEk3Tk1XZWRMLTlmNlkyUEE1MnlQalNaSSIsCiAgICAgICAgIkhpeTZXV3VlTEQ1Ym4xNjI5OHRQdjdHWGhtbGRNRE9UbkJpLUNaYnBoTm8iLAogICAgICAgICJMYjAyN3E2OTFqWFhsLWpDNzN2aThlYk9qOXNteDNDLV9vZzdnQTRUQlFFIgogICAgICBdLAogICAgICAidHlwZSI6ICJWYWNjaW5lIgogICAgfSwKICAgICJyZWNpcGllbnQiOiB7CiAgICAgICJfc2QiOiBbCiAgICAgICAgIjFsU1FCTlkyNHEwVGg2T0d6dGhxLTctNGw2Y0FheHJZWE9HWnBlV19sbkEiLAogICAgICAgICIzbnpMcTgxTTJvTjA2d2R2MXNoSHZPRUpWeFo1S0xtZERrSEVESkFCV0VJIiwKICAgICAgICAiUG4xc1dpMDZHNExKcm5uLV9SVDBSYk1fSFRkeG5QSlF1WDJmeld2X0pPVSIsCiJQbjFzV2kwNkc0TEpybm4tX1JUMFJiTV9IVGR4blBKUXVYMmZ6V3ZfSk9zIiwKICAgICAgICAibEY5dXpkc3c3SHBsR0xjNzE0VHI0V083TUdKemE3dHQ3UUZsZUNYNEl0dyIKICAgICAgXSwKICAgICAgInR5cGUiOiAiVmFjY2luZVJlY2lwaWVudCIKICAgIH0sCiAgICAidHlwZSI6ICJWYWNjaW5hdGlvbkV2ZW50IgogIH0sCiAgIl9zZF9hbGciOiAic2hhLTI1NiIKfQ.tKnLymr8fQfupOgvMgBK3GCEIDEzhgta4MgnxYm9fWGMkqrz2R5PSkv0I-AXKXtIF6bdZRbjL-t43vC87jVoZQ~WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgImF0Y0NvZGUiLCAiSjA3QlgwMyJd~WyJlbHVWNU9nM2dTTklJOEVZbnN4QV9BIiwgIm1lZGljaW5hbFByb2R1Y3ROYW1lIiwgIkNPVklELTE5IFZhY2NpbmUgTW9kZXJuYSJd~WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgIm1hcmtldGluZ0F1dGhvcml6YXRpb25Ib2xkZXIiLCAiTW9kZXJuYSBCaW90ZWNoIl0~WyJlSThaV205UW5LUHBOUGVOZW5IZGhRIiwgIm5leHRWYWNjaW5hdGlvbkRhdGUiLCAiMjAyMS0wOC0xNlQxMzo0MDoxMloiXQ~WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgImNvdW50cnlPZlZhY2NpbmF0aW9uIiwgIkdFIl0~WyJBSngtMDk1VlBycFR0TjRRTU9xUk9BIiwgImRhdGVPZlZhY2NpbmF0aW9uIiwgIjIwMjEtMDYtMjNUMTM6NDA6MTJaIl0~WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgIm9yZGVyIiwgIjMvMyJd~WyJHMDJOU3JRZmpGWFE3SW8wOXN5YWpBIiwgImdlbmRlciIsICJGZW1hbGUiXQ~WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgImJpcnRoRGF0ZSIsICIxOTYxLTA4LTE3Il0~WyJuUHVvUW5rUkZxM0JJZUFtN0FuWEZBIiwgImdpdmVuTmFtZSIsICJNYXJpb24iXQ~WyI1YlBzMUlxdVpOYTBoa2FGenp6Wk53IiwgImZhbWlseU5hbWUiLCAiTXVzdGVybWFubiJd~WyI1YTJXMF9OcmxFWnpmcW1rXzdQcS13IiwgImFkbWluaXN0ZXJpbmdDZW50cmUiLCAiUHJheGlzIFNvbW1lcmdhcnRlbiJd~WyJ5MXNWVTV3ZGZKYWhWZGd3UGdTN1JRIiwgImJhdGNoTnVtYmVyIiwgIjE2MjYzODI3MzYiXQ~WyJIYlE0WDhzclZXM1FEeG5JSmRxeU9BIiwgImhlYWx0aFByb2Zlc3Npb25hbCIsICI4ODMxMTAwMDAwMTUzNzYiXQ~
                """
      .replacingOccurrences(of: "\n", with: "")
      .replacingOccurrences(of: " ", with: "")

    let result = SDJWTVerifier(serialisedString: ComplexStructureSDJWTString, serialisationFormat: .serialised).unsingedVerify { parser in
      try DisclosuresVerifier(parser: parser)
    }

    XCTAssertNoThrow(try result.get())
  }
}
