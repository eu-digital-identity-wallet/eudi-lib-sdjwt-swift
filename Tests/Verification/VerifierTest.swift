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
import JSONWebKey
import JSONWebSignature
import JSONWebToken
import SwiftyJSON
import XCTest

@testable import eudi_lib_sdjwt_swift

final class VerifierTest: XCTestCase {

  func testVerifierBehaviour_WhenPassedValidSignatures_ThenExpectToPassAllCriterias() throws {

      let pk = try JSONDecoder.jwt.decode(JWK.self, from: key.tryToData())
    // Copied from Spec https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-05.html#name-example-3-complex-structure
    let complexStructureSDJWTString =
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
                """.clean()

    let result = try SDJWTVerifier(parser: CompactParser(serialisedString: complexStructureSDJWTString))
      .verifyIssuance { jws in
        try SignatureVerifier(signedJWT: jws, publicKey: pk)
      } claimVerifier: { _, _ in
        ClaimsVerifier()
      }

    XCTAssertNoThrow(try result.get())

    let recreatedClaimsResult = try CompactParser(serialisedString: complexStructureSDJWTString)
      .getSignedSdJwt()
      .recreateClaims()

    XCTAssertTrue(recreatedClaimsResult.recreatedClaims.exists())
    XCTAssertTrue(recreatedClaimsResult.digestsFoundOnPayload.count == 6)

  }

  func testVerifierBehaviour_WhenPassedNoSignature_ThenExpectToPassAllCriterias() throws {
    let ComplexStructureSDJWTString =
                """
                eyJhbGciOiAiRVMyNTYifQ.
                ewogICJpc3MiOiAiaHR0cHM6Ly9l
                eGFtcGxlLmNvbS9pc3N3NXIiLAogICJpYXQiOiAxNjgzMDAwMDA
                wLAogICJleHAiOiAxODgzMDAwMDAwLAogICJAY29udGV4dCI6IF
                sKICAgICJodHRwczovL3d3dy53My5vcmcvMjAxOC9jcmVkZW50a
                WFscy92MSIsCiAgICAiaHR0cHM6Ly93M2lkLm9yZy92YWNjaW5h
                dGlvbi92MSIKICBdLAogICJ0eXBlIjogWwogICAgIlZlcmlmaWF
                ibGVDcmVkZW50aWFsIiwKICAgICJWYWNjaW5hdGlvbkNlcnRpZm
                ljYXRlIgogIF0sCiAgImlzc3VlciI6ICJodHRwczovL2V4YW1wb
                GUuY29tL2lzc3VlciIsCiAgImlzc3VhbmNlRGF0ZSI6ICIyMDIz
                LTAyLTA5VDExOjAxOjU5WiIsCiAgImV4cGlyYXRpb25EYXRlIjo
                gIjIwMjgtMDItMDhUMTE6MDE6NTlaIiwKICAibmFtZSI6ICJDT1
                ZJRC0xOSBWYWNjaW5hdGlvbiBDZXJ0aWZpY2F0ZSIsCiAgImRlc
                2NyaXB0aW9uIjogIkNPVklELTE5IFZhY2NpbmF0aW9uIENlcnRp
                ZmljYXRlIiwKICAiY3JlZGVudGlhbFN1YmplY3QiOiB7CiAgICA
                iX3NkIjogWwogICAgICAiMVZfSy04bERROGlGWEJGWGJaWTllaH
                FSNEhhYldDaTVUMHliSXpaUGV3dyIsCiAgICAgICJKempMZ3RQM
                jlkUC1CM3RkMTJQNjc0Z0ZtSzJ6eTgxSE10QmdmNkNKTldnIiwK
                ICAgICAgIlIyZkdiZkEwN1pfWWxrcW1OWnltYTF4eXl4MVhzdEl
                pUzZCMVlibDJKWjQiLAogICAgICAiVENtenJsN0syZ2V2X2R1N3
                BjTUl5elJMSHAtWWVnLUZsX2N4dHJVdlB4ZyIsCiAgICAgICJWN
                2tKQkxLNzhUbVZET21yZko3WnVVUEh1S18yY2M3eVpSYTRxVjF0
                eHdNIiwKICAgICAgImIwZVVzdkdQLU9ERGRGb1k0Tmx6bFhjM3R
                Ec2xXSnRDSkY3NU53OE9qX2ciLAogICAgICAiekpLX2VTTVhqd0
                04ZFhtTVpMbkk4RkdNMDh6SjNfdWJHZUVNSi01VEJ5MCIKICAgI
                F0sCiAgICAidmFjY2luZSI6IHsKICAgICAgIl9zZCI6IFsKICAg
                ICAgICAiMWNGNWhMd2toTU5JYXFmV0pyWEk3Tk1XZWRMLTlmNlk
                yUEE1MnlQalNaSSIsCiAgICAgICAgIkhpeTZXV3VlTEQ1Ym4xNj
                I5OHRQdjdHWGhtbGRNRE9UbkJpLUNaYnBoTm8iLAogICAgICAgI
                CJMYjAyN3E2OTFqWFhsLWpDNzN2aThlYk9qOXNteDNDLV9vZzdn
                QTRUQlFFIgogICAgICBdLAogICAgICAidHlwZSI6ICJWYWNjaW5
                lIgogICAgfSwKICAgICJyZWNpcGllbnQiOiB7CiAgICAgICJfc2
                QiOiBbCiAgICAgICAgIjFsU1FCTlkyNHEwVGg2T0d6dGhxLTctN
                Gw2Y0FheHJZWE9HWnBlV19sbkEiLAogICAgICAgICIzbnpMcTgx
                TTJvTjA2d2R2MXNoSHZPRUpWeFo1S0xtZERrSEVESkFCV0VJIiw
                KICAgICAgICAiUG4xc1dpMDZHNExKcm5uLV9SVDBSYk1fSFRkeG
                5QSlF1WDJmeld2X0pPVSIsCiJQbjFzV2kwNkc0TEpybm4tX1JUM
                FJiTV9IVGR4blBKUXVYMmZ6V3ZfSk9zIiwKICAgICAgICAibEY5
                dXpkc3c3SHBsR0xjNzE0VHI0V083TUdKemE3dHQ3UUZsZUNYNEl
                0dyIKICAgICAgXSwKICAgICAgInR5cGUiOiAiVmFjY2luZVJlY2
                lwaWVudCIKICAgIH0sCiAgICAidHlwZSI6ICJWYWNjaW5hdGlvb
                kV2ZW50IgogIH0sCiAgIl9zZF9hbGciOiAic2hhLTI1NiIKfQ

                .tKnLymr8fQfupOgvMgBK3GCEIDEzhgta4MgnxYm9fWGMkqrz2R5PSkv0I-AXKXtIF6bdZRbjL-t43vC87jVoZQ~WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgImF0Y0NvZGUiLCAiSjA3QlgwMyJd
                ~WyJlbHVWNU9nM2dTTklJOEVZbnN4QV9BIiwgIm1lZGljaW5hbFByb2R1Y3ROYW1lIiwgIkNPVklELTE5IFZhY2NpbmUgTW9kZXJuYSJd
                ~WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgIm1hcmtldGluZ0F1dGhvcml6YXRpb25Ib2xkZXIiLCAiTW9kZXJuYSBCaW90ZWNoIl0
                ~WyJlSThaV205UW5LUHBOUGVOZW5IZGhRIiwgIm5leHRWYWNjaW5hdGlvbkRhdGUiLCAiMjAyMS0wOC0xNlQxMzo0MDoxMloiXQ
                ~WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgImNvdW50cnlPZlZhY2NpbmF0aW9uIiwgIkdFIl0~WyJBSngtMDk1VlBycFR0TjRRTU9xUk9BIiwgImRhdGVPZlZhY2NpbmF0aW9uIiwgIjIwMjEtMDYtMjNUMTM6NDA6MTJaIl0
                ~WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgIm9yZGVyIiwgIjMvMyJd~WyJHMDJOU3JRZmpGWFE3SW8wOXN5YWpBIiwgImdlbmRlciIsICJGZW1hbGUiXQ~WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgImJpcnRoRGF0ZSIsICIxOTYxLTA4LTE3Il0
                ~WyJuUHVvUW5rUkZxM0JJZUFtN0FuWEZBIiwgImdpdmVuTmFtZSIsICJNYXJpb24iXQ
                ~WyI1YlBzMUlxdVpOYTBoa2FGenp6Wk53IiwgImZhbWlseU5hbWUiLCAiTXVzdGVybWFubiJd
                ~WyI1YTJXMF9OcmxFWnpmcW1rXzdQcS13IiwgImFkbWluaXN0ZXJpbmdDZW50cmUiLCAiUHJheGlzIFNvbW1lcmdhcnRlbiJd
                ~WyJ5MXNWVTV3ZGZKYWhWZGd3UGdTN1JRIiwgImJhdGNoTnVtYmVyIiwgIjE2MjYzODI3MzYiXQ~WyJIYlE0WDhzclZXM1FEeG5JSmRxeU9BIiwgImhlYWx0aFByb2Zlc3Npb25hbCIsICI4ODMxMTAwMDAwMTUzNzYiXQ~
                """
      .clean()

    let result = try SDJWTVerifier(parser: CompactParser(serialisedString: ComplexStructureSDJWTString))
      .unsingedVerify { signedSDJWT in
        try DisclosuresVerifier(signedSDJWT: signedSDJWT)
      }

    XCTAssertNoThrow(try result.get())
  }

  func testVerifier_WhenPassingSameKeys_ThenExpectToFail() throws {

    let jsonElementArray: JSON = [
      "...": "tYJ0TDucyZZCRMbROG4qRO5vkPSFRxFhUELc18CSl3k"
    ]

    let json: JSON = [
      "evidence": [
        jsonElementArray
      ],
      "time": "2012-04-22T11:30Z",
      "method": "pipp",
      "_sd": [
        "WpxQ4HSoEtcTmCCKOeDslB_emucYLz2oO8oHNr1bEVQ"
      ]
    ]

    let element = """
      WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgeyJfc2QiOiBbIjl3cGpWUFd1
      RDdQSzBuc1FETDhCMDZsbWRnVjNMVnliaEh5ZFFwVE55TEkiLCAiRzVFbmhP
      QU9vVTlYXzZRTU52ekZYanBFQV9SYy1BRXRtMWJHX3djYUtJayIsICJJaHdG
      cldVQjYzUmNacTl5dmdaMFhQYzdHb3doM08ya3FYZUJJc3dnMUI0IiwgIldw
      eFE0SFNvRXRjVG1DQ0tPZURzbEJfZW11Y1lMejJvTzhvSE5yMWJFVlEiXX1d
      """
      .clean()

    let enclosedInDisclosure = """
      WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgInRpbWUiLCAiMjAxMi0wNC0y
      MlQxMTozMFoiXQ

      """
      .clean()
    let duplicateSD = """
      WyJlSThaV205UW5LUHBOUGVOZW5IZGhRIiwgIm1ldGhvZCIsICJwaXBwIl0
      """
      .clean()

    let disclosureForDigestDict = [
      "tYJ0TDucyZZCRMbROG4qRO5vkPSFRxFhUELc18CSl3k": element,
      "9wpjVPWuD7PK0nsQDL8B06lmdgV3LVybhHydQpTNyLI": enclosedInDisclosure,
      "WpxQ4HSoEtcTmCCKOeDslB_emucYLz2oO8oHNr1bEVQ": duplicateSD
    ]

    let claimExtractor = ClaimExtractor(digestsOfDisclosuresDict: disclosureForDigestDict)
    XCTAssertThrowsError(try claimExtractor.findDigests(payload: json, disclosures: [element, enclosedInDisclosure])) { error in
      let error = error as? SDJWTVerifierError
      switch error {
      case .nonUniqueDisclosures:
        XCTAssert(true)
      default:
        XCTFail("wrong type of error \(error?.localizedDescription ?? "")")
      }
    }
  }

  func testVerifierWhenClaimsContainIatExpNbfClaims_ThenExpectTobeInCorrectTimeRanges() throws {
    let iatJwt = try SDJWTIssuer.issue(issuersPrivateKey: issuersKeyPair.private,
                                       header: DefaultJWSHeaderImpl(algorithm: .ES256), buildSDJWT: {
      ConstantClaims.iat(time: Date())
      FlatDisclosedClaim("time", "is created at \(Date())")
    })

    let expSdJwt = try SDJWTIssuer.issue(
      issuersPrivateKey: issuersKeyPair.private,
      header: DefaultJWSHeaderImpl(algorithm: .ES256)) {
        ConstantClaims.exp(time: Date(timeIntervalSinceNow: 36000))
        FlatDisclosedClaim("time", "time runs out")
    }

    let nbfSdJwt = try SDJWTIssuer.issue(
      issuersPrivateKey: issuersKeyPair.private,
      header: DefaultJWSHeaderImpl(algorithm: .ES256)) {
        ConstantClaims.nbf(time: Date(timeIntervalSinceNow: -36000))
        FlatDisclosedClaim("time", "we are ahead of time")
    }

    let nbfAndExpSdJwt = try SDJWTIssuer.issue(
      issuersPrivateKey: issuersKeyPair.private,
      header: DefaultJWSHeaderImpl(algorithm: .ES256)
    ) {
      ConstantClaims.exp(time: Date(timeIntervalSinceNow: 36000))
      ConstantClaims.nbf(time: Date(timeIntervalSinceNow: -36000))
      FlatDisclosedClaim("time", "time runs out or maybe not")
    }

    for sdjwt in [iatJwt, expSdJwt, nbfSdJwt, nbfAndExpSdJwt] {
      let result = try SDJWTVerifier(sdJwt: sdjwt).verifyIssuance { jws in
        try SignatureVerifier(signedJWT: jws, publicKey: issuersKeyPair.public)
      } claimVerifier: { nbf, exp in
        ClaimsVerifier(
          iat: Int(Date().timeIntervalSince1970.rounded()),
          iatValidWindow: TimeRange(
            startTime: Date(),
            endTime: Date(timeIntervalSinceNow: 10)
          ),
          nbf: nbf,
          exp: exp
        )
      }

      XCTAssertNoThrow(try result.get())
    }
  }

  func testVerifierWhenProvidingAKeyBindingJWT_WHenProvidedWithAudNonceAndIatClaims_ThenExpectToPassClaimVerificationAndKBVerification () throws {
    let holdersJWK = holdersKeyPair.public
    let jwk = try holdersJWK.jwk

    let issuerSignedSDJWT = try SDJWTIssuer.issue(
        issuersPrivateKey: issuersKeyPair.private,
        header: DefaultJWSHeaderImpl(algorithm: .ES256)
    ) {
      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date() + 3600)
      ConstantClaims.iss(domain: "https://example.com/issuer")
      FlatDisclosedClaim("sub", "6c5c0a49-b589-431d-bae7-219122a9ec2c")
      FlatDisclosedClaim("given_name", "太郎")
      FlatDisclosedClaim("family_name", "山田")
      FlatDisclosedClaim("email", "\"unusual email address\"@example.jp")
      FlatDisclosedClaim("phone_number", "+81-80-1234-5678")
      ObjectClaim("address") {
        FlatDisclosedClaim("street_address", "東京都港区芝公園４丁目２−８")
        FlatDisclosedClaim("locality", "東京都")
        FlatDisclosedClaim("region", "港区")
        FlatDisclosedClaim("country", "JP")
      }
      FlatDisclosedClaim("birthdate", "1940-01-01")

      ObjectClaim("cnf") {
        ObjectClaim("jwk") {
          PlainClaim("kty", "EC")
          PlainClaim("y", jwk.y?.base64URLEncode())
          PlainClaim("x", jwk.x?.base64URLEncode())
          PlainClaim("crv", jwk.curve)
        }
      }
    }

    let sdHash = DigestCreator()
      .hashAndBase64Encode(
        input: CompactSerialiser(
          signedSDJWT: issuerSignedSDJWT
        ).serialised
      ) ?? ""

    let holder = try SDJWTIssuer
      .presentation(
        holdersPrivateKey: holdersKeyPair.private,
        signedSDJWT: issuerSignedSDJWT,
        disclosuresToPresent: issuerSignedSDJWT.disclosures,
        keyBindingJWT: KBJWT(
          header: DefaultJWSHeaderImpl(algorithm: .ES256),
          kbJwtPayload: .init([
            Keys.nonce.rawValue: "123456789",
            Keys.aud.rawValue: "example.com",
            Keys.iat.rawValue: 1694600000,
            Keys.sdHash.rawValue: sdHash
          ])
        )
      )

    let verifier = SDJWTVerifier(
      sdJwt: holder
    ).verifyPresentation { jws in
      try SignatureVerifier(
        signedJWT: jws,
        publicKey: issuersKeyPair.public
      )
      
    } claimVerifier: { _, _ in
      ClaimsVerifier()
      
    } keyBindingVerifier: { jws, holdersPublicKey in
      try KeyBindingVerifier(
        iatOffset: .init(
          startTime: Date(timeIntervalSince1970: 1694600000 - 1000),
          endTime: Date(timeIntervalSince1970: 1694600000)
        )!,
        expectedAudience: "example.com",
        challenge: jws,
        extractedKey: holdersPublicKey
      )
    }

    XCTAssertEqual(sdHash, holder.delineatedCompactSerialisation)
    XCTAssertNoThrow(try verifier.get())
  }

  func testSerialiseWhenChosingEnvelopeFormat_AppylingEnvelopeBinding_ThenExpectACorrectJWT() throws {
    let serializerTest = SerialiserTest()

    let compactParser = try CompactParser(serialisedString: serializerTest.testSerializerWhenSerializedFormatIsSelected_ThenExpectSerialisedFormattedSignedSDJWT())

    let envelopeSerializer = try EnvelopedSerialiser(
        SDJWT: compactParser.getSignedSdJwt(),
        jwTpayload: JWTBody(nonce: "", aud: "sub", iat: 1234
    ).toJSONData())

    _ = try SignatureVerifier(
        signedJWT: JWS(
            payload: envelopeSerializer.data,
            protectedHeader: DefaultJWSHeaderImpl(algorithm: .ES256),
            key: holdersKeyPair.private
        ),
        publicKey: holdersKeyPair.public)

    let jwt = try JWS(
      payload: envelopeSerializer.data,
      protectedHeader: DefaultJWSHeaderImpl(algorithm: .ES256),
      key: holdersKeyPair.private
    )

    let envelopedJws = try JWS(jwsString: jwt.compactSerialization)

    let verifyEnvelope =
    try SDJWTVerifier(parser: EnvelopedParser(data: envelopeSerializer.data))
      .verifyEnvelope(envelope: envelopedJws) { jws in

        try SignatureVerifier(signedJWT: jws, publicKey: issuersKeyPair.public)
      } holdersSignatureVerifier: {

        try SignatureVerifier(signedJWT: envelopedJws, publicKey: holdersKeyPair.public)
      } claimVerifier: { audClaim, iat in
        ClaimsVerifier(
          iat: iat,
          iatValidWindow: .init(
            startTime: Date(timeIntervalSince1970: 1234-10),
            endTime: Date(timeIntervalSince1970: 1234+10)
          ),
          audClaim: audClaim,
          expectedAud: "sub"
        )
      }
    XCTAssertNoThrow(try verifyEnvelope.get())
  }
}
