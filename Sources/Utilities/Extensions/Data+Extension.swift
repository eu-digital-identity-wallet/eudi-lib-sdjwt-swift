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

extension Data {
  func base64URLEncode() -> String {
    var base64 = self.base64EncodedString()
    base64 = base64.replacingOccurrences(of: "+", with: "-")
    base64 = base64.replacingOccurrences(of: "/", with: "_")
    base64 = base64.replacingOccurrences(of: "=", with: "")
    return base64
  }

  func decodeBase64(encoding: String.Encoding = .utf8) -> String? {
    return String(data: self, encoding: encoding)
  }

}
