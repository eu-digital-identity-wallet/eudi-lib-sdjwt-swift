import CryptoKit
import Foundation

@testable import eudi_lib_sdjwt_swift

public struct TestP256AsyncSigner: AsyncSignerProtocol {
    private let secKey: SecKey

    public init(secKey: SecKey) {
        self.secKey = secKey
    }

    public func signAsync(_ data: Data) async throws -> Data {
        guard let keyData = SecKeyCopyExternalRepresentation(secKey, nil) as Data? else {
            throw SDJWTError.keyCreation
        }
        let p256 = try P256.Signing.PrivateKey.init(x963Representation: keyData)
        let signature = try p256.signature(for: data)
        return signature.rawRepresentation
    }
}
