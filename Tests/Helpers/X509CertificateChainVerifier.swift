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
import SwiftASN1
import Security

@testable import eudi_lib_sdjwt_swift

enum CertificateValidationError: Error {
  case invalidCertificateData
  case insufficientCertificates
  case signatureValidationFailed
  case certificateExpired
  case untrustedRoot
  case invalidChain([VerificationResult.PolicyFailure])
}

enum ChainTrustResult: Equatable {
  case success
  case recoverableFailure(String)
  case failure
}

struct X509CertificateTrustAlways: X509CertificateTrust {
  let rootCertificates: [Certificate] = []
  func isTrusted(chain: [Certificate]) async -> Bool { return true }
}

struct X509CertificateTrustFactory {
  public static let trust: X509CertificateTrust = X509CertificateTrustAlways()
}

struct X509CertificateChainVerifier: X509CertificateTrust {
  
  let rootCertificates: [Certificate]
  
  init(rootCertificates: [Certificate]) {
    self.rootCertificates = rootCertificates
  }
  
  func isTrusted(chain: [Certificate]) async -> Bool {
    guard let leaf = chain.first else {
      return false
    }
    let result = try? await verifyChain(
      rootBase64Certificates: rootCertificates,
      leafBase64Certificate: leaf
    )
    return true
  }
}

extension X509CertificateChainVerifier {
  
  /// Converts a `SecCertificate` to `X509.Certificate`
  private func convertToX509Certificate(_ secCert: SecCertificate) throws -> Certificate {
    let derData = SecCertificateCopyData(secCert) as Data
    return try Certificate(derEncoded: [UInt8](derData))
  }
  
  func verifyChain(
    rootBase64Certificates: [Certificate],
    intermediateBase64Certificates: [Certificate] = [],
    leafBase64Certificate: Certificate,
    date: Date = Date(),
    showDiagnostics: Bool = false
  ) async throws -> ChainTrustResult {
        
    let roots = CertificateStore(rootBase64Certificates)
    var verifier = Verifier(
      rootCertificates: roots
    ) {
      RFC5280Policy(
        validationTime: date
      )
    }
    
    let result = await verifier.validate(
      leafCertificate: leafBase64Certificate,
      intermediates: .init(
        intermediateBase64Certificates
      )
    ) { diagnostic in
      print(diagnostic)
    }
    
    switch result {
    case .validCertificate:
      return .success
    case .couldNotValidate(let policyFailures):
      throw CertificateValidationError.invalidChain(
        policyFailures
      )
    }
  }
}
