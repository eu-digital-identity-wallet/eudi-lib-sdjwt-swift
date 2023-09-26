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

public struct PlainClaim: ClaimRepresentable {

  // MARK: - Properties

  public var key: String
  public var value: SdElement

  // MARK: - Lifecycle

  public init?(_ key: String, _ plain: Encodable) {
    self.key = key
    self.value = SdElement.plain(value: plain)
    guard case Result.success(true) = checkKeyValidity() else {
      return nil
    }
  }

  public init?(_ key: String, _ plain: [Encodable]) {
    self.key = key
    self.value = SdElement.plain(value: plain)
    guard case Result.success(true) = checkKeyValidity() else {
      return nil
    }
  }

  public init?(_ key: String, _ plain: [String: Encodable]) {
    self.key = key
    self.value = SdElement.plain(value: plain)
    guard case Result.success(true) = checkKeyValidity() else {
      return nil
    }
  }
}
