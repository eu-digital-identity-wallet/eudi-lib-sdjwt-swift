# Option 3: SD-JWT with Recursive Disclosures

Check [specification Option 3: SD-JWT with Recursive Disclosures](https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-05.html#name-option-3-sd-jwt-with-recurs)

```swift
    @SDJWTBuilder
    var structured: SdElement {
      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date() + 3600)
      ConstantClaims.iss(domain: "https://example.com/issuer")
      ConstantClaims.sub(subject: "6c5c0a49-b589-431d-bae7-219122a9ec2c")
      
      RecursiveObject("adress") {
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
  "exp" : 1693476949,
  "iss" : "https:\/\/example.com\/issuer",
  "_sd_alg" : "sha-256",
  "_sd" : [
    "7jN-o5-81J63qE2vXORpKaY7Zm52GlCXQsrCaRaiFcE"
  ],
  "sub" : "6c5c0a49-b589-431d-bae7-219122a9ec2c",
  "iat" : 1693473349
}
==============================
With Disclosures
==============================
["x5HSiohyCn3FUZe0MXuUUw","street_address","Schulstr. 12"]
["ltC5iRybCpKoPTn3Diz-Fg","region","Sachsen-Anhalt"]
["QYlVZtL6zlyKVFc3FCGs6A","country","DE"]
["w4FfTXW36JGoeUM1k8D0_Q","locality","Schulpforta"]
["qkE1fgF5zqyYukatAcy17A","adress",{"_sd":["gNdvCgycudh2vNa_exsWr6_igezWEkoln_vTmNMuEGU","ss9r1unU3BIesHy64eSS11uFbUeh_Oxmw1CdGCjEAhU","w9onM-lt7tq6UCSb4sTDRX2X7amR20A2IA24DVtOutc","MtOONqFr0_E86SSWGxFA0XYwPkDZsyRIQ4qRtiErLQU"]}]
==============================
```