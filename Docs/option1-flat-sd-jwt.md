# Option 1: Flat SD-JWT

Check [specification Option 1: Flat SD-JWT](https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-05.html#name-option-1-flat-sd-jwt)

The example bellow demonstrates the usage of the library mixed with the Kotlinx Serialization DSL
to produce a SD-JWT which contains claim `sub` plain and `address` is selectively disclosed as a whole.
Also, standard JWT claims have been added plain (`iss`, `iat`, `exp`)

```swift
    @SDJWTBuilder
    var structured: SdElement {
      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date() + 3600)
      ConstantClaims.iss(domain: "https://example.com/issuer")
      ConstantClaims.sub(subject: "6c5c0a49-b589-431d-bae7-219122a9ec2c")

      FlatDisclosedClaim("adress", ["street_address" : "Schulstr. 12",
                                    "locality": "Schulpforta",
                                    "region": "Sachsen-Anhalt",
                                    "country": "DE"])
    }
```

```JSON
Payload JSON Value of sdjwt
==============================
{
  "exp" : 1693475273,
  "iss" : "https:\/\/example.com\/issuer",
  "_sd_alg" : "sha-256",
  "sub" : "6c5c0a49-b589-431d-bae7-219122a9ec2c",
  "iat" : 1693471673,
  "_sd" : [
    "SpQRt2W21ObUsgynLQkDLPwjHXtWa2z4MU3aFG6lfp8"
  ]
}
==============================
With Disclosures
==============================
["30hrimjEfcym7kXSqOFxww","adress",{"street_address":"Schulstr. 12","region":"Sachsen-Anhalt","country":"DE","locality":"Schulpforta"}]
==============================
```