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

extension KeyedDecodingContainer {
  mutating func decode<T: Decodable>(for key: String) -> T? {
    // Find the first key that matches the given key.
    if let firstKey = allKeys.first(where: { $0.stringValue == key }) {
      // if it exists decode it as usual otherwise return nil
      return try? decode(T.self, forKey: firstKey)
    } else {
      // iterate through the coding keys available
      for codingKey in allKeys {
        // try to get the nested keyed decoding container
        // and call the same function on the new contaner.
        if var nestedContainer = try? nestedContainer(
             keyedBy: RawCodingKey.self, forKey: codingKey),
           let decodedValue: T = nestedContainer.decode(for: key) {
             return decodedValue
         // try to get the nested unkeyed decoding container
        } else if var nestedContainer = try? nestedUnkeyedContainer(
                 forKey: codingKey),
            let decodedValue: T = nestedContainer.decode(for: key) {
          return decodedValue
        }
      }
    }
    return nil
  }
}

extension UnkeyedDecodingContainer {
    mutating func decode<T: Decodable>(for key: String) -> T? {
        // Try to get the nested keyed container of this unkeyed container
        // call our function on the keyed container
        guard var container = try? nestedContainer(
            keyedBy: RawCodingKey.self) else { return nil }
        return container.decode(for: key)
    }
}


