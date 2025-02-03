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
import SwiftyJSON

import Foundation
import SwiftyJSON

public struct SdJwtVcTypeMetadata {
  public let vct: Vct
  public let vctIntegrity: DocumentIntegrity?
  public let name: String?
  public let description: String?
  public let extends: URL?
  public let extendsIntegrity: DocumentIntegrity?
  public let display: Display?
  public let claims: [ClaimMetadata]?
  public let schema: JSON?
  public let schemaUri: URL?
  public let schemaUriIntegrity: DocumentIntegrity?
  
  public init(
    vct: Vct,
    vctIntegrity: DocumentIntegrity? = nil,
    name: String? = nil,
    description: String? = nil,
    extends: URL? = nil,
    extendsIntegrity: DocumentIntegrity? = nil,
    display: Display? = nil,
    claims: [ClaimMetadata]? = nil,
    schema: JSON? = nil,
    schemaUri: URL? = nil,
    schemaUriIntegrity: DocumentIntegrity? = nil
  ) throws {
    
    guard schema == nil || schemaUri == nil else {
      throw SDJWTError.error("Conflicting schema definitions")
    }
    
    self.vct = vct
    self.vctIntegrity = vctIntegrity
    self.name = name
    self.description = description
    self.extends = extends
    self.extendsIntegrity = extendsIntegrity
    self.display = display
    self.claims = claims
    self.schema = schema
    self.schemaUri = schemaUri
    self.schemaUriIntegrity = schemaUriIntegrity
  }

  public struct Vct {
    public let value: String
    
    public init(value: String) throws {
      guard !value.isEmpty else {
        throw SDJWTError.error("Vct value must not be blank")
      }
      self.value = value
    }
  }

  public struct ClaimMetadata {
    public let path: String
    public let display: [ClaimDisplay]?
    public let selectivelyDisclosable: ClaimSelectivelyDisclosable
    public let svgId: String?
    
    public init(
      path: String,
      display: [ClaimDisplay]? = nil,
      selectivelyDisclosable: ClaimSelectivelyDisclosable = .allowed,
      svgId: String? = nil
    ) {
      self.path = path
      self.display = display
      self.selectivelyDisclosable = selectivelyDisclosable
      self.svgId = svgId
    }
  }

  public struct ClaimDisplay {
    public let lang: String
    public let label: String
    public let description: String?
    
    public init(
      lang: String,
      label: String,
      description: String? = nil
    ) {
      self.lang = lang
      self.label = label
      self.description = description
    }
  }

  public enum ClaimSelectivelyDisclosable: String {
    case always
    case allowed
    case never
  }

  public struct Display {
    public let value: [DisplayMetadata]
    
    public init(value: [DisplayMetadata]) throws {
      let uniqueLangs = Set(value.map { $0.lang })
      guard value.count == uniqueLangs.count else {
        throw SDJWTError.error("Each language must appear only once in the display list")
      }
      self.value = value
    }
  }

  public struct DisplayMetadata {
    public let lang: String
    public let name: String
    public let description: String?
    public let rendering: RenderingMetadata?
    
    public init(
      lang: String,
      name: String,
      description: String? = nil,
      rendering: RenderingMetadata? = nil
    ) {
      self.lang = lang
      self.name = name
      self.description = description
      self.rendering = rendering
    }
  }

  public struct RenderingMetadata {
    public let simple: SimpleRenderingMethod?
    public let svgTemplates: [SvgTemplate]?
    
    public init(
      simple: SimpleRenderingMethod? = nil,
      svgTemplates: [SvgTemplate]? = nil
    ) {
      self.simple = simple
      self.svgTemplates = svgTemplates
    }
  }

  public struct SimpleRenderingMethod {
    public let logo: LogoMetadata?
    public let backgroundColor: String?
    public let textColor: String?
    
    public init(
      logo: LogoMetadata? = nil,
      backgroundColor: String? = nil,
      textColor: String? = nil
    ) {
      self.logo = logo
      self.backgroundColor = backgroundColor
      self.textColor = textColor
    }
  }

  public struct SvgTemplate {
    public let uri: URL
    public let uriIntegrity: DocumentIntegrity?
    public let properties: SvgTemplateProperties?
    
    public init(
      uri: URL,
      uriIntegrity: DocumentIntegrity? = nil,
      properties: SvgTemplateProperties? = nil
    ) {
      self.uri = uri
      self.uriIntegrity = uriIntegrity
      self.properties = properties
    }
  }

  public struct SvgTemplateProperties {
    public let orientation: String?
    public let colorScheme: String?
    public let contrast: String?
    
    public init(
      orientation: String? = nil,
      colorScheme: String? = nil,
      contrast: String? = nil
    ) throws {
      guard orientation != nil || colorScheme != nil || contrast != nil else {
        throw SDJWTError.error("At least one property must be specified")
      }
      self.orientation = orientation
      self.colorScheme = colorScheme
      self.contrast = contrast
    }
  }

  public struct LogoMetadata {
    public let uri: URL
    public let uriIntegrity: DocumentIntegrity?
    public let altText: String?
    
    public init(
      uri: URL,
      uriIntegrity: DocumentIntegrity? = nil,
      altText: String? = nil
    ) {
      self.uri = uri
      self.uriIntegrity = uriIntegrity
      self.altText = altText
    }
  }

  public struct DocumentIntegrity {
    public let value: String
    
    public init(value: String) {
      self.value = value
    }
  }
}
