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

import JOSESwift
import CryptoKit
import Security

class JWSController<SecKey> {

  // MARK: - Properties

  var signatureAlgorithm: SignatureAlgorithm
  // SecKey Should be Data (HMAC) Or SecKey (RSA, EC)
  let signer: Signer<SecKey>

  // MARK: - Lifecycle

  init(signingAlgorithm: SignatureAlgorithm, privateKey: SecKey) throws {
    self.signatureAlgorithm = signingAlgorithm
    guard let signer = Signer(signingAlgorithm: signingAlgorithm, key: privateKey) else {
      throw JOSESwiftError.signingFailed(description: "Failed To Create Signing Algorith \(signingAlgorithm) with key \(privateKey)")
    }

    self.signer = signer
  }
}
