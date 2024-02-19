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

public struct ArrayClaim: ClaimRepresentable {

  // MARK: - Properties

  public var key: String
  public var value: SdElement

  // MARK: - Lifecycle

  public init?(_ key: String, array: [SdElement]) {
    self.key = key
    self.value = .array(array)
    guard case Result.success(true) = checkKeyValidity() else {
      return nil
    }
  }

  public init?(_ key: String, @SDJWTArrayBuilder builder: () -> [SdElement]) {
    self.key = key
    self.value = .array(builder())
    guard case Result.success(true) = checkKeyValidity() else {
      return nil
    }
  }
}

public struct RecursiveArrayClaim: ClaimRepresentable {

  // MARK: - Properties

  public var key: String
  public var value: SdElement

  // MARK: - Lifecycle

  public init?(_ key: String, array: [SdElement]) {
    self.key = key
    self.value = .recursiveArray(array)

    guard case Result.success(true) = checkKeyValidity() else {
      return nil
    }
  }

  public init?(_ key: String, @SDJWTArrayBuilder builder: () -> [SdElement]) {
    self.key = key
    self.value = .recursiveArray(builder())

    guard case Result.success(true) = checkKeyValidity() else {
      return nil
    }
  }
}
