import Foundation

public protocol AsyncSignerProtocol {
  func signAsync(_ data: Data) async throws -> Data
}