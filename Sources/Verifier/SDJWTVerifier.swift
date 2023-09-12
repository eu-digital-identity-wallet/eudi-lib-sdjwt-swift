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
}

class SDJWTVerifier {

  let sdJwt: SignedSDJWT

  init(parser: ParserProtocol) throws {
    self.sdJwt = try parser.getSignedSdJwt()
  }

  init(sdJwt: SignedSDJWT) {
    self.sdJwt = sdJwt
  }

  func unsingedVerify(disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier) -> Result<Void, Error> {
    Result {
      _ = try disclosuresVerifier(sdJwt).verify()
    }
  }

  func verifyIssuance<KeyType>(issuersSignatureVerifier: (JWS) throws -> SignatureVerifier<KeyType>,
                               disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier,
                               claimVerifier: () throws -> ClaimsVerifier) -> Result<SignedSDJWT, Error> {
    Result {
      _ = try issuersSignatureVerifier(sdJwt.jwt).verify()
      // The recreated json, and the disclosures
      let output = try disclosuresVerifier(sdJwt).verify()
      try claimVerifier().verify()
      return sdJwt
    }
  }

  func verifyPresentation<IssuersKeyType, HoldersKeyType>(issuersSignatureVerifier: (JWS) -> SignatureVerifier<IssuersKeyType>,
                                                          disclosuresVerifier: (SignedSDJWT) -> DisclosuresVerifier,
                                                          claimVerifier: () throws -> ClaimsVerifier,
                                                          keyBindingVerifier: (() -> SignatureVerifier<HoldersKeyType>)? = nil) -> Result<Void, Error> {
    Result {
      self.verifyIssuance(issuersSignatureVerifier: issuersSignatureVerifier, disclosuresVerifier: disclosuresVerifier, claimVerifier: claimVerifier)
      if let keyBindingVerifier {
        try keyBindingVerifier().verify()
      }
    }
  }

  func with(verifierProtocol: () -> any VerifierProtocol) throws -> Self {
    try verifierProtocol().verify()
    return self
  }

  func verifyIat(iat: Int, dateCollision: Date) throws {

  }
}
