//
//  Encodable+Extension.swift
//  
//
//  Created by SALAMPASIS Nikolaos on 21/8/23.
//

import Foundation

extension Encodable {
    func toJSONString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let jsonData = try encoder.encode(self)

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        } else {
            throw NSError(domain: "JSONEncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON data to string."])
        }
    }
}
