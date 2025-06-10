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
import XCTest
import SwiftyJSON
@testable import eudi_lib_sdjwt_swift


final class TypeMetadataClaimsValidatorTests: XCTestCase {
  
  func testValidate_missingTypeMetadata_throwsError() {
    
    let sut = TypeMetadataClaimsValidator()
    
    XCTAssertThrowsError(try sut.validate([], nil)) { error in
      XCTAssertEqual(error as? TypeMetadataError, TypeMetadataError.missingTypeMetadata)
    }
  }
  
  func testValidate_missingOrInvalidVct_throwsError() {
    let sut = TypeMetadataClaimsValidator()
    
    let metadata = ResolvedTypeMetadata(vct: "")
    
    XCTAssertThrowsError(try sut.validate([], metadata)) { error in
      XCTAssertEqual(error as? TypeMetadataError, TypeMetadataError.missingOrInvalidVCT)
    }
  }
  
  func testValidate_vctMismatch_throwsError() {
    let sut = TypeMetadataClaimsValidator()
    
    let metadata = ResolvedTypeMetadata(vct: "vct")
    
    XCTAssertThrowsError(try sut.validate(["vct": "other",], metadata)) { error in
      XCTAssertEqual(error as? TypeMetadataError, TypeMetadataError.vctMismatch)
    }
  }
  
  
  func testValidate_duplicateLanguageInDisplays_throwsError() {
    let sut = TypeMetadataClaimsValidator()
    
    let metadata = ResolvedTypeMetadata(vct: "vct", displays: [
      .init(lang: "en", name: "USA English"),
      .init(lang: "en", name: "UK English")
    ])
    
    XCTAssertThrowsError(try sut.validate(["vct": "vct",], metadata)) { error in
      XCTAssertEqual(error as? TypeMetadataError, TypeMetadataError.duplicateLanguageInDisplay)
    }
  }
}






