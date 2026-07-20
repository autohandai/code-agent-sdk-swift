import Foundation

public struct PermissionAcknowledgementParameters: Codable, Sendable, Equatable {
  public let requestId: String

  public init(requestId: String) {
    self.requestId = requestId
  }
}

public struct PermissionAcknowledgementResult: Codable, Sendable, Equatable {
  public let success: Bool

  public init(success: Bool) {
    self.success = success
  }
}
