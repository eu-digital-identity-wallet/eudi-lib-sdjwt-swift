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

package protocol TypeMetadataMergerType {
  func mergeMetadata(from metadataArray: [ResolvedTypeMetadata]) -> ResolvedTypeMetadata?
}

struct TypeMetadataMerger: TypeMetadataMergerType {
  
  public func mergeMetadata(
    from metadataArray: [ResolvedTypeMetadata]
  ) -> ResolvedTypeMetadata? {
    
    guard let base = metadataArray.first else { return nil }
    
    return metadataArray.dropFirst().reduce(base) { (result: ResolvedTypeMetadata, parent: ResolvedTypeMetadata) -> ResolvedTypeMetadata in
      
      let name = result.name ?? parent.name
      let description = result.description ?? parent.description
      
      let display = mergeByKey(
        primary: result.displays,
        secondary: parent.displays,
        keySelector: \.lang,
        merge: { current, _ in current }
      )
      
      let claims = mergeByKey(
        primary: result.claims,
        secondary: parent.claims,
        keySelector: \.path,
        merge: { current, parent in
          SdJwtVcTypeMetadata.ClaimMetadata(
            path: current.path,
            display: mergeByKey(
              primary: current.display ?? [],
              secondary: parent.display ?? [],
              keySelector: \.lang,
              merge: { current, _ in current }
            ),
            selectivelyDisclosable: current.selectivelyDisclosable,
            svgId: current.svgId
          )
        }
      )
      
      return ResolvedTypeMetadata(
        vct: result.vct,
        name: name,
        description: description,
        displays: display,
        claims: claims
      )
    }
  }
  
  private func mergeByKey<T, K: Hashable>(
    primary: [T],
    secondary: [T],
    keySelector: (T) -> K,
    merge: (T, T) -> T
  ) -> [T] {

    var seenKeys = Set<K>()
    var merged: [T] = []

    // Add all primary items (in order)
    for item in primary {
      let key = keySelector(item)
      seenKeys.insert(key)
      merged.append(item)
    }

    // Merge or append secondary items
    for item in secondary {
      let key = keySelector(item)
      if let index = merged.firstIndex(where: { keySelector($0) == key }) {
        merged[index] = merge(merged[index], item)
      } else if !seenKeys.contains(key) {
        merged.append(item)
      }
    }
      
    return merged
  }
}


