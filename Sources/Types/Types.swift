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

public typealias KeyPair = (public: SecKey, private: SecKey)
public typealias JWTString = String
public typealias Nonce = String

public enum SDJWTError: Error, Equatable {
  case sdAsKey
  case nullJSONValue
  case encodingError
  case discloseError
  case serializationError
  case nonObjectFormat(ofElement: String)
  case keyCreation
  case algorithmMissMatch
  case noneAsAlgorithm
  case macAsAlgorithm
  case randomGenerationFailed
  case error(String)
}

public enum SDJWTVerifierError: Error {
  case parsingError
  case invalidJwt(description: String?)
  case invalidJwk
  case invalidIssuer
  case keyBindingFailed(description: String)
  case invalidDisclosure(disclosures: [Disclosure])
  case missingOrUnknownHashingAlgorithm
  case nonUniqueDisclosures
  case nonUniqueDisclosureDigests
  case missingDigests(disclosures: [Disclosure])
  case noAlgorithmProvided
  case algorithmNotAllowed(algorithm: String)
  case failedToCreateVerifier
  case expiredJwt
  case notValidYetJwt
  case invalidTypeMetadataURL
}

public enum TypeMetadataError: Error, Equatable {
  case invalidPayload
  case missingOrInvalidVCT
  case vctMismatch
  case duplicateLanguageInDisplay
  case missingDisplayProperties
  case invalidTypeMetadataURL
  case unsupportedRetreivalMethod
  case vctIntegrityCheckFailed
  case schemaIntegrityCheckFailed
  case emptyRequiredVcts
  case unexpectedVct
  case circularReference
  case invalidSchemaURL
  case invalidSchema
  case invalidDicslosuresDipslay
  case conflictingSchemaDefinition
  case missingSchemaUriIntegrity
  case schemaValidationFailed(description: String)
  case missingTypeMetadata
  case missingDisclosuresForValidation
  case expectedDisclosureMissing(path: ClaimPath)
  case unexpectedDisclosurePresent(path: ClaimPath)
  case mandatoryPropertyOverrideNotAllowed(path: ClaimPath)
  case selectivelyDisclosablePropertyOverrideNotAllowed(path: ClaimPath)
  case integrityValidationFailed
}

// MARK: - Redacted error descriptions

extension SDJWTVerifierError: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    switch self {
    case .parsingError:
      return "parsingError"
    case .invalidJwt(let description):
      return "invalidJwt(\(description ?? "nil"))"
    case .invalidJwk:
      return "invalidJwk"
    case .invalidIssuer:
      return "invalidIssuer"
    case .keyBindingFailed(let description):
      return "keyBindingFailed(\(description))"
    case .invalidDisclosure(let disclosures):
      return "invalidDisclosure(count: \(disclosures.count), content: REDACTED)"
    case .missingOrUnknownHashingAlgorithm:
      return "missingOrUnknownHashingAlgorithm"
    case .nonUniqueDisclosures:
      return "nonUniqueDisclosures"
    case .nonUniqueDisclosureDigests:
      return "nonUniqueDisclosureDigests"
    case .missingDigests(let disclosures):
      return "missingDigests(count: \(disclosures.count), content: REDACTED)"
    case .noAlgorithmProvided:
      return "noAlgorithmProvided"
    case .algorithmNotAllowed(let algorithm):
      return "algorithmNotAllowed(\(algorithm))"
    case .failedToCreateVerifier:
      return "failedToCreateVerifier"
    case .expiredJwt:
      return "expiredJwt"
    case .notValidYetJwt:
      return "notValidYetJwt"
    case .invalidTypeMetadataURL:
      return "invalidTypeMetadataURL"
    }
  }

  public var debugDescription: String { description }
}

extension SDJWTError: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    switch self {
    case .sdAsKey:
      return "sdAsKey"
    case .nullJSONValue:
      return "nullJSONValue"
    case .encodingError:
      return "encodingError"
    case .discloseError:
      return "discloseError"
    case .serializationError:
      return "serializationError"
    case .nonObjectFormat:
      // ofElement is the serialised sdJwtObject, which contains claim values.
      return "nonObjectFormat(ofElement: REDACTED)"
    case .keyCreation:
      return "keyCreation"
    case .algorithmMissMatch:
      return "algorithmMissMatch"
    case .noneAsAlgorithm:
      return "noneAsAlgorithm"
    case .macAsAlgorithm:
      return "macAsAlgorithm"
    case .randomGenerationFailed:
      return "randomGenerationFailed"
    case .error(let message):
      return "error(\(message))"
    }
  }

  public var debugDescription: String { description }
}

/// Static Keys Used by the JWT
public enum Keys: String {
  case sd = "_sd"
  case dots = "..."
  case sdAlg = "_sd_alg"
  case sdHash = "sd_hash"
  case iss
  case iat
  case sub
  case exp
  case jti
  case nbf
  case aud
  case cnf
  case jwk
  case nonce
  case none
}

public struct DID: Sendable {

  public static let DID_SYNTAX = try? NSRegularExpression(pattern: "^did:[a-z0-9]+:(([A-Z.a-z0-9]|-|_|%[0-9A-Fa-f][0-9A-Fa-f])*:)*([A-Z.a-z0-9]|-|_|%[0-9A-Fa-f][0-9A-Fa-f])+$", options: [])

  public let uri: URL

  public init(uri: URL) {
    self.uri = uri
  }

  public var string: String {
    return uri.absoluteString
  }

  public static func parse(_ string: String, regex: NSRegularExpression? = Self.DID_SYNTAX) -> DID? {
    guard
      let regex = regex,
      regex.matches(
        in: string,
        options: [],
        range: NSRange(
          location: 0,
          length: string.utf16.count
        )
      ).isEmpty == false,
      let url = URL(string: string)
    else {
      return nil
    }

    return DID(uri: url)
  }
}
