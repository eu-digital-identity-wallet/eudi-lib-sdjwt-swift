# Example 4: W3C Verifiable Credentials Data Model v2.0

Description of the example in the [A.4. W3C Verifiable Credentials Data Model v2.0 specification](https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-12.html#name-w3c-verifiable-credentials-)


```json
{
  "@context": [
    "https://www.w3.org/2018/credentials/v1",
    "https://w3id.org/vaccination/v1"
  ],
  "type": [
    "VerifiableCredential",
    "VaccinationCertificate"
  ],
  "issuer": "https://example.com/issuer",
  "issuanceDate": "2023-02-09T11:01:59Z",
  "expirationDate": "2028-02-08T11:01:59Z",
  "name": "COVID-19 Vaccination Certificate",
  "description": "COVID-19 Vaccination Certificate",
  "credentialSubject": {
    "vaccine": {
      "type": "Vaccine",
      "atcCode": "J07BX03",
      "medicinalProductName": "COVID-19 Vaccine Moderna",
      "marketingAuthorizationHolder": "Moderna Biotech"
    },
    "nextVaccinationDate": "2021-08-16T13:40:12Z",
    "countryOfVaccination": "GE",
    "dateOfVaccination": "2021-06-23T13:40:12Z",
    "order": "3/3",
    "recipient": {
      "type": "VaccineRecipient",
      "gender": "Female",
      "birthDate": "1961-08-17",
      "givenName": "Marion",
      "familyName": "Mustermann"
    },
    "type": "VaccinationEvent",
    "administeringCentre": "Praxis Sommergarten",
    "batchNumber": "1626382736",
    "healthProfessional": "883110000015376"
  }
}
```

```swift
     @SDJWTBuilder
    var w3c: SdElement {

      ConstantClaims.iat(time: Date())
      ConstantClaims.exp(time: Date() + 3600)
      ConstantClaims.iss(domain: "https://example.com/issuer")
      
      PlainClaim("name", "COVID-19 Vaccination Certificate")
      PlainClaim("description", "COVID-19 Vaccination Certificate")
      
      ArrayClaim("@context", array: [
        .plain("https://www.w3.org/2018/credentials/v1"),
        .plain("https://w3id.org/vaccination/v1")
      ])
      
      ArrayClaim("type", array: [
        .plain("VerifiableCredential"),
        .plain("VaccinationCertificate")
      ])
      
      ObjectClaim("cnf") {
        ObjectClaim("jwk") {
          PlainClaim("kty", "EC")
          PlainClaim("y", jwk.y?.base64URLEncode())
          PlainClaim("x", jwk.x?.base64URLEncode())
          PlainClaim("crv", jwk.curve?.rawValue)
        }
      }
      
      ObjectClaim("credentialSubject") {
        PlainClaim("type", "VaccinationEvent")
        
        FlatDisclosedClaim("nextVaccinationDate", "2021-08-16T13:40:12Z")
        FlatDisclosedClaim("countryOfVaccination", "GE")
        FlatDisclosedClaim("dateOfVaccination", "2021-06-23T13:40:12Z")
        FlatDisclosedClaim("order", "3/3")
        FlatDisclosedClaim("administeringCentre", "Praxis Sommergarten")
        FlatDisclosedClaim("batchNumber", "1626382736")
        FlatDisclosedClaim("healthProfessional", "883110000015376")
        
        ObjectClaim("vaccine") {
          PlainClaim("type", "Vaccine")
          FlatDisclosedClaim("atcCode", "J07BX03")
          FlatDisclosedClaim("medicinalProductName", "COVID-19 Vaccine Moderna")
          FlatDisclosedClaim("marketingAuthorizationHolder", "Moderna Biotech")
        }
        
        ObjectClaim("recipient") {
          PlainClaim("type", "VaccineRecipient")
          
          FlatDisclosedClaim("gender", "Female")
          FlatDisclosedClaim("birthDate", "1961-08-17")
          FlatDisclosedClaim("givenName", "Marion")
          FlatDisclosedClaim("familyName", "Mustermann")
        }
      }
    }
```

```json
JSON Value of sdjwt
==============================
{
  "@context" : [
    "https:\/\/www.w3.org\/2018\/credentials\/v1",
    "https:\/\/w3id.org\/vaccination\/v1"
  ],
  "description" : "COVID-19 Vaccination Certificate",
  "iss" : "https:\/\/example.com\/issuer",
  "name" : "COVID-19 Vaccination Certificate",
  "exp" : 1736254903,
  "type" : [
    "VerifiableCredential",
    "VaccinationCertificate"
  ],
  "_sd_alg" : "sha-256",
  "cnf" : {
    "jwk" : {
      "crv" : "P-256",
      "x" : "jssFS-Li8gPIeXuIAKJG0312K1qWJWwBF5uDxYflcyY",
      "kty" : "EC",
      "y" : "3rxERYpq9FRDG_R5pcs9T-MfxDGpZsFH4nJ4tzyOHwg"
    }
  },
  "iat" : 1736251303,
  "credentialSubject" : {
    "_sd" : [
      "Af5hXGUA9mlwKpvwn-tZ1L8cvHVw1074LvBMYiLTuHk",
      "iiUvzT5fAkxbe3Wdcx4UFsowR_SYpCstPyBCJK4RSnw",
      "cVzWvuDvrm0rmaOWqxjb8LKFsh8RKpkpI1iYO-QB_vE",
      "eZowknNkiLUFnCU0vuIrVK3VnNt6dnSJmBZP4m5YpTw",
      "Ky67aRyp3Yw0uJtWSwzqYEaFtyCikok-N6AzggNVPZU",
      "mrB8756df70aNQ8urt4ScW-yxVPxlC8CpCGgXY_4YZg",
      "BC7Osf0BpOMc_6jKD6M5sWCoTKIHMtDjRuFQzet7BqQ"
    ],
    "type" : "VaccinationEvent",
    "recipient" : {
      "type" : "VaccineRecipient",
      "_sd" : [
        "TRxiZXx1J_dFgWsQJ6Z59dxSxWMj21cJbax3zS42Zi8",
        "xsy0M42R5RotdT26XJEJr_mKtTQH4x3NEoV4yFz1Y-U",
        "ZSyUVGCLtWI8Hf47C1f0QG7lmHxUXtb27d0pnqCjrUA",
        "icoGd1rZeb1SteDkrdJK7tm3ZwurXTmnmcGE3aMxvIQ"
      ]
    },
    "vaccine" : {
      "_sd" : [
        "MnbuUlSYyRcDXynj_6RiacuBNWCDarVciyP0MdkwJV0",
        "jtDahbSRxPnLhdbK3tIKl5xRnzZ5iRP28ioEuUiggjg",
        "3wRG4lMIQuIQey5LeJPkujD0N5k5dli7b47-Wxz318E"
      ],
      "type" : "Vaccine"
    }
  }
}
==============================
With Disclosures
==============================
["salt","gender","Female"]
["salt","givenName","Marion"]
["salt","birthDate","1961-08-17"]
["salt","familyName","Mustermann"]
["salt","administeringCentre","Praxis Sommergarten"]
["salt","dateOfVaccination","2021-06-23T13:40:12Z"]
["salt","batchNumber","1626382736"]
["salt","countryOfVaccination","GE"]
["salt","healthProfessional","883110000015376"]
["salt","medicinalProductName","COVID-19 Vaccine Moderna"]
["salt","atcCode","J07BX03"]
["salt","marketingAuthorizationHolder","Moderna Biotech"]
["salt","order","3/3"]
["salt","nextVaccinationDate","2021-08-16T13:40:12Z"]
```