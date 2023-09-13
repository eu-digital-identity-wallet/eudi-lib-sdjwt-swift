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

protocol VerifierProtocol {
  associatedtype ReturnType

  @discardableResult
  func verify() throws -> ReturnType
}

enum SDJWTVerifierError: Error {
  case parsingError
  case invalidJwt
  case keyBindingFailed(description: String)
  case invalidDisclosure(disclosures: [Disclosure])
  case missingOrUnknownHashingAlgorithm
  case nonUniqueDisclosures
  case nonUniqueDisclosureDigests
  case missingDigests(disclosures: [Disclosure])
  case noAlgorithmProvided
  case failedToCreateVerifier
  case expiredJwt
  case notValidYetJwt
}

class SDJWTVerifier {

  // MARK: - Properties

  let sdJwt: SignedSDJWT

  // MARK: - Lifecycle

  public  init(parser: ParserProtocol) throws {
    self.sdJwt = try parser.getSignedSdJwt()
  }

  public  init(sdJwt: SignedSDJWT) {
    self.sdJwt = sdJwt
  }

  // MARK: - Methods

  public  func verifyIssuance(issuersSignatureVerifier: (JWS) throws -> SignatureVerifier,
                      disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier,
                      claimVerifier: ((_ nbf: Int?, _ exp: Int?) throws -> ClaimsVerifier)? = nil) rethrows -> Result<SignedSDJWT, Error> {
    Result {
      try self.verify(issuersSignatureVerifier: issuersSignatureVerifier, disclosuresVerifier: disclosuresVerifier, claimVerifier: claimVerifier).get()
    }
  }

  public func verifyPresentation(issuersSignatureVerifier: (JWS) throws -> SignatureVerifier,
                          disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier,
                          claimVerifier: ((_ nbf: Int?, _ exp: Int?) throws -> ClaimsVerifier)? = nil,
                          keyBindingVerifier: ((JWS, JWK) throws -> KeyBindingVerifier)? = nil) -> Result<SignedSDJWT, Error> {
    Result {
      let commonVerifyResult = self.verify(issuersSignatureVerifier: issuersSignatureVerifier, disclosuresVerifier: disclosuresVerifier, claimVerifier: claimVerifier)

      if let keyBindingVerifier {
        let sdjwt = try commonVerifyResult.get()
        guard let kbJwt = sdjwt.kbJwt else {
          throw SDJWTVerifierError.keyBindingFailed(description: "No KB provided")
        }
        let extractedKey = try sdjwt.extractHoldersPublicKey()
        try keyBindingVerifier(kbJwt, extractedKey).verify()
      }
      return try commonVerifyResult.get()
    }
  }

  private func verify(issuersSignatureVerifier: (JWS) throws -> SignatureVerifier,
                      disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier,
                      claimVerifier: ((_ nbf: Int?, _ exp: Int?) throws -> ClaimsVerifier)? = nil) -> Result<SignedSDJWT, Error> {
    Result {
      _ = try issuersSignatureVerifier(sdJwt.jwt).verify()
      // The recreated json, and the disclosures
      let output = try disclosuresVerifier(sdJwt).verify()
      try claimVerifier?(output.recreatedClaims[Keys.nbf.rawValue].int, output.recreatedClaims[Keys.exp.rawValue].int).verify()
      return sdJwt
    }
  }

  func with(verifierProtocol: () -> any VerifierProtocol) throws -> Self {
    try verifierProtocol().verify()
    return self
  }

  func unsingedVerify(disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier) -> Result<Void, Error> {
    Result {
      _ = try disclosuresVerifier(sdJwt).verify()
    }
  }

}
