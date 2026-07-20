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

public struct DirectoryAccessResponseParameters: Codable, Sendable, Equatable {
  public let requestId: String
  public let granted: Bool

  public init(requestId: String, granted: Bool) {
    self.requestId = requestId
    self.granted = granted
  }
}

public struct DirectoryAccessResponseResult: Codable, Sendable, Equatable {
  public let success: Bool

  public init(success: Bool) {
    self.success = success
  }
}

public struct DirectoryAccessAcknowledgementParameters: Codable, Sendable, Equatable {
  public let requestId: String

  public init(requestId: String) {
    self.requestId = requestId
  }
}

public struct DirectoryAccessAcknowledgementResult: Codable, Sendable, Equatable {
  public let success: Bool

  public init(success: Bool) {
    self.success = success
  }
}
