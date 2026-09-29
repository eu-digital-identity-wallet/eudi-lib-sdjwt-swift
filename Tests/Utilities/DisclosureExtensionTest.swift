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

import XCTest
@testable import eudi_lib_sdjwt_swift

/// Regression tests for the bounds-checked Disclosure accessors.
/// A malformed disclosure array previously trapped with fatal
/// index-out-of-range; the accessors now return nil instead.
final class DisclosureExtensionTest: XCTestCase {

  func testObjectProperty_WellFormedArray_ReturnsKeyValue() {
    let disclosure = "[\"salt\", \"given_name\", \"John\"]"
    let result = disclosure.objectProperty
    XCTAssertEqual(result?.key, "given_name")
    XCTAssertEqual(result?.value.stringValue, "John")
  }

  func testObjectProperty_TooShort_ReturnsNil() {
    XCTAssertNil("[\"salt\"]".objectProperty)
    XCTAssertNil("[\"salt\", \"only_two\"]".objectProperty)
  }

  func testObjectProperty_EmptyArray_ReturnsNil() {
    XCTAssertNil("[]".objectProperty)
  }

  func testObjectProperty_NonArrayJSON_ReturnsNil() {
    XCTAssertNil("{\"not\":\"array\"}".objectProperty)
    XCTAssertNil("\"just a string\"".objectProperty)
    XCTAssertNil("not json at all".objectProperty)
  }

  func testArrayProperty_WellFormedArray_ReturnsValue() {
    let disclosure = "[\"salt\", \"element-value\"]"
    XCTAssertEqual(disclosure.arrayProperty?.stringValue, "element-value")
  }

  func testArrayProperty_TooShort_ReturnsNil() {
    XCTAssertNil("[\"salt\"]".arrayProperty)
    XCTAssertNil("[]".arrayProperty)
  }

  func testArrayProperty_NonArrayJSON_ReturnsNil() {
    XCTAssertNil("{\"not\":\"array\"}".arrayProperty)
    XCTAssertNil("garbage".arrayProperty)
  }
}
