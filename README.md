# EUDI SD-JWT

:heavy_exclamation_mark: **Important!** Before you proceed, please read
the [EUDI Wallet Reference Implementation project description](https://github.com/eu-digital-identity-wallet/.github/blob/main/profile/reference-implementation.md)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

## Table of contents

* [Overview](#overview)
* [DSL Examples](#dsl-examples)
* [How to contribute](#how-to-contribute)
* [License](#license)

## Overview

This is a library offering a DSL (domain-specific language) for defining how a set of claims should be made selectively
disclosable.

Library implements [SD-JWT draft 12](https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-12.html)
is implemented in Swift.

## Use cases supported

- [Issuance](#issuance): As an Issuer use the library to issue a SD-JWT (in Combined Issuance Format)
- [Holder Verification](#holder-verification): As Holder verify a SD-JWT (in Combined Issuance Format) issued by an
  Issuer
- [Presentation Verification](#presentation-verification): As a Verifier verify SD-JWT in Combined Presentation Format or in Envelope Format 
- [Recreate initial claims](#recreate-original-claims): Given a SD-JWT recreate the original claims
* [SD-JWT VC support](#sd-jwt-vc-support)

## Issuance

To issue a SD-JWT, an `Issuer` should have:

- Decided on how the issued claims will be selectively disclosed (check [DSL examples](#dsl-examples))
- Whether to use decoy digests or not
- An appropriate signing key pair
- optionally, decided if and how will include holder's public key to the SD-JWT

In the example bellow, Issuer decides to issue an SD-JWT as follows:

- Includes in plain standard JWT claims (`sub`,`iss`, `iat`, `exp`)
- Makes selectively disclosable a claim named `address` using structured disclosure. This allows to individually
  disclose every subclaim of `address`
- Uses his key pair to sign the SD-JWT

```Swift
let issuersKeyPair: KeyPair!

let signedSDJWT = try SDJWTIssuer.issue(issuersPrivateKey: issuersKeyPair.private,
                                        decoys: 0, // Can be omitted
                                        header: .init(algorithm: .ES256)) {
  ConstantClaims.sub(subject: "6c5c0a49-b589-431d-bae7-219122a9ec2c")
  ConstantClaims.iss(domain: "https://example.com/issuer")
  ConstantClaims.iat(time: 1516239022)
  ConstantClaims.exp(time: 1516239022)
  ObjectClaim("address") {
    FlatDisclosedClaim("street_address", "Schulstr. 12")
    FlatDisclosedClaim("locality", "Schulpforta")
    FlatDisclosedClaim("region", "Sachsen-Anhalt")
    FlatDisclosedClaim("country", "DE")
  }
}

```

## Holder Verification

In this case, the SD-JWT is expected to be in serialized form.

Holder must know:

the public key of the Issuer and the algorithm used by the Issuer to sign the SD-JWT

```swift
let unverifiedSdJwtString = "..."
let issuersKeyPair: KeyPair!

SDJWTVerifier(parser: CompactParser(serialisedString: unverifiedSdJwtString))
  .verifyIssuance { jws in
    SignatureVerifier(signedJWT: jws, publicKey: issuersKeyPair.public)
}
```
## Presentation Verification

**In simple (not enveloped) format**

In this case, the SD-JWT is expected to be in Combined Presentation format. Verifier should know the public key of the Issuer and the algorithm used by the Issuer to sign the SD-JWT. Also, if verification includes Key Binding, the Verifier must also know a how the public key of the Holder was included in the SD-JWT and which algorithm the Holder used to sign the Key Binding JWT
```swift
// Issue a SDJWT to passed to a holder from an issuer
// Including Holders Public key
let issuerSignedSDJWT = try SDJWTIssuer
    .issue(issuersPrivateKey: issuersKeyPair.private,
           header: .init(algorithm: .ES256)) {
  // Claims disclosed or plain
  ...
  // add holders public key in the payload
  ObjectClaim("cnf") {
    ObjectClaim("jwk") {
      PlainClaim("kty", "EC")
      PlainClaim("x", "EOid5YEjFXpCzaqyEqckcA5TBGxWEVYCiKz05qO5r_c")
      PlainClaim("y", "7TTgK6fW5oxaN8m22f_HPVJ9Ny3KBKIvLcBIpUpk-7A")
      PlainClaim("crv", "P-256")
    }
  }
}

// Issue a SDJWT for presentation to a verifier
// Expect a verifier Challenge in json format to sign
// And prove identity
// Chose the subset of disclosures to present if needed
let holderSDJWTRepresentation = try SDJWTIssuer
  .presentation(holdersPrivateKey: holdersKeyPair.private,
                signedSDJWT: issuerSignedSDJWT,
                disclosuresToPresent: issuerSignedSDJWT.disclosures.filter({ _ in true }),
                keyBindingJWT: KBJWT(header: .init(algorithm: .ES256),
                                     kbJwtPayload: VerifiersChallenge.json)

SDJWTVerifier(sdJwt: holderSDJWTRepresentation)
.verifyPresentation { jws in
    try SignatureVerifier(signedJWT: jws, publicKey: issuersKeyPair.public)
  } keyBindingVerifier: { jws, holdersPublicKey in
    try KeyBindingVerifier(challenge: jws, extractedKey: holdersPublicKey)
}                                                           
```
**In enveloped format**

In this case, the SD-JWT is expected to be in envelope format. 
Verifier should know:
* the public key of the Issuer and the algorithm used by the Issuer to sign the SD-JWT.
* the public key and the signing algorithm used by the Holder to sign the envelope JWT, since the envelope acts like a proof of possession (replacing the key binding JWT)

```swift
let sdjwtOnPayload = "...."

try SDJWTVerifier(parser: CompactParser(serialisedString: sdjwtOnPayload))
  .verifyEnvelope(envelope: envelopedJws) { jws in
    // to verify the enveloped sdjwt
    try SignatureVerifier(signedJWT: jws, publicKey: issuersKeyPair.public)
  } holdersSignatureVerifier: {
    // to verify the container jwt
    try SignatureVerifier(signedJWT: envelopedJws, publicKey: holdersKeyPair.public)
  } claimVerifier: { audClaim, iat in
    ClaimsVerifier(iat: iat,
                   iatValidWindow: .init(startTime: Date(),
                                         endTime: Date()),
                   audClaim: audClaim,
                   expectedAud: "clientId")
  }
```
## Recreate original claims
Given a complex structure as per [Example 3: Complex Structured SD-JWT](docs/examples/example3-complex-structured.md)
and a subset of claims we can recreate the initial JSON of the SD-JWT.

```
["2GLC42sKQveCfGfryNRN9w", "time", "2012-04-23T18:25Z"]
["Pc33JM2LchcU_lHggv_ufQ", {"_sd": ["9wpjVPWuD7PK0nsQDL8B06lmdgV3LVybhHydQpTNyLI", "G5EnhOAOoU9X_6QMNvzFXjpEA_Rc-AEtm1bG_wcaKIk", "IhwFrWUB63RcZq9yvgZ0XPc7Gowh3O2kqXeBIswg1B4", "WpxQ4HSoEtcTmCCKOeDslB_emucYLz2oO8oHNr1bEVQ"]}]
["eI8ZWm9QnKPpNPeNenHdhQ", "method", "pipp"]
["G02NSrQfjFXQ7Io09syajA", "given_name", "Max"]
["lklxF5jMYlGTPUovMNIvCA", "family_name", "M\u00fcller"]
["y1sVU5wdfJahVdgwPgS7RQ", "address", {"locality": "Maxstadt", "postal_code": "12344", "country": "DE", "street_address": "Weidenstra\u00dfe 22"}]
```

```swift
let example3SDJWTSerialisedFormat = "..."
let sdjwt = CompactParser(serialisedString: example3SDJWTSerialisedFormat).getSignedSdJwt()

// array of digests of disclosures found on payload for collision 
sdjwt.recreateClaims().digestsFoundOnPayload checking
// the recreated JSON
sdjwt.recreateClaims().recreatedClaims 
```
The recreated JSON output 
```json
{
  "iat" : 1683000000,
  "verified_claims" : {
    "claims" : {
      "given_name" : "Max",
      "family_name" : "Müller",
      "address" : {
        "country" : "DE",
        "locality" : "Maxstadt",
        "street_address" : "Weidenstraße 22",
        "postal_code" : "12344"
      }
    },
    "verification" : {
      "trust_framework" : "de_aml",
      "time" : "2012-04-23T18:25Z",
      "evidence" : [
        {
          "method" : "pipp"
        }
      ]
    }
  },
  "iss" : "https://example.com/issuer",
  "exp" : 1883000000
}
```
## DSL Examples

All examples assume that we have the following claim set

```json
{
  "sub": "6c5c0a49-b589-431d-bae7-219122a9ec2c",
  "address": {
    "street_address": "Schulstr. 12",
    "locality": "Schulpforta",
    "region": "Sachsen-Anhalt",
    "country": "DE"
  }
}
```

- [Option 1: Flat SD-JWT](Docs/examples/option1-flat-sd-jwt.md)
- [Option 2: Structured SD-JWT](Docs/examples/option2-structured-sd-jwt.md)
- [Option 3: SD-JWT with Recursive Disclosures](Docs/examples/option3-recursive-sd-jwt.md)
- [Example 2a: Handling Structured Claims](Docs/examples/example2a-handling-structure-claims.md)
- [Example 3: Complex Structured SD-JWT](Docs/examples/example3-complex-structured.md)

## SD-JWT VC support

The library supports verifying [SD-JWT-based Verifiable Credentials](https://www.ietf.org/archive/id/draft-ietf-oauth-sd-jwt-vc-04.html).
More specifically, Issuer-signed JWT Verification Key Validation support is provided by [SDJWTVerifier](Sources/Verifier/SDJWTVerifier.swift). 

Please check [PresentationTest](Tests/Presentation/PresentationTest.swift) for code examples on creating a holder presentation.

Please check [VcVerifierTest](Tests/Verification/VcVerifierTest.swift) for code examples on verifying an Issuance SD-JWT VC and a Presentation SD-JWT VC (including verification of the Key Binding JWT).

## How to contribute

We welcome contributions to this project. To ensure that the process is smooth for everyone
involved, follow the guidelines found in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

### Third-party component licenses

* JOSE Support: [jose-swift](https://github.com/beatt83/jose-swift)
* JSON Support: [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)

### License details

Copyright (c) 2023 European Commission

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
