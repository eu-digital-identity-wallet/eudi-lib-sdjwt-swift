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

public protocol VerifierProtocol {
  associatedtype ReturnType

  @discardableResult
  func verify() throws -> ReturnType
}

public enum SDJWTVerifierError: Error {
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
public class SDJWTVerifier {

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
                              claimVerifier: ((_ nbf: Int?, _ exp: Int?) throws -> ClaimsVerifier)? = nil) rethrows -> Result<SignedSDJWT, Error> {
    Result {
      try self.verify(issuersSignatureVerifier: issuersSignatureVerifier, claimVerifier: claimVerifier).get()
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
                                 claimVerifier: ((_ nbf: Int?, _ exp: Int?) throws -> ClaimsVerifier)? = nil,
                                 keyBindingVerifier: ((JWS, JWK) throws -> KeyBindingVerifier)? = nil) -> Result<SignedSDJWT, Error> {
    Result {
      let commonVerifyResult = self.verify(issuersSignatureVerifier: issuersSignatureVerifier, claimVerifier: claimVerifier)
      let sdjwt = try commonVerifyResult.get()

      if let keyBindingVerifier {
        guard let kbJwt = sdjwt.kbJwt else {
          throw SDJWTVerifierError.keyBindingFailed(description: "No KB provided")
        }
        let extractedKey = try sdjwt.extractHoldersPublicKey()
        try keyBindingVerifier(kbJwt, extractedKey).verify()
        
        if let sdHash = try? kbJwt.payloadJSON()["sd_hash"].stringValue {
          if sdHash != sdjwt.delineatedCompactSerialisation {
            throw SDJWTVerifierError.keyBindingFailed(description: "No KB provided")
          }
        } else {
          throw SDJWTVerifierError.keyBindingFailed(description: "sd_hash not present")
        }
      }
      return sdjwt
    }
  }

  public func verifyEnvelope(envelope: JWS,
                             issuersSignatureVerifier: (JWS) throws -> SignatureVerifier,
                             holdersSignatureVerifier: () throws -> SignatureVerifier,
                             claimVerifier: (_ audClaim: String, _ iat: Int) -> ClaimsVerifier) -> Result<JWS, Error> {
    Result {
      try issuersSignatureVerifier(sdJwt.jwt).verify()
      try holdersSignatureVerifier().verify()
      try DisclosuresVerifier(signedSDJWT: sdJwt).verify()

      guard
        let aud = try envelope.aud(),
        let iat = try envelope.iat() else {
        throw SDJWTVerifierError.keyBindingFailed(description: "Envelope miss-formatted")
      }
      try claimVerifier(aud, iat).verify()
      return try holdersSignatureVerifier().verify()
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
                      claimVerifier: ((_ nbf: Int?, _ exp: Int?) throws -> ClaimsVerifier)? = nil) -> Result<SignedSDJWT, Error> {
    Result {
      _ = try issuersSignatureVerifier(sdJwt.jwt).verify()
      // The recreated json, and the disclosures
      let output = try DisclosuresVerifier(signedSDJWT: sdJwt).verify()
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
  public func with(verifierProtocol: (SignedSDJWT) -> any VerifierProtocol) throws -> Self {
    try verifierProtocol(self.sdJwt).verify()
    return self
  }

  /// Performs verification using a custom verifier protocol.
  ///
  /// - Parameter verifierProtocol: A closure that provides a custom verifier conforming to `AnyVerifierProtocol`.
  /// - Returns: Self after performing the verification.
  /// - Throws: An error if the verification fails.
  ///
  internal func unsingedVerify(disclosuresVerifier: (SignedSDJWT) throws -> DisclosuresVerifier) -> Result<SignedSDJWT, Error> {
    Result {
      try disclosuresVerifier(sdJwt).verify()
      return sdJwt
    }
  }

}

extension SDJWTVerifier {
  static func verifyEnvelop() {

  }
}
