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
  "exp" : 1693477311,
  "iss" : "https:\/\/example.com\/issuer",
  "_sd_alg" : "sha-256",
  "verified_claims" : {
    "claims" : {
      "_sd" : [
        "D9D5ldd666CVuxC7vyWSQHJEo31ZsK8Cns6dlqDPpUY",
        "4PeAg-yUb-_XRD4FVhuFhi2xUgAAUxUUj_CV7t8vBs8",
        "R22loaJH3C0ZFxYS-Qe7wmcStVc6qWwjlrRvdjMZtN0",
        "6GX41M83BjwE0x0Sb7QdkVC5-V56AyxzHWH2Qyr34Qk",
        "y7NsdXEN7F19b5msr9fsOeFM5rOO7Y4xZiKheCdmsRo",
        "NIZVocHwnLyZyIuILtzpSeuGKpfgh_9du2AfjioKrpo"
      ]
    },
    "verification" : {
      "_sd" : [
        "xbqjAvqZtReHAU6-aLtdj30OkKUJcgdtEoMggaiFk08",
        "T2L1vmdI4FiBKFdLGePY7jZpn7DCFKBeRx-3Rz5GC04"
      ],
      "trust_framework" : "de_aml",
      "evidence" : [
        {
          "..." : "6hhIPr_K4X2CTGiWhWBW8JUx9ibM3h0G9cKZYrTRtoI"
        }
      ]
    }
  },
  "_sd" : [
    "fT0cytB4jAEXfGmjINXO_2giBC4GVo-E3hq5poC013g",
    "3_qtX3_E3XcM_OV_TrA-nDaQBjOYvWcIvNP7GPjchmM",
    "62Vfag5nsHC66LdeEDlsHacTsstkDb6Qo3Yuhjgmkac"
  ],
  "iat" : 1693473711
}
==============================
With Disclosures
==============================
["PLSWuFPPd7EYXG4BBP1Rqw","msisdn","49123456789"]
["QVuXF0zd4nyBr8CaqzByEw","place_of_birth",{"locality":"Þykkvabæjarklaustur","country":"IS"}]
["TwskWIIs51XJ3-gsCkmuXQ","given_name","Max"]
["w7fja-OpJgndtFHhBE-GUA","nationalities",["DE"]]
["HrGCNG0CFKmWJG9U-1L7tQ","family_name","Müller"]
["FfpVmyDQOQIpVyOB3uXXFw","birthdate","1956-01-28"]
["YfO8E3mhaUhHc8OWA1ytWQ","address",{"country":"DE","street_address":"Weidenstraße 22","locality":"Maxstadt","postal_code":"12344"}]
["E-Ia-sPmuOMslR9kywLYLA","verification_process","f24c6f-6d3f-4ec5-973e-b0d8506f3bc7"]
["AH_9zowEJlF4pfkMKyoN9w","time","2012-04-23T18:25Z"]

["w1iOVocFVPPrzinmRprrww",{"date_of_issuance":"2010-03-23","type":"document","method":"pipp","document":{"type":"idcard","issuer":{"country":"DE","name":"Stadt Augsburg"}},"time":"2012-04-22T11:30Z","date_of_expiry":"2020-03-22","number":"53554554"}]

["Al9TAw8odPtkWDg6yMerGQ","birth_middle_name","Timotheus"]
["9aj-PjSm-aFmUr1dJ-T6bw","salutation","Dr."]
==============================
```