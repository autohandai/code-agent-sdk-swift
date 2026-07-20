import Foundation

/// Result returned after replacing the active CLI conversation.
public struct ConversationResetResult: Codable, Sendable, Equatable {
  public let sessionId: String

  public init(sessionId: String) {
    self.sessionId = sessionId
  }
}

public struct BrowserHandoffCreateParameters: Codable, Sendable, Equatable {
  public let extensionId: String?
  public let installUrl: String?

  public init(extensionId: String? = nil, installUrl: String? = nil) {
    self.extensionId = extensionId
    self.installUrl = installUrl
  }
}

public struct BrowserHandoffCreateResult: Codable, Sendable, Equatable {
  public let token: String
  public let sessionId: String
  public let workspaceRoot: String
  public let createdAt: String
  public let expiresAt: String
  public let url: String

  public init(
    token: String,
    sessionId: String,
    workspaceRoot: String,
    createdAt: String,
    expiresAt: String,
    url: String
  ) {
    self.token = token
    self.sessionId = sessionId
    self.workspaceRoot = workspaceRoot
    self.createdAt = createdAt
    self.expiresAt = expiresAt
    self.url = url
  }
}
