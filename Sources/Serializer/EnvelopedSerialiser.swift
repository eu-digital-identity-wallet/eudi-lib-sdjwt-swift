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

public class EnvelopedSerialiser: SerialiserProtocol {

  // MARK: - Properties

  private var payload: JSON
  private var serialisationFormat: SerialisationFormat = .envelope

  public var serialised: String {
    return (try? payload.toJSONString(outputFormatting: [])) ?? ""
  }

  public var data: Data {
    return (try? payload.rawData()) ?? Data()
  }

  // MARK: - Lifecycle

  public init(SDJWT: SignedSDJWT, jwTpayload: Data, options opt: JSONSerialization.ReadingOptions = []) throws {
    var updatedSDJWT = SDJWT
    updatedSDJWT.kbJwt = nil

    payload = try JSON(data: jwTpayload)
    let compactSerialiser = CompactSerialiser(signedSDJWT: updatedSDJWT)
    payload[Keys.sdJwt].string = compactSerialiser.serialised
  }
}
