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
  func verify() throws -> ReturnType
}

enum SDJWTVerifierError: Error {
  case parsingError
  case invalidJwt
  case keyBidningFailed(desription: String)
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

  init(parser: ParserProtocol) throws {
    self.sdJwt = try parser.getSignedSdJwt()
  }

  init(sdJwt: SignedSDJWT) {
    self.sdJwt = sdJwt
  }

  // MARK: - Methods
  
  func unsingedVerify(disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier) -> Result<Void, Error> {
    Result {
      _ = try disclosuresVerifier(sdJwt).verify()
    }
  }

  func verifyIssuance<KeyType>(issuersSignatureVerifier: (JWS) throws -> SignatureVerifier<KeyType>,
                               disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier,
                               claimVerifier: ((_ nbf: Int?, _ exp: Int?) throws -> ClaimsVerifier)? = nil) -> Result<SignedSDJWT, Error> {
    Result {
      try self.verify(issuersSignatureVerifier: issuersSignatureVerifier, disclosuresVerifier: disclosuresVerifier, claimVerifier: claimVerifier).get()
    }
  }


  func verifyPresentation<IssuersKeyType, HoldersKeyType>(issuersSignatureVerifier: (JWS) -> SignatureVerifier<IssuersKeyType>,
                                                          disclosuresVerifier: (SignedSDJWT) -> DisclosuresVerifier,
                                                          claimVerifier: ((_ nbf: Int?, _ exp: Int?) throws -> ClaimsVerifier)? = nil,
                                                          keyBindingVerifier: (() -> SignatureVerifier<HoldersKeyType>)? = nil) -> Result<SignedSDJWT, Error> {
    Result {
      let commonVerifyResult = self.verify(issuersSignatureVerifier: issuersSignatureVerifier, disclosuresVerifier: disclosuresVerifier, claimVerifier: claimVerifier)
      try keyBindingVerifier?().verify()
      return try commonVerifyResult.get()
    }
  }


  private func verify<KeyType>(issuersSignatureVerifier: (JWS) throws -> SignatureVerifier<KeyType>,
                               disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier,
                               claimVerifier: ((_ nbf: Int?, _ exp: Int?) throws -> ClaimsVerifier)? = nil) -> Result<SignedSDJWT, Error> {
    Result {
      _ = try issuersSignatureVerifier(sdJwt.jwt).verify()
      // The recreated json, and the disclosures
      let output = try disclosuresVerifier(sdJwt).verify()
      let isValid = try claimVerifier?(output.recreatedClaims[Keys.nbf.rawValue].int, output.recreatedClaims[Keys.exp.rawValue].int).verify()
      return sdJwt
    }
  }

  func with(verifierProtocol: () -> any VerifierProtocol) throws -> Self {
    let result = try verifierProtocol().verify()
    return self
  }

  func verifyIat(iat: Int, dateCollision: Date) throws {

  }
}
