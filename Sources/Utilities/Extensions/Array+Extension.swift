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

extension Array {
  /// Safely accesses an element at the given index.
  /// - Parameter index: The index to access.
  /// - Returns: The element if within bounds, otherwise `nil`.
  subscript(safe index: Int) -> Element? {
      return indices.contains(index) ? self[index] : nil
  }
  
  mutating func appendOptional(_ newElement: Element? ) {
    guard let newElement else {
      return
    }
    self.append(newElement)
  }
}

extension Array {
  subscript(safe range: Range<Index>) -> [Element]? {
    if range.lowerBound >= startIndex && range.upperBound <= endIndex {
      return Array(self[range])
    } else {
      return nil
    }
  }
}

extension Array where Element == String {
  mutating func findAndRemoveFirst(from otherArray: [String]) -> (Array, Element?) {
    for (index, element) in self.enumerated() {
      if otherArray.contains(element) {
        self.remove(at: index)
        return (self, element)
      }
    }
    return (self, nil)
  }
}
