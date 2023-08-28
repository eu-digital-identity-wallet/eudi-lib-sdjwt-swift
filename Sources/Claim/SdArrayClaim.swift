///*
//* Copyright (c) 2023 European Commission
//*
//* Licensed under the Apache License, Version 2.0 (the "License");
//* you may not use this file except in compliance with the License.
//* You may obtain a copy of the License at
//*
//*     http://www.apache.org/licenses/LICENSE-2.0
//*
//* Unless required by applicable law or agreed to in writing, software
//* distributed under the License is distributed on an "AS IS" BASIS,
//* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//* See the License for the specific language governing permissions and
//* limitations under the License.
//*/

struct SdArrayClaim: ClaimRepresentable {
  var key: String
  var value: SdElement

  init(_ key: String, array: [SdElement]) {
    self.key = key
    self.value = .array(array)
  }

  init(_ key: String, @SDJWTArrayBuilder builder: () -> [SdElement]) {
    self.key = key
    self.value = .array(builder())
  }
}

struct RecursiveSdArrayClaim: ClaimRepresentable {
  var key: String
  var value: SdElement

  init(_ key: String, array: [SdElement]) {
    self.key = key
    self.value = .recursiveArray(array)
  }

  init(_ key: String, @SDJWTArrayBuilder builder: () -> [SdElement]) {
    self.key = key
    self.value = .recursiveArray(builder())
  }
}

