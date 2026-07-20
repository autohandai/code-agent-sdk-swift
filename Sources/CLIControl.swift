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

public struct BrowserHandoffAttachParameters: Codable, Sendable, Equatable {
  public let token: String

  public init(token: String) {
    self.token = token
  }
}

public struct BrowserHandoffAttachResult: Codable, Sendable, Equatable {
  public let success: Bool
  public let sessionId: String?
  public let workspaceRoot: String?
  public let messageCount: Int?

  public init(
    success: Bool,
    sessionId: String? = nil,
    workspaceRoot: String? = nil,
    messageCount: Int? = nil
  ) {
    self.success = success
    self.sessionId = sessionId
    self.workspaceRoot = workspaceRoot
    self.messageCount = messageCount
  }
}

public struct AutoModeStartParameters: Codable, Sendable, Equatable {
  public let prompt: String
  public let maxIterations: Int?
  public let completionPromise: String?
  public let useWorktree: Bool?
  public let checkpointInterval: Int?
  public let maxRuntime: Int?
  public let maxCost: Double?

  public init(
    prompt: String,
    maxIterations: Int? = nil,
    completionPromise: String? = nil,
    useWorktree: Bool? = nil,
    checkpointInterval: Int? = nil,
    maxRuntime: Int? = nil,
    maxCost: Double? = nil
  ) {
    self.prompt = prompt
    self.maxIterations = maxIterations
    self.completionPromise = completionPromise
    self.useWorktree = useWorktree
    self.checkpointInterval = checkpointInterval
    self.maxRuntime = maxRuntime
    self.maxCost = maxCost
  }
}

public struct AutoModeStartResult: Codable, Sendable, Equatable {
  public let success: Bool
  public let sessionId: String?
  public let error: String?

  public init(success: Bool, sessionId: String? = nil, error: String? = nil) {
    self.success = success
    self.sessionId = sessionId
    self.error = error
  }
}
