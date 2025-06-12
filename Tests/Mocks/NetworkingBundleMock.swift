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

import XCTest

@testable import eudi_lib_sdjwt_swift

class NetworkingBundleMock: Networking {
  
  let path: String?
  let `extension`: String?
  let statusCode: Int
  let filenameResolver: ((URL) -> String)?
  
  init(
    path: String? = nil,
    `extension`: String? = nil,
    statusCode: Int = 200,
    filenameResolver: ((URL) -> String)? = nil
  ) {
    self.path = path
    self.extension = `extension`
    self.statusCode = statusCode
    self.filenameResolver = filenameResolver
  }
  
  func data(
    from url: URL
  ) async throws -> (Data, URLResponse) {
    
    let filePath: String?

    if let path = self.path, let ext = self.extension {
      filePath = Bundle.module.path(forResource: path, ofType: ext)
    } else {
      let filename = filenameResolver?(url) ?? url.lastPathComponent
      filePath = Bundle.module.path(forResource: filename, ofType: "json")
    }

    guard let path = filePath else {
      throw URLError(.fileDoesNotExist)
    }

    let fileURL = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: fileURL)
    let result = Result<Data, Error>.success(data)
    let response = HTTPURLResponse(
      url: url,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: [:]
    )
    return try (result.get(), response!)
  }
  
  func data(
    for request: URLRequest
  ) async throws -> (Data, URLResponse) {
    return try await data(from: URL(string: "https://www.example.com")!)
  }
}

class NetworkingJSONMock: Networking {
  
  let json: JSON
  let statusCode: Int
  
  init(
    json: JSON,
    statusCode: Int = 200
  ) {
    self.json = json
    self.statusCode = statusCode
  }
  
  func data(
    from url: URL
  ) async throws -> (Data, URLResponse) {
    let result = Result<Data, Error>.success(try self.json.rawData())
    let response = HTTPURLResponse(
      url: .stub(),
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: [:]
    )
    return try (result.get(), response!)
  }
  
  func data(
    for request: URLRequest
  ) async throws -> (Data, URLResponse) {
    return try await data(from: URL(string: "https://www.example.com")!)
  }
}
