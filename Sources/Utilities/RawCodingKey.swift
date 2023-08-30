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

public struct RawCodingKey: CodingKey {

  private let string: String
  private let int: Int?

  public var stringValue: String { return string }

  public init(string: String) {
    self.string = string
    int = nil
  }

  public init?(stringValue: String) {
    string = stringValue
    int = nil
  }

  public var intValue: Int? { return int }
  public init?(intValue: Int) {
    string = String(describing: intValue)
    int = intValue
  }
}

extension RawCodingKey: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {

  public init(stringLiteral value: String) {
    string = value
    int = nil
  }

  public init(integerLiteral value: Int) {
    string = ""
    int = value
  }
}
