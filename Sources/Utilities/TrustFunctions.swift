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
import SwiftyJSON

func parseCertificates(from chain: [String]) -> [Certificate] {
  processChain(chain)
}

func parseCertificates(from data: Data) -> [Certificate] {
  let header = try? JSON(data: data)
  let chain = header?["x5c"].array?.compactMap { $0.stringValue } ?? []
  return processChain(chain)
}

func parseCertificateData(_ data: Data) -> [String] {
  let header = try? JSON(data: data)
  return header?["x5c"].array?.compactMap { $0.stringValue } ?? []
}

fileprivate func processChain(_ chain: [String]) -> [Certificate] {
  return chain.compactMap { serializedCertificate in
    guard let serializedData = Data(base64Encoded: serializedCertificate) else {
      return nil
    }
    
    if let string = String(data: serializedData, encoding: .utf8) {
      guard let data = Data(base64Encoded: string.removeCertificateDelimiters()) else {
        return nil
      }
      let derBytes = [UInt8](data)
      return try? Certificate(derEncoded: derBytes)
    } else {
      let derBytes = [UInt8](serializedData)
      return try? Certificate(derEncoded: derBytes)
    }
  }
}
