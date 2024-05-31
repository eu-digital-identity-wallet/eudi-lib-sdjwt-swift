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
import JSONWebSignature
import SwiftyJSON
import XCTest

@testable import eudi_lib_sdjwt_swift

final class SignedJwtTest: XCTestCase {

  func testGivenASampleUnsignedJWT_WhenSupplyingWithES256PublicKeyPair_ThenCreateTheSDJW_WithNoKeyBidning() throws {

    let keyPair = generateES256KeyPair()
    let signedJWT = try SDJWTIssuer.issue(
      issuersPrivateKey: keyPair.private,
      header: DefaultJWSHeaderImpl(
        algorithm: .ES256
      )
    ) {
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

    let serialised: String = try signedJWT.serialised { jwt in
      CompactSerialiser(signedSDJWT: jwt)
    }

    let verifier = try SDJWTVerifier(parser: CompactParser(serialisedString: serialised)).verifyIssuance { jws in
      try SignatureVerifier(signedJWT: jws, publicKey: keyPair.public)
    } claimVerifier: { _, _ in
      ClaimsVerifier()
    }
  }

}
