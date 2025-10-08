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
  case invalidChain
}

enum ChainTrustResult: Equatable {
  case success
  case recoverableFailure(String)
  case failure
}

struct X509CertificateTrustAlways: X509SDJWTVCCertificateTrust {
  let rootCertificates: [Certificate] = []
  func isTrusted(chain: [Certificate]) async -> Bool { return true }
}

struct X509CertificateTrustFactory {
  public static let trust: X509SDJWTVCCertificateTrust = X509CertificateTrustAlways()
}

struct X509SDJWTVCCertificateChainVerifier: X509SDJWTVCCertificateTrust {
  
  let rootCertificates: [Certificate]
  
  init(rootCertificates: [Certificate]) {
    self.rootCertificates = rootCertificates
  }
  
  func isTrusted(chain: [Certificate]) async -> Bool {
    guard let leaf = chain.first else {
      return false
    }
    let result = await verifyChain(
      rootBase64Certificates: rootCertificates,
      leafBase64Certificate: leaf
    )
    
    switch result {
    case .success, .recoverableFailure:
      return true
    case .failure:
      return false
    }
  }
}

extension X509SDJWTVCCertificateChainVerifier {
  
  func verifyChain(
    rootBase64Certificates: [Certificate],
    intermediateBase64Certificates: [Certificate] = [],
    leafBase64Certificate: Certificate,
    date: Date = Date(),
    showDiagnostics: Bool = false
  ) async -> ChainTrustResult {
    
    let roots = CertificateStore(rootBase64Certificates)
    var verifier = Verifier(
      rootCertificates: roots
    ) {
      RFC5280Policy(
        fixedValidationTime: date
      )
      AcceptPrivateEKUPolicy()
    }
    
    let result = await verifier.validate(
      leaf: leafBase64Certificate,
      intermediates: .init(
        intermediateBase64Certificates
      )
    ) { diagnostic in
      print(diagnostic)
    }
    
    switch result {
    case .validCertificate:
      return .success
    case .couldNotValidate:
      return .failure
    }
  }
}

/// Accept a leaf whose *critical* EKU contains the private OID 1.3.130.2.0.0.1.2.
/// We also declare that we "understand" the EKU extension (2.5.29.37) so a critical EKU
/// won't cause the default policy to reject the chain.
struct AcceptPrivateEKUPolicy: VerifierPolicy {

  private static let ekuExtOID = ASN1ObjectIdentifier("2.5.29.37")
  private static let privatePurpose = ASN1ObjectIdentifier("1.3.130.2.0.0.1.2")
  
  var verifyingCriticalExtensions: [ASN1ObjectIdentifier] { [Self.ekuExtOID] }
  var understoodCriticalExtensions: Set<ASN1ObjectIdentifier> { [Self.ekuExtOID] }
  
  func chainMeetsPolicyRequirements(
    chain: UnverifiedCertificateChain
  ) -> PolicyEvaluationResult {
    evaluate(chain: chain)
  }
  
  private func evaluate(chain: UnverifiedCertificateChain) -> PolicyEvaluationResult {
    return .meetsPolicy
  }
}
