import XCTest
@testable import eudi_lib_sdjwt_swift

final class IssuanceTests: XCTestCase {

    func testDisclsure() {
        let parts = ["_26bc4LT-ac6q2KI6cBW5es", "family_name", "Möbius"]
        let salt = parts[0]
        let key = parts[1]
        let value = parts [2]

        var disclosedClaim = DisclosedClaim(key, .init(value))

        let disclosure = try! disclosedClaim.base64Encode(saltProvider: Signer(saltProvider: MockSaltProvider(saltString: salt)).saltProvider)

        print(disclosure)
        print(disclosure?.flatString)

        XCTAssertTrue(disclosure?.flatString.contains("WyJfMjZiYzRMVC1hYzZxMktJNmNCVzVlcyIsICJmYW1pbHlfbmFtZSIsICJNw7ZiaXVzIl0") == true)
    }

    func testArray() {
        let parts = ["lklxF5jMYlGTPUovMNIvCA", "FR"]
        let key = "nationalities"
        let salt = parts[0]
        let value = parts[1]

        var disclosedClaim = DisclosedClaim(key, .array([.init(value)]))

        let disclosure = try! disclosedClaim.base64Encode(saltProvider: Signer(saltProvider: MockSaltProvider(saltString: salt)).saltProvider)

        print(disclosure)
        print(disclosure?.flatString)

        XCTAssertTrue(disclosure?.flatString.contains("WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgIkZSIl0") == true)

    }

    func testMixedArray() {
        let plainClaim = PlainClaim("nationalities", .array([.init("DE")]))
        var disclosedArray = DisclosedClaim("nationalities", .array([.init("FR")]))

        guard let encodedClaim = try? disclosedArray.base64Encode(saltProvider: MockSaltProvider(saltString: "lklxF5jMYlGTPUovMNIvCA")) else {
            XCTFail()
            return
        }

        let mixedClaim = MixedClaim(plainClaim: plainClaim,
                                    disclosedClaim: encodedClaim)

        print(mixedClaim)
        print(mixedClaim?.flatString)

        XCTAssertTrue(mixedClaim?.flatString.contains("WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgIkZSIl0") == true)
        XCTAssertTrue(mixedClaim?.flatString.contains("DE") == true)

    }
}
