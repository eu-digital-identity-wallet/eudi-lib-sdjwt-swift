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

public class SDJWTIssuer {

  /// Enum to represent the purpose of the JWT.
  enum Purpose {
    /// Used for JWT issuance.
    case issuance(JWSRegisteredFieldsHeader, ClaimSet)
    /// Used for JWT presentation.
    case presentation(SignedSDJWT, [Disclosure], KBJWT?)
  }

  // MARK: - Lifecycle
  /// Private initializer to prevent direct instantiation of the class.
  /// 
  private init() {}

  // MARK: - Methods

  /// Issue a signed SDJWT.
  ///
  /// - Parameters:
  ///   - issuersPrivateKey: The private key used for signing the JWT.
  ///   - header: The JWSHeader for the JWT.
  ///   - decoys: The number of decoys to include in the JWT.
  ///   - buildSDJWT: A closure that builds the SDJWTObject.
  /// - Returns: The signed SDJWT.
  /// - Throws: An error if there's an issue with JWT creation or signing.
  ///
  public static func issue<KeyType>(issuersPrivateKey: KeyType,
                             header: JWSRegisteredFieldsHeader,
                             decoys: Int = 0,
                             @SDJWTBuilder buildSDJWT: () throws -> SdElement) throws -> SignedSDJWT {

    let factory = SDJWTFactory(decoysLimit: decoys)
    let claimSet = try factory.createSDJWTPayload(sdJwtObject: SDJWTBuilder.build(builder: buildSDJWT)).get()
    let signedSDJWT = try self.createSDJWT(purpose: .issuance(header, claimSet), signingKey: issuersPrivateKey)
    return signedSDJWT
  }

  /// Present a signed SDJWT.
  /// Adding holder's key binding information
  /// - Parameters:
  ///   - holdersPrivateKey: The private key of the holder.
  ///   - signedSDJWT: The signed SDJWT to present.
  ///   - disclosuresToPresent: The disclosures to include in the presentation.
  ///   - keyBindingJWT: An optional KBJWT for key binding.
  ///
  public static func presentation<KeyType>(
    holdersPrivateKey: KeyType,
    signedSDJWT: SignedSDJWT,
    disclosuresToPresent: [Disclosure],
    keyBindingJWT: KBJWT?
  ) throws -> SignedSDJWT {
    try createSDJWT(
      purpose: .presentation(
        signedSDJWT, 
        disclosuresToPresent,
        keyBindingJWT
      ),
      signingKey: holdersPrivateKey
    )
  }

  /// Present a signed SDJWT.
  /// Present the sdjwt without any key binding information
  /// - Parameters:
  ///   - signedSDJWT: The signed SDJWT to present.
  ///   - disclosuresToPresent: The disclosures to include in the presentation.
  ///
  public static func presentation(signedSDJWT: SignedSDJWT,
                           disclosuresToPresent: [Disclosure]) throws -> SignedSDJWT {
    return try createSDJWT(purpose: .presentation(signedSDJWT, disclosuresToPresent, nil), signingKey: Void.self)

  }

  /// Create a signed SDJWT based on the specified purpose.
  ///
  /// - Parameters:
  ///   - purpose: The purpose of the JWT (issuance or presentation).
  ///   - signingKey: The key used for signing.
  /// - Returns: The signed SDJWT.
  /// - Throws: An error if there's an issue with JWT creation or signing.
  ///
  static func createSDJWT<KeyType>(purpose: Purpose, signingKey: KeyType) throws -> SignedSDJWT {
    switch purpose {
    case .issuance(let JWSHeader, let claimSet):
      let ungsingedSDJWT = try SDJWT(jwt: JWT(header: JWSHeader, payload: claimSet.value), disclosures: claimSet.disclosures, kbJWT: nil)
      return try createSignedSDJWT(sdJwt: ungsingedSDJWT, issuersPrivateKey: signingKey)
      // ..........
    case .presentation(let signedJWT, let selectedDisclosures, let KBJWT):
      let signedJWT = signedJWT.disclosuresToPresent(disclosures: selectedDisclosures)
      if let KBJWT {
        return try createKeyBondedSDJWT(signedSDJWT: signedJWT, kbJWT: KBJWT, holdersPrivateKey: signingKey)
      }
      return signedJWT
      // ..........
    }

  }

  /// Create a signed SDJWT without key binding.
  ///
  /// - Parameters:
  ///   - sdJwt: The unsigned SDJWT.
  ///   - issuersPrivateKey: The private key of the issuer.
  /// - Returns: The signed SDJWT.
  /// - Throws: An error if there's an issue with JWT signing.
  ///
  private static func createSignedSDJWT<KeyType>(sdJwt: SDJWT, issuersPrivateKey: KeyType) throws -> SignedSDJWT {
    try SignedSDJWT.nonKeyBondedSDJWT(sdJwt: sdJwt, issuersPrivateKey: issuersPrivateKey)
  }

  /// Create a key-bonded signed SDJWT.
  ///
  /// - Parameters:
  ///   - signedSDJWT: The signed SDJWT.
  ///   - kbJWT: The KBJWT for key binding.
  ///   - holdersPrivateKey: The private key of the holder.
  /// - Returns: The key-bonded signed SDJWT.
  /// - Throws: An error if there's an issue with JWT signing or key binding.
  ///
  private static func createKeyBondedSDJWT<KeyType>(signedSDJWT: SignedSDJWT, kbJWT: JWT, holdersPrivateKey: KeyType) throws -> SignedSDJWT {
    try SignedSDJWT.keyBondedSDJWT(signedSDJWT: signedSDJWT, kbJWT: kbJWT, holdersPrivateKey: holdersPrivateKey)
  }

}
