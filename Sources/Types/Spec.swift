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

/// Selective Disclosure for JWTs (SD-JWT)
/// Reference: [SD-JWT Specification](https://datatracker.ietf.org/doc/draft-ietf-oauth-selective-disclosure-jwt/)
struct SdJwtSpec {
  /// Digests of Disclosures for object properties
  static let claimSD = "_sd"
  
  /// Hash algorithm used to generate Disclosure digests and digest over presentation
  static let claimSDAlg = "_sd_alg"
  
  /// Digest of the SD-JWT to which the KB-JWT is tied
  static let claimSDHash = "sd_hash"
  
  /// Digest of the Disclosure for an array element
  static let claimArrayElementDigest = "..."
  
  // MARK: - Header parameters for JWS JSON
  /// An array of strings where each element is an individual Disclosure
  static let jwsJSONDisclosures = "disclosures"
  
  /// Present only in an SD-JWT+KB, the Key Binding JWT
  static let jwsJSONKBJWT = "kb_jwt"
  
  // MARK: - Other Constants
  static let disclosureSeparator: Character = "~"
  
  // MARK: - Media Types
  static let mediaSubtypeSDJWT = "sd-jwt"
  static let mediaTypeApplicationSDJWT = "application/\(mediaSubtypeSDJWT)"
  static let mediaSubtypeSDJWTJSON = "sd-jwt+json"
  static let mediaTypeApplicationSDJWTJSON = "application/\(mediaSubtypeSDJWTJSON)"
  static let mediaSubtypeKBJWT = "kb+jwt"
  static let mediaTypeApplicationKBJWTJSON = "application/\(mediaSubtypeKBJWT)"
  static let suffixSDJWT = "+sd-jwt"
  
  static let registeredNonDisclosableClaims: Set<String> =
  [
    "iss",
    "nbf",
    "exp",
    "cnf",
    "vct",
    "vct#integrity",
    "status"
  ]
}

/// JSON Web Signature (JWS) Specification
/// Reference: [RFC 7515](https://datatracker.ietf.org/doc/html/rfc7515)
struct RFC7515 {
  static let jwsJSONHeader = "header"
  static let jwsJSONProtected = "protected"
  static let jwsJSONSignature = "signature"
  static let jwsJSONSignatures = "signatures"
  static let jwsJSONPayload = "payload"
}

/// SD-JWT-based Verifiable Credentials Specification
/// Reference: [SD-JWT-VC](https://datatracker.ietf.org/doc/draft-ietf-oauth-sd-jwt-vc/)
struct SdJwtVcSpec {
  static let wellKnownSuffixJWTVcIssuer = "jwt-vc-issuer"
  static let wellKnownJWTVcIssuer = "/.well-known/\(wellKnownSuffixJWTVcIssuer)"
  
  // MARK: - Media Types
  static let mediaSubtypeDCSdJWT = "dc+sd-jwt"
  static let mediaTypeApplicationDCSdJWT = "application/\(mediaSubtypeDCSdJWT)"
  
  // MARK: - Issuer Metadata
  static let issuer = "issuer"
  
  // MARK: - Type Metadata
  static let hashIntegrity = "#integrity"
  static let vct = "vct"
  static let vctIntegrity = "\(vct)\(hashIntegrity)"
  static let name = "name"
  static let description = "description"
  static let extends = "extends"
  static let extendsIntegrity = "\(extends)\(hashIntegrity)"
  static let display = "display"
  static let claims = "claims"
  static let schema = "schema"
  static let schemaURI = "schema_uri"
  static let schemaURIIntegrity = "\(schemaURI)\(hashIntegrity)"
  static let claimPath = "path"
  static let claimDisplay = "display"
  static let claimMandatory = "mandatory"
  static let claimSD = "sd"
  static let claimSDAlways = "always"
  static let claimSDAllowed = "allowed"
  static let claimSDNever = "never"
  static let claimSVGID = "svg_id"
  static let claimLang = "lang"
  static let claimLabel = "label"
  static let claimDescription = description
  static let lang = "lang"
  static let rendering = "rendering"
  static let simple = "simple"
  static let svgTemplates = "svg_templates"
  static let logo = "logo"
  static let logoURI = "uri"
  static let logoURIIntegrity = "\(logoURI)\(hashIntegrity)"
  static let logoAltText = "alt_text"
  static let backgroundColor = "background_color"
  static let textColor = "text_color"
  static let svgURI = "uri"
  static let svgURIIntegrity = "\(svgURI)\(hashIntegrity)"
  static let svgProperties = "properties"
  static let svgOrientation = "orientation"
  static let svgOrientationPortrait = "portrait"
  static let svgOrientationLandscape = "landscape"
  static let svgColorScheme = "color_scheme"
  static let svgColorSchemeLight = "light"
  static let svgColorSchemeDark = "dark"
  static let svgContrast = "contrast"
  static let svgContrastNormal = "normal"
  static let svgContrastHigh = "high"
}

/// JSON Web Token (JWT) Specification
/// Reference: [RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519)
struct RFC7519 {
  static let issuer = "iss"
  static let subject = "sub"
  static let audience = "aud"
  static let expirationTime = "exp"
  static let notBefore = "nbf"
  static let issuedAt = "iat"
  static let jwtID = "jti"
}
