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

public struct TimeRange: Sendable {
  let startTime: Date
  let endTime: Date

  public init?(startTime: Date, endTime: Date) {
    guard startTime < endTime else {
      return nil // Ensure that the start time is earlier than the end time
    }
    self.startTime = startTime
    self.endTime = endTime
  }

  func contains(date: Date) -> Bool {
    return date >= startTime && date <= endTime
  }
}
