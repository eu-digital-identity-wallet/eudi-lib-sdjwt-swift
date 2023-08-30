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
import JOSESwift
import SwiftyJSON
import XCTest

@testable import eudi_lib_sdjwt_swift

final class SignedJwtTest: XCTestCase {
  @SDJWTBuilder
  var claims: SdElement {
    ConstantClaims.sub(subject: "6c5c0a49-b589-431d-bae7-219122a9ec2c")
    ConstantClaims.iss(domain: "https://example.com/issuer")
    ConstantClaims.iat(time: 1516239022)
    ConstantClaims.exp(time: 1516239022)

    ObjectClaim("address") {
      FlatDisclosedClaim("street_address", "Schulstr. 12")
      FlatDisclosedClaim("locality", "Schulpforta")
      FlatDisclosedClaim("region", "Sachsen-Anhalt")
      FlatDisclosedClaim("country", "DE")
    }
  }
  let factory = SDJWTFactory(saltProvider: DefaultSaltProvider())

  func testSignedJwt() {
    let claimSet = validateObjectResults(factoryResult: factory.createJWT(sdjwtObject: claims.asObject), expectedDigests: claims.expectedDigests)

    let keyPair = generateES256KeyPair()
    print(keyPair.private, keyPair.public)

    let issuer = try! SDJWTIssuer(purpose: .issuance(claimSet), jwsController: JWSController(signingAlgorithm: .ES256, privateKey: keyPair.private))

    let jws = try! issuer.createSignedJWT()

    do {
      let verifier = Verifier(verifyingAlgorithm: .ES256, key: keyPair.public)!

      let payload = try jws.validate(using: verifier).payload
      let message = try JSON.init(data: payload.data())

      XCTAssertEqual(message, claimSet.value)
    } catch {
      XCTFail("Failed To Verfiy JWS")
    }
  }

  func testSDJWTserialization() {
    let claimSet = validateObjectResults(factoryResult: factory.createJWT(sdjwtObject: claims.asObject), expectedDigests: claims.expectedDigests)

    let keyPair = generateES256KeyPair()
    print(keyPair.private, keyPair.public)

    let issuer = try! SDJWTIssuer(purpose: .issuance(claimSet), jwsController: JWSController(signingAlgorithm: .ES256, privateKey: keyPair.private))

    XCTAssertNoThrow(try issuer.createSignedJWT())
    let jws = try! issuer.createSignedJWT()
    let data = issuer.serialize(jws: jws)!

    let serializedString = String(data: data, encoding: .utf8)
  }

  func issuanceAsSpecExample() throws {

    let keyPair: KeyPair = generateES256KeyPair()

    let factory = SDJWTFactory(saltProvider: DefaultSaltProvider())
    let claimSet = factory.createJWT(sdjwtObject: claims.asObject)
    validateObjectResults(factoryResult: claimSet, expectedDigests: 4)
    let issuer = try SDJWTIssuer(purpose: .issuance(claimSet.get()),
                                 jwsController: .init(signingAlgorithm: .ES256, privateKey: keyPair.private))
    let signedSDJWT = try issuer.createSignedJWT()
    let data = issuer.serialize(jws: signedSDJWT)!
    let serializedString = String(data: data, encoding: .utf8)
    print(serializedString)
  }

  func testWrapTest() {
    XCTAssertNoThrow(try issuanceAsSpecExample())
  }
}
