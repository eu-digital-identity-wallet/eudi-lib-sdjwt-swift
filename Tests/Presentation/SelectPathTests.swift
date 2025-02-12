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

class SelectPathTests: XCTestCase {
  
  var selectPath: DefaultSelectPath!
  
  override func setUp() {
    super.setUp()
    selectPath = DefaultSelectPath()
  }
  
  func testSelectClaimFromDictionary() {
    let json = JSON(["name": "Alice", "age": 30])
    let path = ClaimPath([.claim(name: "name")])
    
    let result = selectPath.select(json: json, path: path)
    
    switch result {
    case .success(let selectedJSON):
      XCTAssertEqual(selectedJSON, JSON("Alice"))
    case .failure:
      XCTFail("Expected to find 'name' but failed")
    }
  }
  
  func testSelectNonexistentClaim() {
    let json = JSON(["name": "Alice"])
    let path = ClaimPath([.claim(name: "unknown")])
    
    let result = selectPath.select(json: json, path: path)
    
    switch result {
    case .success(let selectedJSON):
      XCTAssertEqual(selectedJSON, JSON.null)
    case .failure:
      XCTFail("Expected nil but failed")
    }
  }
  
  func testSelectFromArrayByIndex() {
    let json = JSON(["items": ["apple", "banana", "cherry"]])
    let path = ClaimPath([.claim(name: "items"), .arrayElement(index: 1)])
    
    let result = selectPath.select(json: json, path: path)
    
    switch result {
    case .success(let selectedJSON):
      XCTAssertEqual(selectedJSON, JSON("banana"))
    case .failure:
      XCTFail("Expected to find 'banana' but failed")
    }
  }
  
  func testSelectArrayElementOutOfBounds() {
    let json = JSON(["items": ["apple", "banana"]])
    let path = ClaimPath([.claim(name: "items"), .arrayElement(index: 5)]) // Index out of bounds
    
    let result = selectPath.select(json: json, path: path)
    
    switch result {
    case .success(let selectedJSON):
      XCTAssertEqual(selectedJSON, nil)
    case .failure:
      XCTFail("Expected nil for out-of-bounds index")
    }
  }
  
  func testSelectAllArrayElements() {
    let json = JSON(["items": [["id": 1], ["id": 2], ["id": 3]]])
    let path = ClaimPath([.claim(name: "items"), .allArrayElements, .claim(name: "id")])
    
    let result = selectPath.select(json: json, path: path)
    
    switch result {
    case .success(let selectedJSON):
      XCTAssertEqual(selectedJSON, JSON([1, 2, 3]))
    case .failure:
      XCTFail("Expected [1, 2, 3] but failed")
    }
  }
  
  func testSelectFromNonDictionary() {
    let json = JSON(["items": "not a dictionary"])
    let path = ClaimPath([.claim(name: "items"), .claim(name: "name")]) // Should fail
    
    let result = selectPath.select(json: json, path: path)
    
    switch result {
    case .success:
      XCTFail("Expected failure but got success")
    case .failure(let error):
      XCTAssertTrue(error.localizedDescription.contains("Expected JSON object"))
    }
  }
  
  func testSelectFromNonArray() {
    let json = JSON(["items": "not an array"])
    let path = ClaimPath([.claim(name: "items"), .arrayElement(index: 0)]) // Should fail
    
    let result = selectPath.select(json: json, path: path)
    
    switch result {
    case .success:
      XCTFail("Expected failure but got success")
    case .failure(let error):
      XCTAssertTrue(error.localizedDescription.contains("Expected JSON array"))
    }
  }
}


