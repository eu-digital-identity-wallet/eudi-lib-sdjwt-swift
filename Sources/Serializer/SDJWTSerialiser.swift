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

class Serialiser {

  var serialised: String {
    self.serialisationFormat.serialize(signedSDJWT: signedSDJWT)
  }

  private var signedSDJWT: SignedSDJWT
  private var serialisationFormat: SerialisationFormat

  init(signedSDJWT: SignedSDJWT, serialisationFormat: SerialisationFormat) {
    self.signedSDJWT = signedSDJWT
    self.serialisationFormat = serialisationFormat
  }
}

extension SerialisationFormat {
  func serialize(signedSDJWT: SignedSDJWT) -> String {
    switch self {
    case .serialised:
      return serialised(signedSDJWT: signedSDJWT)
    }

    func serialised(signedSDJWT: SignedSDJWT) -> String {
      var output = ""
      output += signedSDJWT.jwt.compactSerializedString
      output += signedSDJWT.disclosures.reduce(into: "~", { partialResult, disclosure in
        partialResult += disclosure + "~"
      })
      output += signedSDJWT.kbJwt?.compactSerializedString ?? ""
      return output
    }

  }
}
