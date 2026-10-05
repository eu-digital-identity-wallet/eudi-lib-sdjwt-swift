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

import XCTest
import JSONWebSignature
import JSONWebToken

@testable import eudi_lib_sdjwt_swift


final class KeyBindingSigningErrorTest: XCTestCase {

  private struct ThrowingAsyncSigner: AsyncSignerProtocol {
    struct SignerError: Error {}
    func signAsync(_ data: Data) async throws -> Data {
      throw SignerError()
    }
  }

  private func issueSampleSDJWT() async throws -> SignedSDJWT {
    let holdersJwk = try holdersKeyPair.public.jwk
    return try await SDJWTIssuer.issue(
      issuersPrivateKey: issuersKeyPair.private,
      header: DefaultJWSHeaderImpl(algorithm: .ES256)
    ) {
      ConstantClaims.iat(time: Date())
      ConstantClaims.iss(domain: "https://example.com/issuer")
      FlatDisclosedClaim("given_name", "John")
      ObjectClaim("cnf") {
        ObjectClaim("jwk") {
          PlainClaim("kty", "EC")
          PlainClaim("y", holdersJwk.y?.base64URLEncode())
          PlainClaim("x", holdersJwk.x?.base64URLEncode())
          PlainClaim("crv", holdersJwk.curve)
        }
      }
    }
  }

  func testKeyBondedSDJWT_AsyncSignerThrows_PropagatesInsteadOfNilKbJwt() async throws {
    let issuerSignedSDJWT = try await issueSampleSDJWT()
    let kbJWT = try KBJWT(
      header: DefaultJWSHeaderImpl(algorithm: .ES256),
      kbJwtPayload: .init([
        Keys.nonce.rawValue: "n-1",
        Keys.aud.rawValue: "https://verifier.example.com",
        Keys.iat.rawValue: Int(Date().timeIntervalSince1970),
        Keys.sdHash.rawValue: "test-hash"
      ])
    )

    do {
      _ = try await SignedSDJWT.keyBondedSDJWT(
        signedSDJWT: issuerSignedSDJWT,
        kbJWT: kbJWT,
        holdersPrivateKey: ThrowingAsyncSigner()
      )
      XCTFail("Expected KB-JWT signing error to propagate")
    } catch is ThrowingAsyncSigner.SignerError {
      // expected
    }
  }

  func testKeyBondedSDJWT_ValidSigner_ProducesNonNilKbJwt() async throws {
    let issuerSignedSDJWT = try await issueSampleSDJWT()
    let kbJWT = try KBJWT(
      header: DefaultJWSHeaderImpl(algorithm: .ES256),
      kbJwtPayload: .init([
        Keys.nonce.rawValue: "n-1",
        Keys.aud.rawValue: "https://verifier.example.com",
        Keys.iat.rawValue: Int(Date().timeIntervalSince1970),
        Keys.sdHash.rawValue: "test-hash"
      ])
    )

    let signed = try await SignedSDJWT.keyBondedSDJWT(
      signedSDJWT: issuerSignedSDJWT,
      kbJWT: kbJWT,
      holdersPrivateKey: TestP256AsyncSigner(secKey: holdersKeyPair.private)
    )
    XCTAssertNotNil(signed.kbJwt, "kbJwt must be present when signing succeeds")
  }
}
