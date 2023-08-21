//
//  Signer.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 21/8/23.
//

import Foundation
import CryptoKit

class Signer {

//    It is important to note that:
//
//    The input to the hash function MUST be the base64url-encoded Disclosure, not the bytes encoded by the base64url string.
//    The bytes of the output of the hash function MUST be base64url-encoded, and are not the bytes making up the (often used) hex representation of the bytes of the digest.
//
    var saltProvider: SaltProvider

    init(saltProvider: SaltProvider = DefaultSaltProvider()) {
        self.saltProvider = saltProvider
    }

}
