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

extension SdElement {
  var expectedDigests: Int {
    var output = 0
    switch self {
    case .object(let object):
      output = object.reduce(into: 0) { partialResult, element in
        partialResult += element.value.expectedDigests
      }
    case .plain:
      ()
    case .flat:
      output += 1
    case .array(let array):
      output = array.reduce(into: 0, { partialResult, element in
        partialResult += element.expectedDigests
      })
    case .recursiveObject(let object):
      output = object.reduce(into: 0) { partialResult, element in
        partialResult += element.value.expectedDigests
      }
      output += 1
    case .recursiveArray(let array):
      output = array.reduce(into: 0, { partialResult, element in
        partialResult += element.expectedDigests
      })
      output += 1
    }

    return output
  }
}

func validateObjectResults(factoryResult result: Result<ClaimSet, Error>) {
  switch result {
  case .success((let json, let disclosures)):
    print(try! json.toJSONString(outputFormatting: .prettyPrinted))
    disclosures.forEach({print($0)})
  case .failure(let err):
    XCTFail("Failed to Create SDJWT")
  }
}
