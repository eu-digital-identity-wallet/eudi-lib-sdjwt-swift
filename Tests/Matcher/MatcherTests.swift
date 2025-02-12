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
import SwiftyJSON

@testable import eudi_lib_sdjwt_swift

final class MatcherTests: XCTestCase {
  
  var json: JSON!
  var matcher: Matcher!
  
  override func setUp() {
    super.setUp()
    
    // Sample JSON structure
    json = JSON([
      "user": [
        "name": "John Doe",
        "age": 30,
        "address": [
          "city": "New York",
          "zip": "10001"
        ]
      ],
      "items": [
        ["name": "Item 1", "price": 10],
        ["name": "Item 2", "price": 20],
        ["name": "Item 3", "price": 30]
      ],
      "things": [
        "one",
        "two",
        "three"
      ],
      "config": [
        "enabled": true,
        "thresholds": [100, 200, 300]
      ]
    ])
    
    matcher = Matcher(json: json)
  }
  
  // MARK: - Basic Matching Tests
  
  func testMatchSingleLevelKey() {
    let path = ClaimPath.claim("user")
    let result = matcher.match(path)
    XCTAssertNotNil(result)
    XCTAssertEqual(result?["name"].stringValue, "John Doe")
  }
  
  func testMatchNestedKey() {
    let path = ClaimPath([.claim(name: "user"), .claim(name: "name")])
    let result = matcher.match(path)
    XCTAssertEqual(result?.stringValue, "John Doe")
  }
  
  func testMatchDeeplyNestedKey() {
    let path = ClaimPath([.claim(name: "user"), .claim(name: "address"), .claim(name: "city")])
    let result = matcher.match(path)
    XCTAssertEqual(result?.stringValue, "New York")
  }
  
  // MARK: - Array Indexing Tests
  
  func testMatchArrayElement() {
    let path = ClaimPath([.claim(name: "items"), .arrayElement(index: 1), .claim(name: "name")])
    let result = matcher.match(path)
    XCTAssertEqual(result?.stringValue, "Item 2")
  }
  
  func testMatchOutOfBoundsArrayElement() {
    let path = ClaimPath([.claim(name: "items"), .arrayElement(index: 10)])
    let result = matcher.match(path)
    XCTAssertNil(result)
  }
  
  func testMatchArrayAllElements() {
    let path = ClaimPath([.claim(name: "items"), .allArrayElements])
    let result = matcher.match(path)
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.arrayValue.count, 3)
  }
  
  func testMatchArrayAllElementsReturned() {
    let path = ClaimPath([.claim(name: "items"), .allArrayElements, .claim(name: "price")])
    let result = matcher.match(path)
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.arrayValue, [10, 20, 30])
  }
  
  // MARK: - Non-existent Keys
  
  func testMatchNonExistentKey() {
    let path = ClaimPath([.claim(name: "invalidKey")])
    let result = matcher.match(path)
    XCTAssertNil(result)
  }
  
  func testMatchPartialInvalidPath() {
    let path = ClaimPath([.claim(name: "user"), .claim(name: "invalidKey")])
    let result = matcher.match(path)
    XCTAssertNil(result)
  }
  
  // MARK: - Boolean Matching Tests
  
  func testMatchesReturnsTrueForExistingPath() {
    let path = ClaimPath([.claim(name: "user"), .claim(name: "name")])
    XCTAssertTrue(matcher.matches(path))
  }
  
  func testMatchesReturnsFalseForNonExistentPath() {
    let path = ClaimPath([.claim(name: "user"), .claim(name: "invalidKey")])
    XCTAssertFalse(matcher.matches(path))
  }
  
  // MARK: - Edge Cases
  
  func testMatchEmptyClaimPath() {
    let path = ClaimPath([])
    let result = matcher.match(path)
    XCTAssertNotNil(result)
  }
  
  func testMatchRoot() {
    let path = ClaimPath([.claim(name: "")])
    let result = matcher.match(path)
    XCTAssertNil(result)
  }
  
  func testMatchBooleanValue() {
    let path = ClaimPath([.claim(name: "config"), .claim(name: "enabled")])
    let result = matcher.match(path)
    XCTAssertEqual(result?.boolValue, true)
  }
  
  func testMatchNumberArrayElement() {
    let path = ClaimPath([.claim(name: "config"), .claim(name: "thresholds"), .arrayElement(index: 1)])
    let result = matcher.match(path)
    XCTAssertEqual(result?.intValue, 200)
  }
  
  func testMatchWholeArray() {
    let path = ClaimPath([.claim(name: "config"), .claim(name: "thresholds")])
    let result = matcher.match(path)
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.arrayValue.count, 3)
  }
  
  // MARK: - Invalid Path Formats
  
  func testMatchWithInvalidJsonPointerPath() {
    let path = ClaimPath(jsonPointer: "invalid-path")
    XCTAssertNil(path)
  }
  
  func testMatchWithMalformedPath() {
    let path = ClaimPath([.claim(name: "/wrong/format")])
    let result = matcher.match(path)
    XCTAssertNil(result)
  }
  
  func testMatchWithEscapedCharacters() {
    let path = ClaimPath([.claim(name: "user/name")])
    let result = matcher.match(path)
    XCTAssertNil(result)
  }
  
  func testMatchWithNestedArray() {
    let nestedJson: JSON = [
      "data": [
        "records": [
          ["id": 1, "value": "A"],
          ["id": 2, "value": "B"],
          ["id": 3, "value": "C"]
        ]
      ]
    ]
    
    let nestedMatcher = Matcher(json: nestedJson)
    let path = ClaimPath([.claim(name: "data"), .claim(name: "records"), .arrayElement(index: 2), .claim(name: "value")])
    let result = nestedMatcher.match(path)
    XCTAssertEqual(result?.stringValue, "C")
  }
}
