# Example 2a: Handling Structured Claims

Description of the example in the [specification Example 2a: Handling Structured  Claims](https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-05.html#name-example-2-handling-structur)

```json
{
  "sub": "6c5c0a49-b589-431d-bae7-219122a9ec2c",
  "given_name": "太郎",
  "family_name": "山田",
  "email": "\"unusual email address\"@example.jp",
  "phone_number": "+81-80-1234-5678",
  "address": {
    "street_address": "東京都港区芝公園４丁目２−８",
    "locality": "東京都",
    "region": "港区",
    "country": "JP"
  },
  "birthdate": "1940-01-01"
}
```

```swift
    @SDJWTBuilder
    var structuredSDJWT: SdElement {
      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date() + 3600)
      ConstantClaims.iss(domain: "https://example.com/issuer")
      FlatDisclosedClaim("sub", "6c5c0a49-b589-431d-bae7-219122a9ec2c")
      FlatDisclosedClaim("given_name", "太郎")
      FlatDisclosedClaim("family_name", "山田")
      FlatDisclosedClaim("email", "\"unusual email address\"@example.jp")
      FlatDisclosedClaim("phone_number", "+81-80-1234-5678")
      ObjectClaim("address") {
        FlatDisclosedClaim("street_address", "東京都港区芝公園４丁目２−８")
        FlatDisclosedClaim("locality", "東京都")
        FlatDisclosedClaim("region", "港区")
        FlatDisclosedClaim("country", "JP")
      }
      FlatDisclosedClaim("birthdate", "1940-01-01")
    }
```

After adding Decoy Digests in the SD Payload
10 disclosures for 15 digests

```json
Payload JSON Value of sdjwt
==============================
{
  "exp" : 1693476076,
  "address" : {
    "_sd" : [
      "-GHSPEwvR3C4E3HU-Pops5bukBPJ65j-UdTAm9LkKfI",
      "jy6BwCH4zP3AqOvUNf11ty7Q4gQIWlyyB-Zz9W8MPC8",
      "zDZk_WUZD-dK2hI8ealtYD-HB_sBqkiQrztuRW0yALc",
      "-o63KXi5kRVCU0dB7Dpq7D3mogWyMHF4qyCMe2kyxfI"
    ]
  },
  "iss" : "https:\/\/example.com\/issuer",
  "_sd_alg" : "sha-256",
  "_sd" : [
    "VEnlvbQTzBgXR-TYDFFXsgzhm6X29Gsm9hHDPoEPkkg",
    "av9XGX_cMoxpBfcUX7YWkLPA5HAiXAZCX9QuQg0JqM8",
    "fphL1dl65jV0fIr5TfYscypi-v3Qev4ehh2tJ4nJ3NE",
    "i0rFL8M0wVa8zBnfpq_Os_7V5_h6mJqux8vGr_zIaDc",
    "qrOBwn3VXxZDXknuO6HoKCUflvtAUIy_Ui4ObRp3ebo",
    "D0ODQBdTLVpfD9VPZEmYFyYmI9DGFl_vLuegATIH7KA",
    "oydM1mWCRLfamoGo9schOAtPAHx9dM1QQU0bv_pPZok",
    "rwij4_kRA0Vt3NMAz6MZoG65OJN2s_vCZbLZyTuL_Y8",
    "nwyvw2BTX2P1KSEvxIWF1QNkQYxBGOs0iDU3KBwa1BI",
    "Xkmd7WqHN8ipOcZkMsndun5T435EVO3sX1WcmdPBWiY",
    "tVnTzjl14yUIXf_EYqLgkg5l4y7f9j8eZAx-68LWe5o",
    "IE2zXBkmSKUTbPkNLiU6oq0f2csHbgMaO2l--nMWdr0"
  ],
  "iat" : 1693472476
}
==============================
With Disclosures
==============================
["J6whWG_XGPP0Y2qm_tW7qA","family_name","山田"]
["EWxci7PlRVHXE8xpDPlXnw","sub","6c5c0a49-b589-431d-bae7-219122a9ec2c"]
["4ftGy2cRiP0Q-tseFULfYA","phone_number","+81-80-1234-5678"]
["5-VsBOUtiV5t6EqqCGPrVQ","birthdate","1940-01-01"]
["TBztzKhMKv7CUf2KWGuu4w","email","\"unusual email address\"@example.jp"]
["2NcRy5Bm88bLMVy_iRRmfA","street_address","東京都港区芝公園４丁目２−８"]
["ud51p-Cj1akldeXWNhFqkA","country","JP"]
["hYWjeHIjOauji-ieZANsVg","region","港区"]
["a2xI7Z5yA3eplfoK767Nvg","locality","東京都"]
["KdmE1xeG3eQFMXVACGOj8A","given_name","太郎"]
==============================
```
