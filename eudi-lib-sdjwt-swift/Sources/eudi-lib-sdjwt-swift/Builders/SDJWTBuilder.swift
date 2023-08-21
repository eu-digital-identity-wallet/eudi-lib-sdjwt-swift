//
//  SDJWTBuilder.swift
//
//
//  Created by SALAMPASIS Nikolaos on 13/8/23.
//

import Foundation

@resultBuilder
enum SDJWTBuilder {
    static func buildBlock() -> [String: SDElementValue] { [:] }

    static func buildBlock(_ elements: SDElement...) -> [String: SDElementValue] {
        elements.reduce(into: [:]) { partialResult, element in
            partialResult[element.key] = element.value
        }
    }
}

@resultBuilder
enum SDJWTObjectBuilder {
    static func buildBlock(_ elements: SDElement...) -> [SDElement] {
        elements
    }
}

@resultBuilder
enum SDJWTArrayBuilder {
    static func buildBlock(_ elements: SDElementValue...) -> [SDElementValue] {
        elements
    }
}

func makeSDJWT(@SDJWTBuilder _ content: () -> [String: SDElementValue]) -> [String: SDElementValue] {
    content()
}

func makeSDJWTObject(key: String, @SDJWTObjectBuilder _ content: () -> [SDElement]) -> (String, [SDElement]) {
    return (key, content())
}

let sdjwt = makeSDJWT {
    PlainClaim("sub", SDElementValue(builder: {

    }))
}

class Builder {

    @SDJWTBuilder
    static  var jwt: [String: SDElementValue] {
        PlainClaim("sub", .base("6c5c0a49-b589-431d-bae7-219122a9ec2c"))
        PlainClaim("iss", .base("https://example.com/issuer"))
        PlainClaim("iat", .base(1516239022))
        PlainClaim("exp", .base(1735689661))
        DisclosedClaim("adress", .init(builder: {
            PlainClaim("street_address", .base("Schulstr. 12"))
            PlainClaim("locality", .base("Schulpforta"))
            PlainClaim("region", .base("Sachsen-Anhalt"))
            PlainClaim("country", .base("DE"))
        }))
    }

}
