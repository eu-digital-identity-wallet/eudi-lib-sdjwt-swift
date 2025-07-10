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

/// Defines a Verifier's policy concerning Type Metadata.
public enum TypeMetadataPolicy {
  
  /**
   * Type Metadata are not used.
   */
  case notUsed
  
  /**
   * Type Metadata are not required.
   * Failure to successfully resolve Type Metadata for any Vct, does not result in the rejection of the SD-JWT VC.
   */
  case optional(verifier: TypeMetadataVerifierType)
  
  /**
   * Type Metadata are always required for all Vcts.
   * Failure to successfully resolve Type Metadata for any Vct, results in the rejection of the SD-JWT VC.
   */
  case alwaysRequired(verifier: TypeMetadataVerifierType)
  
  /**
   * Type Metadata are always required for the specified Vcts.
   * Failure to successfully resolve Type Metadata for any of the specified Vcts, results in the rejection of the SD-JWT VC.
   */
  case requiredFor(vcts: Set<String>, verifier: TypeMetadataVerifierType)
}
