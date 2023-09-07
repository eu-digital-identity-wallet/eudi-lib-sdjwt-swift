# EUDI SD-JWT

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

## Table of contents

* [Overview](#overview)
* [DSL Examples](#dsl-examples)
* [How to contribute](#how-to-contribute)
* [License](#license)

## Overview

This is a library offering a DSL (domain-specific language) for defining how a set of claims should be made selectively
disclosable.

Library implements [SD-JWT draft5](https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-05.html)
is implemented in Swift.

## Use cases supported

- [Issuance](#issuance): As an Issuer use the library to issue a SD-JWT (in Combined Issuance Format) ✅︎
- [Holder Verification](#holder-verification): As Holder verify a SD-JWT (in Combined Issuance Format) issued by an
  Issuer
- [Presentation Verification](#presentation-verification): As a Verifier verify SD-JWT in Combined Presentation Format or in Envelope Format
- [Recreate initial claims](#recreate-original-claims): Given a SD-JWT recreate the original claims

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
    let keyPair: KeyPair!

    @SDJWTBuilder
    var claims: SdElement {
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
    
    let factory = SDJWTFactory(saltProvider: DefaultSaltProvider())
    let claimSet = try factory.createJWT(sdjwtObject: claims.asObject).get()
    let issuer = try SDJWTIssuer(purpose: .issuance(claimSet),
                                 jwsController: .init(signingAlgorithm: .ES256, privateKey: keyPair.private))
                                 
    let signedSDJWT = try issuer.createSignedJWT()

```

## Holder Verification

In this case, the SD-JWT is expected to be in serialized form.

Holder must know:

the public key of the Issuer and the algorithm used by the Issuer to sign the SD-JWT

```swift
let unverifiedSdJwt = "..."
let issuerPubKey: ECPublicKey = "..."

let parser = Parser(serialisedString: unverifiedSdJwt, serialisationFormat: .serialised)

let result = SdJwtVerifier().verifyIssuance(parser: parser) 
{ jws in
  try SignatureVerifier(signedJWT: jws, publicKey: pk.converted(to: SecKey.self))
} disclosuresVerifier: {
  try DisclosuresVerifier(parser: parser)
}

```
## Presentation Verification

## Recreate original claims

## How to contribute

We welcome contributions to this project. To ensure that the process is smooth for everyone
involved, follow the guidelines found in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

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
