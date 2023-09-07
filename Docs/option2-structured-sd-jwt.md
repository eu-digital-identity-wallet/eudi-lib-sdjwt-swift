# Option 2: Structured SD-JWT

Check [specification Option 2: Structured SD-JWT](https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-05.html#name-option-2-structured-sd-jwt)

The example bellow demonstrates the usage of the library mixed with the Kotlinx Serialization DSL
to produce a SD-JWT which contains claim `sub` plain and `address` claim contents selectively disclosable individually


```swift
    @SDJWTBuilder
    var structured: SdElement {
      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date() + 3600)
      ConstantClaims.iss(domain: "https://example.com/issuer")
      ConstantClaims.sub(subject: "6c5c0a49-b589-431d-bae7-219122a9ec2c")

      ObjectClaim("adress") {
        FlatDisclosedClaim("street_address", "Schulstr. 12")
        FlatDisclosedClaim("locality", "Schulpforta")
        FlatDisclosedClaim("region", "Sachsen-Anhalt")
        FlatDisclosedClaim("country", "DE")
      }
    }
```
```json
Payload JSON Value of sdjwt
==============================
{
  "exp" : 1693475797,
  "iss" : "https:\/\/example.com\/issuer",
  "_sd_alg" : "sha-256",
  "sub" : "6c5c0a49-b589-431d-bae7-219122a9ec2c",
  "iat" : 1693472197,
  "adress" : {
    "_sd" : [
      "u4RK-WS9Ip1ithdRZSK1SUOgRh2uOI-cwFvVNccwpaY",
      "uuWdWNVWVzaBpMpJJk6juAoY50BB34woJcUo470kZP8",
      "HpARQbCHbfAhnrXJ-X51F4lbcgKUKhRxuuAcUbodcAk",
      "GsIUyUPE8-jswpSmQmI9_9UGrtlIVrptTNFB0yD8LPE"
    ]
  }
}
==============================
With Disclosures
==============================
["HGc5FbvrJzYLfHL0MSnLRg","street_address","Schulstr. 12"]
["eQnkqHQAuoax2bjQm_Kxpg","region","Sachsen-Anhalt"]
["GJblUU_ZgqtrsjD1Xwp1AQ","locality","Schulpforta"]
["Bnt12MRgXMuDeezf9kB6nA","country","DE"]
==============================
```