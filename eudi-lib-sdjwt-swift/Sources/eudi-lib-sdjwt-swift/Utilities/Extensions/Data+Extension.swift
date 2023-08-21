//
//  Data+Extension.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 21/8/23.
//

import Foundation

extension Data {
    func base64URLEncode() -> String {
        var base64 = self.base64EncodedString()
        base64 = base64.replacingOccurrences(of: "+", with: "-")
        base64 = base64.replacingOccurrences(of: "/", with: "_")
        base64 = base64.replacingOccurrences(of: "=", with: "")
        return base64
    }
}
