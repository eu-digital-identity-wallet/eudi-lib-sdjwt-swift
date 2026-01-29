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

class ClaimPathTests: XCTestCase {
  
  func testClaimPathInitialization() {
    let path = ClaimPath([.claim(name: "user"), .claim(name: "name")])
    XCTAssertEqual(path.value, [.claim(name: "user"), .claim(name: "name")])
  }
  
  func testClaimPathAppendingClaim() {
    let path = ClaimPath.claim("user") + .claim(name: "name")
    XCTAssertEqual(path, ClaimPath([.claim(name: "user"), .claim(name: "name")]))
  }
  
  func testClaimPathAppendingArrayElement() {
    let path = ClaimPath.claim("items") + .arrayElement(index: 2)
    XCTAssertEqual(path, ClaimPath([.claim(name: "items"), .arrayElement(index: 2)]))
  }
  
  func testClaimPathAppendingAllArrayElements() {
    let path = ClaimPath.claim("items").allArrayElements()
    XCTAssertEqual(path, ClaimPath([.claim(name: "items"), .allArrayElements]))
  }
  
  func testClaimPathContains() {
    let parentPath = ClaimPath([.claim(name: "user")])
    let childPath = ClaimPath([.claim(name: "user"), .claim(name: "name")])
    XCTAssertTrue(childPath.contains(parentPath))
    XCTAssertFalse(parentPath.contains(childPath))
  }
  
  func testClaimPathParent() {
    let path = ClaimPath([.claim(name: "user"), .claim(name: "name")])
    let parent = path.parent()
    XCTAssertEqual(parent, ClaimPath([.claim(name: "user")]))
  }
  
  func testClaimPathParentOfRoot() {
    let path = ClaimPath([.claim(name: "root")])
    XCTAssertNil(path.parent())
  }
  
  func testClaimPathHead() {
    let path = ClaimPath([.claim(name: "user"), .claim(name: "name")])
    XCTAssertEqual(path.head(), .claim(name: "user"))
  }
  
  func testClaimPathTail() {
    let path = ClaimPath([.claim(name: "user"), .claim(name: "name")])
    let tail = path.tail()
    XCTAssertEqual(tail, ClaimPath([.claim(name: "name")]))
  }
  
  func testClaimPathTailOfSingleElement() {
    let path = ClaimPath([.claim(name: "user")])
    XCTAssertNil(path.tail())
  }
  
  func testClaimPathJsonPointerInitialization() {
    let path = ClaimPath(pointer: "/user/name")
    XCTAssertEqual(path, ClaimPath([.claim(name: "user"), .claim(name: "name")]))
  }
  
  func testClaimPathJsonPointerArrayIndex() {
    let path = ClaimPath(pointer: "/items/2")
    XCTAssertEqual(path, ClaimPath([.claim(name: "items"), .arrayElement(index: 2)]))
  }
  
  func testClaimPathJsonPointerEscapedCharacters() {
    let path = ClaimPath(pointer: "/user~1data")
    XCTAssertEqual(path, ClaimPath([.claim(name: "user/data")]))
  }
  
  func testClaimPathJsonPointerInvalidFormat() {
    let path = ClaimPath(pointer: "user/name") // Missing leading "/"
    XCTAssertNil(path)
  }
  
  func testClaimPathMatches() {
    let path1 = ClaimPath([.claim(name: "user"), .claim(name: "name")])
    let path2 = ClaimPath([.claim(name: "user"), .claim(name: "name")])
    XCTAssertTrue(path1.matches(path2))
  }
  
  func testClaimPathDoesNotMatchDifferentSizes() {
    let path1 = ClaimPath([.claim(name: "user")])
    let path2 = ClaimPath([.claim(name: "user"), .claim(name: "name")])
    XCTAssertFalse(path1.matches(path2))
  }
}

