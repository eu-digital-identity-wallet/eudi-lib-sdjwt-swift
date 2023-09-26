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

public struct ObjectClaim: ClaimRepresentable {

  // MARK: - Properties

  public var key: String
  public var value: SdElement

  // MARK: - Lifecycle

  public init?(_ key: String, @SDJWTBuilder builder: () -> SdElement) {
    self.key = key
    guard let object = builder().asObject else {
      return nil
    }
    self.value = .object(object)
    guard case Result.success(true) = checkKeyValidity() else {
      return nil
    }
  }

  public init?(_ key: String, value: SdElement) {
    self.key = key
    self.value = value
    guard case Result.success(true) = checkKeyValidity() else {
      return nil
    }
  }
}

public struct RecursiveObject: ClaimRepresentable {

  // MARK: - Properties

  public var key: String
  public var value: SdElement

  // MARK: - Lifecycle

  public init?(_ key: String, @SDJWTBuilder builder: () -> SdElement) {
    self.key = key
    guard let object = builder().asObject else {
      return nil
    }
    self.value = .recursiveObject(object)
  }
}
