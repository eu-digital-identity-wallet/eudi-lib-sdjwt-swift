import XCTest
@testable import eudi_lib_sdjwt_swift

final class eudi_lib_sdjwt_swiftTests: XCTestCase {

    func testDisclsure() {
        let parts = ["_26bc4LT-ac6q2KI6cBW5es", "family_name", "Möbius"]
        let salt = parts[0]
        let key = parts[1]
        let value = parts [2]

        var disclosedClaim = DisclosedClaim(key, .init(value))

        let disclosure = try? disclosedClaim.base64Encode(saltProvider: Signer(saltProvider: MockSaltProvider(saltString: salt)).saltProvider)

        print(disclosure)
        print(disclosure?.flatString)

        XCTAssertTrue(disclosure?.flatString.contains("WyJfMjZiYzRMVC1hYzZxMktJNmNCVzVlcyIsICJmYW1pbHlfbmFtZSIsICJNw7ZiaXVzIl0") == true)
    }
}
