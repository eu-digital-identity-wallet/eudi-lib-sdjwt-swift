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

/// `SDJWTVerifier` is a class for verifying SD JSON Web Tokens (SDJWT) in a Swift application.
/// This class provides comprehensive methods to validate both cases of Issuance to a holder and presentation to a verifier
///
class SDJWTVerifier {

  // MARK: - Properties

  /// The signed SDJWT object to be verified.
  let sdJwt: SignedSDJWT

  // MARK: - Lifecycle
  /// Initializes the verifier with a parser that throws an error if the SDJWT cannot be obtained.
  ///
  /// - Parameters:
  ///   - parser: A parser conforming to `ParserProtocol`.
  /// - Throws: An error if the SDJWT cannot be obtained.
  ///
  public  init(parser: ParserProtocol) throws {
    self.sdJwt = try parser.getSignedSdJwt()
  }

  /// Initializes the verifier with a pre-existing SDJWT.
  ///
  /// - Parameters:
  ///   - sdJwt: A pre-existing `SignedSDJWT` object.
  ///
  public  init(sdJwt: SignedSDJWT) {
    self.sdJwt = sdJwt
  }

  // MARK: - Methods

  /// Verifies the issuance of the SDJWT.
  ///
  /// - Parameters:
  ///   - issuersSignatureVerifier: A closure that verifies the issuer's signature.
  ///   - disclosuresVerifier: A closure that verifies the disclosures.
  ///   - claimVerifier: An optional closure to verify claims.
  /// - Returns: A `Result` containing the verified `SignedSDJWT` or an error.
  ///
  public  func verifyIssuance(issuersSignatureVerifier: (JWS) throws -> SignatureVerifier,
                              disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier,
                              claimVerifier: ((_ nbf: Int?, _ exp: Int?) throws -> ClaimsVerifier)? = nil) rethrows -> Result<SignedSDJWT, Error> {
    Result {
      try self.verify(issuersSignatureVerifier: issuersSignatureVerifier, disclosuresVerifier: disclosuresVerifier, claimVerifier: claimVerifier).get()
    }
  }

  /// Verifies the presentation of the SDJWT, including key binding if provided.
  ///
  /// - Parameters:
  ///   - issuersSignatureVerifier: A closure that verifies the issuer's signature.
  ///   - disclosuresVerifier: A closure that verifies the disclosures.
  ///   - claimVerifier: An optional closure to verify claims.
  ///   - keyBindingVerifier: An optional closure to verify key binding.
  /// - Returns: A `Result` containing the verified `SignedSDJWT` or an error.
  ///
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

  /// Verifies the common fields of the SDJWT for both cases (issuance and presentation).
  ///
  /// - Parameters:
  ///   - issuersSignatureVerifier: A closure that verifies the issuer's signature.
  ///   - disclosuresVerifier: A closure that verifies the disclosures.
  ///   - claimVerifier: An optional closure to verify claims.
  /// - Returns: A `Result` containing the verified `SignedSDJWT` or an error.
  ///
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

  /// Performs verification using a custom verifier protocol.
  ///
  /// - Parameter verifierProtocol: A closure that provides a custom verifier conforming to `AnyVerifierProtocol`.
  /// - Returns: Self after performing the verification.
  /// - Throws: An error if the verification fails.
  ///
  public func with(verifierProtocol: () -> any VerifierProtocol) throws -> Self {
    try verifierProtocol().verify()
    return self
  }

  /// Performs verification using a custom verifier protocol.
  ///
  /// - Parameter verifierProtocol: A closure that provides a custom verifier conforming to `AnyVerifierProtocol`.
  /// - Returns: Self after performing the verification.
  /// - Throws: An error if the verification fails.
  ///
  internal func unsingedVerify(disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier) -> Result<Void, Error> {
    Result {
      _ = try disclosuresVerifier(sdJwt).verify()
    }
  }

}
