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
import JOSESwift
import SwiftyJSON

@testable import eudi_lib_sdjwt_swift

final class KeyBindingTest: XCTestCase {

  let kbJwt = """
  eyJhbGciOiAiRVMyNTYiLCAidHlwIjogImtiK2p3dCJ9
  .eyJub25jZSI6ICIxMjM0NTY3ODkwIiwgImF1ZCI6ICJodHRwczovL2V4YW1wbGUuY29
  tL3ZlcmlmaWVyIiwgImlhdCI6IDE2ODgxNjA0ODN9.duRIKesDpGY-5GkRcr98uhud64
  PfmPhL0qMcXFeBL5x2IGbAc_buglOrpd0LZA_cgCGXDx4zQoMou2kKrl-WCA
  """
    .clean()

  let jwk = """
  {
    "kty": "EC",
    "crv": "P-256",
    "x": "TCAER19Zvu3OHF4j4W4vfSVoHIP1ILilDls7vCeGemc",
    "y": "ZxjiWWbZMQGHVWKVQ4hbSIirsVfuecCE6t4jT9F2HZQ"
  }
  """
    .clean()

  @SDJWTBuilder
  var claims: SdElement {
    ConstantClaims.iat(time: Date())
    ConstantClaims.exp(time: Date() + 3600)
    ConstantClaims.iss(domain: "https://example.com/issuer")
    FlatDisclosedClaim("sub", "6c5c0a49-b589-431d-bae7-219122a9ec2c")
    FlatDisclosedClaim("given_name", "太郎")
  }

  func testKeyBinding() throws {
    let keyPair = generateES256KeyPair()
    let factory = SDJWTFactory(saltProvider: DefaultSaltProvider())
    let pk = try ECPublicKey(publicKey: keyPair.public)
    let jwk: JSON = try
    ["jwk": JSON(data: pk.jsonData()!)]
    let keyBindingJwt = factory.createJWT(sdjwtObject: claims.asObject, holdersPublicKey: jwk)
  }

  func testcCreateKeyBindingJWT_whenPassedECPublicKey() throws {

    let json = JSON(parseJSON: jwk)
    let ecPk = try ECPublicKey(data: json.rawData())
    print(try ecPk.converted(to: SecKey.self))

    let kbJws = try JWS(compactSerialization: kbJwt)
    let verifier = try SignatureVerifier(signedJWT: kbJws, publicKey: ecPk.converted(to: SecKey.self))
    try XCTAssertNoThrow(verifier.verify())
  }

  func testKeyBindingCreation_WhenKeybindingIsPresent_ThenExpectCorrectVerification() throws -> (SignedSDJWT, SignedSDJWT) {
    // Issuers Key Pair for es256
    let issuersKeyPair = generateES256KeyPair()
    // Holders Key Pair for es256
    let holdersKeyPair = generateES256KeyPair()

    let factory = SDJWTFactory(saltProvider: DefaultSaltProvider())

//    let json = JSON(parseJSON: jwk)
    let holdersECPK = try ECPublicKey(publicKey: holdersKeyPair.public)
    let jwk: JSON = try
    ["jwk": JSON(data: holdersECPK.jsonData()!)]

    let claims = try factory.createJWT(sdjwtObject: claims.asObject, holdersPublicKey: jwk).get()

    let issuance = try SDJWTIssuer.createSDJWT(purpose: .issuance(.init(algorithm: .ES256), claims),
                                               signingKey: issuersKeyPair.private)

    let kbjwtPayload: ClaimSet = (JSON(
      [
        Keys.aud.rawValue: "https://example.com/verifier",
        Keys.iat.rawValue: Date().timeIntervalSince1970,
        "nonce": "1234567890"] as [String: Any]
    ), [])

    let presentation = try SDJWTIssuer.createSDJWT(purpose: .presentation(issuance, KBJWT(header: .init(algorithm: .ES256), payload: kbjwtPayload.value)),
                                                   signingKey: holdersKeyPair.private)

    try SignatureVerifier(signedJWT: issuance.jwt, publicKey: issuersKeyPair.public).verify()

    try SignatureVerifier(signedJWT: presentation.kbJwt!, publicKey: holdersKeyPair.public).verify()
    try SignatureVerifier(signedJWT: presentation.jwt, publicKey: issuersKeyPair.public).verify()

    return(issuance, presentation)
  }

  func testKeyBindingCreation_WhenKeybindingIsPresent_ThenExpectCorrectVerificationInvoke() {
    XCTAssertNoThrow(try testKeyBindingCreation_WhenKeybindingIsPresent_ThenExpectCorrectVerification())
  }
}
