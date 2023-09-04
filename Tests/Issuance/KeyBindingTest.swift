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
    let keyBindingJwt = factory.createJWT(sdjwtObject: claims.asObject, holdersPublicKey: pk)
  }

  func testcCreateKeyBindingJWT() throws {
    let keyPair = generateES256KeyPair()
    var header = JWSHeader(algorithm: .ES256)
    header.typ = "kb+jwt"

    let payload: JSON = [
      Keys.iat.rawValue: "",
      Keys.exp.rawValue: "",
      Keys.aud.rawValue: ""
    ]

    let kbjwt = try JWT.KBJWT(header: header, KBJWTBody: payload)
    print(kbjwt)

    try print(kbjwt.header.jwkTyped?.toJSONString())
//    print(kbjwt.signature.compactSerializedString)
    let json = JSON(parseJSON: jwk)
    let ecPk = try ECPublicKey(data: json.rawData())
    print(ecPk)
  }

  let jwk = """
  {
    "kty": "EC",
    "crv": "P-256",
    "x": "b28d4MwZMjw8-00CG4xfnn9SLMVMM19SlqZpVb_uNtQ",
    "y": "Xv5zWwuoaTgdS6hV43yI6gBwTnjukmFQQnJ_kCxzqk8"
  }
  """
    .replacingOccurrences(of: "\n", with: "")
    .replacingOccurrences(of: " ", with: "")
}
