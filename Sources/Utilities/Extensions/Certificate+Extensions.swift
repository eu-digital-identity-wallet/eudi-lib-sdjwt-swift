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
import X509

/// Extension for the `SubjectAlternativeNames` structure provided by X.509 library.
/// This extension provides utility methods for extracting DNS names and URIs from the
/// subject alternative names (SAN) field of an X.509 certificate.
extension SubjectAlternativeNames {
  
  /// Extracts the DNS names from the subject alternative names (SAN) field of a certificate.
  ///
  /// This function iterates over all general names in the `SubjectAlternativeNames` structure
  /// and extracts only those that are DNS names (`.dnsName`). It returns these names as an array of strings.
  ///
  /// - Returns: An array of DNS names found in the subject alternative names field, or an empty array if no DNS names are present.
  func rawSubjectAlternativeNames() -> [String] {
    self.compactMap { generalName in
      switch generalName {
      case .dnsName(let name):
        return name
      default: return nil
      }
    }
  }
  
  /// Extracts the Uniform Resource Identifiers (URIs) from the subject alternative names (SAN) field of a certificate.
  ///
  /// This function iterates over all general names in the `SubjectAlternativeNames` structure
  /// and extracts only those that are URIs (`.uniformResourceIdentifier`). It returns these URIs as an array of strings.
  ///
  /// - Returns: An array of URIs found in the subject alternative names field, or an empty array if no URIs are present.
  func rawUniformResourceIdentifiers() -> [String] {
    self.compactMap { generalName in
      switch generalName {
      case .uniformResourceIdentifier(let identifier):
        return identifier
      default: return nil
      }
    }
  }
}
