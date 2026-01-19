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


public typealias DocumentIntegrity = String


public struct SdJwtVcTypeMetadata: Decodable {
  public let vct: String
  public let vctIntegrity: String?
  public let name: String?
  public let description: String?
  public let extends: URL?
  public let extendsIntegrity: String?
  public let display: [DisplayMetadata]?
  public let claims: [ClaimMetadata]?
  
  enum CodingKeys: String, CodingKey {
    case vct
    case vctIntegrity = "vct#integrity"
    case name
    case description
    case extends
    case extendsIntegrity = "extends#integrity"
    case display
    case claims
  }
  
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    vct = try container.decode(String.self, forKey: .vct)
    vctIntegrity = try container.decodeIfPresent(String.self, forKey: .vctIntegrity)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    extends = try container.decodeIfPresent(URL.self, forKey: .extends)
    extendsIntegrity = try container.decodeIfPresent(String.self, forKey: .extendsIntegrity)
    display = try container.decodeIfPresent([DisplayMetadata].self, forKey: .display)
    claims = try container.decodeIfPresent([ClaimMetadata].self, forKey: .claims)
  }
  
  
  public init(
    vct: String,
    vctIntegrity: String? = nil,
    name: String? = nil,
    description: String? = nil,
    extends: URL? = nil,
    extendsIntegrity: String? = nil,
    display: [DisplayMetadata]? = nil,
    claims: [ClaimMetadata]? = nil
  ) throws {
    
    self.vct = vct
    self.vctIntegrity = vctIntegrity
    self.name = name
    self.description = description
    self.extends = extends
    self.extendsIntegrity = extendsIntegrity
    self.display = display
    self.claims = claims
  }
  
  
  
  public struct ClaimMetadata: Decodable {
    public let path: ClaimPath
    public let display: [ClaimDisplay]?
    public let mandatory: Bool
    public let selectivelyDisclosable: ClaimSelectivelyDisclosable
    public let svgId: String?
    
    public init(
      path: ClaimPath,
      display: [ClaimDisplay]? = nil,
      mandatory: Bool = false,
      selectivelyDisclosable: ClaimSelectivelyDisclosable = .allowed,
      svgId: String? = nil
    ) {
      self.path = path
      self.display = display
      self.mandatory = mandatory
      self.selectivelyDisclosable = selectivelyDisclosable
      self.svgId = svgId
    }
    
    enum CodingKeys: String, CodingKey {
      case path
      case display
      case mandatory
      case selectivelyDisclosable = "sd"
      case svgId
    }
    
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      path = try container.decode(ClaimPath.self, forKey: .path)
      display = try container.decodeIfPresent([ClaimDisplay].self, forKey: .display)
      mandatory = try container.decodeIfPresent(Bool.self, forKey: .mandatory) ?? false
      selectivelyDisclosable = try container.decodeIfPresent(ClaimSelectivelyDisclosable.self, forKey: .selectivelyDisclosable) ?? .allowed
      svgId = try container.decodeIfPresent(String.self, forKey: .svgId)
    }
  }
  
  public struct ClaimDisplay: Decodable {
    public let locale: String
    public let label: String
    public let description: String?

    public init(
      locale: String,
      label: String,
      description: String? = nil
    ) {
      self.locale = locale
      self.label = label
      self.description = description
    }
  }
  
  public enum ClaimSelectivelyDisclosable: String, Decodable {
    case always
    case allowed
    case never
  }
  
  public struct DisplayMetadata: Decodable {
    public let locale: String
    public let name: String
    public let description: String?
    public let rendering: RenderingMetadata?

    public init(
      locale: String,
      name: String,
      description: String? = nil,
      rendering: RenderingMetadata? = nil
    ) {
      self.locale = locale
      self.name = name
      self.description = description
      self.rendering = rendering
    }
  }
  
  public struct RenderingMetadata: Decodable {
    public let simple: SimpleRenderingMethod?
    public let svgTemplates: [SvgTemplate]?
    
    public init(
      simple: SimpleRenderingMethod? = nil,
      svgTemplates: [SvgTemplate]? = nil
    ) {
      self.simple = simple
      self.svgTemplates = svgTemplates
    }
    
    enum CodingKeys: String, CodingKey {
      case simple
      case svgTemplates = "svg_templates"
    }
  }
  
  public struct SimpleRenderingMethod: Decodable {
    public let logo: LogoMetadata?
    public let backgroundColor: String?
    public let textColor: String?
    public let backgroundImage: BackgroundImage?

    public init(
      logo: LogoMetadata? = nil,
      backgroundColor: String? = nil,
      textColor: String? = nil,
      backgroundImage: BackgroundImage? = nil
    ) {
      self.logo = logo
      self.backgroundColor = backgroundColor
      self.textColor = textColor
      self.backgroundImage = backgroundImage
    }

    enum CodingKeys: String, CodingKey {
      case logo
      case backgroundColor = "background_color"
      case textColor = "text_color"
      case backgroundImage = "background_image"
    }
  }
  
  public struct SvgTemplate: Decodable {
    public let uri: URL
    public let uriIntegrity: String?
    public let properties: SvgTemplateProperties?
    
    public init(
      uri: URL,
      uriIntegrity: String? = nil,
      properties: SvgTemplateProperties? = nil
    ) {
      self.uri = uri
      self.uriIntegrity = uriIntegrity
      self.properties = properties
    }
    
    enum CodingKeys: String, CodingKey {
      case uri
      case uriIntegrity = "uri#integrity"
      case properties
    }
  }
  
  public struct SvgTemplateProperties: Decodable {
    public let orientation: String?
    public let colorScheme: String?
    public let contrast: String?
    
    public init(
      orientation: String? = nil,
      colorScheme: String? = nil,
      contrast: String? = nil
    ) throws {
      guard orientation != nil || colorScheme != nil || contrast != nil else {
        throw TypeMetadataError.missingDisplayProperties
      }
      self.orientation = orientation
      self.colorScheme = colorScheme
      self.contrast = contrast
    }
    
    enum CodingKeys: String, CodingKey {
      case orientation
      case colorScheme = "color_scheme"
      case contrast
    }
  }
  
  public struct LogoMetadata: Decodable {
    public let uri: URL
    public let uriIntegrity: String?
    public let altText: String?
    
    public init(
      uri: URL,
      uriIntegrity: String? = nil,
      altText: String? = nil
    ) {
      self.uri = uri
      self.uriIntegrity = uriIntegrity
      self.altText = altText
    }
    
    enum CodingKeys: String, CodingKey {
      case uri
      case uriIntegrity = "uri#integrity"
      case altText = "alt_text"
    }
  }

  public struct BackgroundImage: Decodable {
    public let uri: URL
    public let uriIntegrity: DocumentIntegrity?

    public init(
      uri: URL,
      uriIntegrity: DocumentIntegrity? = nil
    ) {
      self.uri = uri
      self.uriIntegrity = uriIntegrity
    }

    enum CodingKeys: String, CodingKey {
      case uri
      case uriIntegrity = "uri#integrity"
    }
  }
}



// MARK: - Extension to map SdJwtVcTypeMetadata to ResolvedTypeMetadata
public extension SdJwtVcTypeMetadata {
  func toResolvedTypeMetadata() -> ResolvedTypeMetadata {
    .init(vct: vct,
          name: name,
          description: description,
          displays: display ?? [],
          claims:claims ?? [] )
    
  }
}

