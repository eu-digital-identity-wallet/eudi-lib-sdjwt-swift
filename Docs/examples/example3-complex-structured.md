# Example 3: Complex Structured SD-JWT

Description of the example in the [specification Example 3: Complex Structured SD-JWT](https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-05.html#name-example-3-complex-structure)


```json
{
  "verified_claims": {
    "verification": {
      "trust_framework": "de_aml",
      "time": "2012-04-23T18:25Z",
      "verification_process": "f24c6f-6d3f-4ec5-973e-b0d8506f3bc7",
      "evidence": [
        {
          "type": "document",
          "method": "pipp",
          "time": "2012-04-22T11:30Z",
          "document": {
            "type": "idcard",
            "issuer": {
              "name": "Stadt Augsburg",
              "country": "DE"
            },
            "number": "53554554",
            "date_of_issuance": "2010-03-23",
            "date_of_expiry": "2020-03-22"
          }
        }
      ]
    },
    "claims": {
      "given_name": "Max",
      "family_name": "Müller",
      "nationalities": [
        "DE"
      ],
      "birthdate": "1956-01-28",
      "place_of_birth": {
        "country": "IS",
        "locality": "Þykkvabæjarklaustur"
      },
      "address": {
        "locality": "Maxstadt",
        "postal_code": "12344",
        "country": "DE",
        "street_address": "Weidenstraße 22"
      }
    }
  },
  "birth_middle_name": "Timotheus",
  "salutation": "Dr.",
  "msisdn": "49123456789"
}
```

```swift
 @SDJWTBuilder
    var complex: SdElement {

      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date() + 3600)
      ConstantClaims.iss(domain: "https://example.com/issuer")

      ObjectClaim("verified_claims") {
        ObjectClaim("verification") {
          PlainClaim("trust_framework", "de_aml")
          FlatDisclosedClaim("time", "2012-04-23T18:25Z")
          FlatDisclosedClaim("verification_process", "f24c6f-6d3f-4ec5-973e-b0d8506f3bc7")
          SdArrayClaim("evidence") {
            evidenceObject
          }
        }
        ObjectClaim("claims") {
          FlatDisclosedClaim("given_name", "Max")
          FlatDisclosedClaim("family_name", "Müller")
          FlatDisclosedClaim("nationalities", ["DE"])
          FlatDisclosedClaim("birthdate", "1956-01-28")
          FlatDisclosedClaim("place_of_birth", ["country": "IS",
                                                "locality": "Þykkvabæjarklaustur"])
          FlatDisclosedClaim("address", ["locality": "Maxstadt",
                                         "postal_code": "12344",
                                         "country": "DE",
                                         "street_address": "Weidenstraße 22"])
        }
      }

      FlatDisclosedClaim("birth_middle_name", "Timotheus")
      FlatDisclosedClaim("salutation", "Dr.")
      FlatDisclosedClaim("msisdn", "49123456789")
    }
    // Separating for clarity purposes. Object to be disclosed in the array
    @SDJWTBuilder
    var evidenceObject: SdElement {
      PlainClaim("type", "document")
      PlainClaim("method", "pipp")
      PlainClaim("time", "2012-04-22T11:30Z")
      ObjectClaim("document") {
        PlainClaim("type", "idcard")
        ObjectClaim("issuer") {
          PlainClaim("name", "Stadt Augsburg")
          PlainClaim("country", "DE")
        }
      }

      PlainClaim("number", "53554554")
      PlainClaim("date_of_issuance", "2010-03-23")
      PlainClaim("date_of_expiry", "2020-03-22")
    }
```

```json
JSON Value of sdjwt
==============================
{
  "exp" : 1694616876,
  "iss" : "https:\/\/example.com\/issuer",
  "verified_claims" : {
    "claims" : {
      "_sd" : [
        "ziKmQIPbGTt1x8Q3wbia7r-Zvm6dmuTxQZ0J5NbxpuE",
        "VOFWFwzrQtfuWArkXfOWE6DDBr0nznkZ7lCw9BaczlA",
        "iNxcbxgciL2UOhQIvMyU609ykxKRNYfYdz9xZaVJtAQ",
        "XoR-qXFiRqyNPtHkydYKxNDxWgOETbzS2lHC2knxYLg",
        "Ex_ubtfg2HDx-j_ujHfgIhI77ZQQyMn3U_a3mPOKLx8",
        "3w8ueFwDsyUWovV44TrAPsA2wye8HqsEe7yLM9dN818"
      ]
    },
    "verification" : {
      "_sd" : [
        "SP0gLtOZCJHxGsfDuIxh0LEOARZb8LrMrX9Fnr88CnQ",
        "dMRmBDM58YkD9zuFuPnwfnRzM3rxjnl8aUkcIxSQrnA"
      ],
      "trust_framework" : "de_aml",
      "evidence" : [
        {
          "..." : "ByYJee1teZA705kii69vLI67nmr2QK9LWHlyIKJYWgs"
        }
      ]
    }
  },
  "_sd" : [
    "3q3cn0A0yF4AsNue8LZZfRx5-2ptZkDtmcSSv6GkWyk",
    "h5egrlhq1ahMMHqC7KS01zlHwJzK1U3bkIAk35Wpa6o",
    "D81Xni2Fr-sNsRztSjGC6vrUl3YECgSE5OF3r83ubfw"
  ],
  "_sd_alg" : "sha-256",
  "iat" : 1694613276
}
==============================
With Disclosures
==============================
["6wlBeHpYNWtycPrdTTNHEQ","time","2012-04-23T18:25Z"]
["OVVl_43krbwsRYyARawPSQ","verification_process","f24c6f-6d3f-4ec5-973e-b0d8506f3bc7"]
["LvqL5qMyV1OwVCv-CgBfBw","document",{"issuer":{"country":"DE","name":"Stadt Augsburg"},"number":"53554554","type":"idcard","date_of_issuance":"2010-03-23","date_of_expiry":"2020-03-22"}]
["YjFGa5Eh75bT2LufTuVjoQ","time","2012-04-22T11:30Z"]
["8YUOCAETbgiovtP70DaxLw","method","pipp"]
["EUFIy-NgCNqVd57jsQbSAA","type","document"]
["f8uDlw7IVwv7h00orDlNnw",{"_sd":["VUGrwGNkcddZ52h9BfL6rDrIp-9Td0u2cpiVBITt-4E","ZkzAOYd7X4MBtpaoVSnJadzDzl_4X0S_JYwfrYkXb28","egOBomjun1tPcvECKX8Kf1Cq7Z3vYbW917cyi46LiLY","GCfaM7xOU2R2IUI8coleEn7BS-lhOxpqT8a2xeee3tA"]}]
["WDkvrQl1LppGB0Ggc_EQ8Q","address",{"locality":"Maxstadt","street_address":"Weidenstraße 22","postal_code":"12344","country":"DE"}]
["49g88l4NGB2xfL_K6gBmjQ","family_name","Müller"]
["WTJXaTT3OWteMKEbg8Uscw","given_name","Max"]
["8HQ9CT6KieyIJEjIbko_wA","nationalities",["DE"]]
["9veIh90MR9VUw8Mz4dH-jQ","birthdate","1956-01-28"]
["3NwGv8WPLuhQ883w_r2CUg","place_of_birth",{"country":"IS","locality":"Þykkvabæjarklaustur"}]
["QCRB3icAzmuoXqe5lS3Jhw","birth_middle_name","Timotheus"]
["ux6WeDTtf4czdFVlpl3bmg","salutation","Dr."]
["GfcGwDjbbn4r869bM7OD1g","msisdn","49123456789"]
```
