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

  let parser: CompactParser

  init(serialisedString: String, serialisationFormat: SerialisationFormat) {
    self.parser = CompactParser(serialisedString: serialisedString)
  }

  func unsingedVerify(disclosuresVerifier: (CompactParser) throws -> DisclosuresVerifier) -> Result<Void, Error> {
    Result {
      let hasValidDisclosures = try disclosuresVerifier(parser).verify()
    }
  }

  func verifyIssuance<KeyType>(issuersSignatureVerifier: (JWS) throws -> SignatureVerifier<KeyType>,
                               disclosuresVerifier: (CompactParser) throws -> DisclosuresVerifier) -> Result<Void, Error> {
    Result {
      let sdJwt = try parser.getSignedSdJwt()
      let hasValidSignature = try issuersSignatureVerifier(parser.getSignedSdJwt().jwt).verify()
      let hasValidDisclosures = try disclosuresVerifier(parser).verify()

    }
  }

  func verify<IssuersKeyType, HoldersKeyType>(issuersSignatureVerifier: (JWS) -> SignatureVerifier<IssuersKeyType>,
                                              disclosuresVerifier: (CompactParser) -> DisclosuresVerifier,
                                              keyBindingVerifier: (() -> SignatureVerifier<HoldersKeyType>)? = nil) -> Result<Void, Error> {
    Result {
      try self.verifyIssuance(issuersSignatureVerifier: issuersSignatureVerifier, disclosuresVerifier: disclosuresVerifier)
      if let keyBindingVerifier {
        try keyBindingVerifier().verify()
      }
    }
  }

  func with(verifierProtocol: () -> any VerifierProtocol) throws -> Self {
    try verifierProtocol().verify()
    return self
  }
}
