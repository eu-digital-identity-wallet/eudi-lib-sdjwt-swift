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

public class CompactSerialiser: SerialiserProtocol {

  // MARK: - Properties

  public var data: Data {
    self.serialised.data(using: .utf8) ?? Data()
  }

  public var serialised: String {
    self.serialisationFormat.serialise(signedSDJWT: signedSDJWT)
  }

  private var signedSDJWT: SignedSDJWT
  private var serialisationFormat: SerialisationFormat = .serialised

  // MARK: - Lifecycle

  public init(signedSDJWT: SignedSDJWT) {
    self.signedSDJWT = signedSDJWT
  }
}

public extension SerialisationFormat {
  func serialise(signedSDJWT: SignedSDJWT) -> String {
    var output = ""
    output += signedSDJWT.jwt.compactSerialization
    output += signedSDJWT.disclosures.reduce(into: "~", { partialResult, disclosure in
      partialResult += disclosure + "~"
    })
    output += signedSDJWT.kbJwt?.compactSerialization ?? ""
    return output
  }
}
