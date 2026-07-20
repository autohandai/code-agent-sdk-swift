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

public enum AutoModeRunStatus: String, Codable, Sendable, CaseIterable {
  case running
  case paused
  case completed
  case cancelled
  case failed
}

public struct AutoModeCheckpoint: Codable, Sendable, Equatable {
  public let commit: String
  public let message: String
  public let timestamp: String

  public init(commit: String, message: String, timestamp: String) {
    self.commit = commit
    self.message = message
    self.timestamp = timestamp
  }
}

public struct AutoModeState: Codable, Sendable, Equatable {
  public let sessionId: String
  public let status: AutoModeRunStatus
  public let currentIteration: Int
  public let maxIterations: Int
  public let filesCreated: Int
  public let filesModified: Int
  public let branch: String?
  public let lastCheckpoint: AutoModeCheckpoint?

  public init(
    sessionId: String,
    status: AutoModeRunStatus,
    currentIteration: Int,
    maxIterations: Int,
    filesCreated: Int,
    filesModified: Int,
    branch: String? = nil,
    lastCheckpoint: AutoModeCheckpoint? = nil
  ) {
    self.sessionId = sessionId
    self.status = status
    self.currentIteration = currentIteration
    self.maxIterations = maxIterations
    self.filesCreated = filesCreated
    self.filesModified = filesModified
    self.branch = branch
    self.lastCheckpoint = lastCheckpoint
  }
}

public struct AutoModeStatusResult: Codable, Sendable, Equatable {
  public let active: Bool
  public let paused: Bool
  public let state: AutoModeState?

  public init(active: Bool, paused: Bool, state: AutoModeState? = nil) {
    self.active = active
    self.paused = paused
    self.state = state
  }
}

public struct AutoModeOperationResult: Codable, Sendable, Equatable {
  public let success: Bool
  public let error: String?

  public init(success: Bool, error: String? = nil) {
    self.success = success
    self.error = error
  }
}

public struct AutoModeCancelParameters: Codable, Sendable, Equatable {
  public let reason: String?

  public init(reason: String? = nil) {
    self.reason = reason
  }
}

public struct AutoModeLogParameters: Codable, Sendable, Equatable {
  public let limit: Int?

  public init(limit: Int? = nil) {
    self.limit = limit
  }
}

public struct AutoModeLogCheckpoint: Codable, Sendable, Equatable {
  public let commit: String
  public let message: String

  public init(commit: String, message: String) {
    self.commit = commit
    self.message = message
  }
}

public struct AutoModeIteration: Codable, Sendable, Equatable {
  public let iteration: Int
  public let timestamp: String
  public let actions: [String]
  public let tokensUsed: Int?
  public let cost: Double?
  public let checkpoint: AutoModeLogCheckpoint?

  public init(
    iteration: Int,
    timestamp: String,
    actions: [String],
    tokensUsed: Int? = nil,
    cost: Double? = nil,
    checkpoint: AutoModeLogCheckpoint? = nil
  ) {
    self.iteration = iteration
    self.timestamp = timestamp
    self.actions = actions
    self.tokensUsed = tokensUsed
    self.cost = cost
    self.checkpoint = checkpoint
  }
}

public struct AutoModeLogResult: Codable, Sendable, Equatable {
  public let success: Bool
  public let iterations: [AutoModeIteration]
  public let error: String?

  public init(
    success: Bool,
    iterations: [AutoModeIteration],
    error: String? = nil
  ) {
    self.success = success
    self.iterations = iterations
    self.error = error
  }
}
