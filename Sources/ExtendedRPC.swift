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

public enum ChangesDecisionAction: String, Codable, Sendable, CaseIterable {
  case acceptAll = "accept_all"
  case rejectAll = "reject_all"
  case acceptSelected = "accept_selected"
}

public struct ChangesDecisionParameters: Codable, Sendable, Equatable {
  public let batchId: String
  public let action: ChangesDecisionAction
  public let selectedChangeIds: [String]?

  public init(
    batchId: String,
    action: ChangesDecisionAction,
    selectedChangeIds: [String]? = nil
  ) {
    self.batchId = batchId
    self.action = action
    self.selectedChangeIds = selectedChangeIds
  }
}

public struct ChangesDecisionError: Codable, Sendable, Equatable {
  public let changeId: String
  public let error: String
}

public struct ChangesDecisionResult: Codable, Sendable, Equatable {
  public let success: Bool
  public let appliedCount: Int
  public let skippedCount: Int
  public let errors: [ChangesDecisionError]?
}

public struct SessionHistoryParameters: Codable, Sendable, Equatable {
  public let page: Int?
  public let pageSize: Int?

  public init(page: Int? = nil, pageSize: Int? = nil) {
    self.page = page
    self.pageSize = pageSize
  }
}

public enum SessionHistoryStatus: String, Codable, Sendable, CaseIterable {
  case active
  case completed
  case crashed
}

public struct SessionHistoryEntry: Codable, Sendable, Equatable {
  public let sessionId: String
  public let createdAt: String
  public let lastActiveAt: String
  public let projectName: String
  public let model: String
  public let messageCount: Int
  public let status: SessionHistoryStatus
}

public struct SessionHistoryResult: Codable, Sendable, Equatable {
  public let sessions: [SessionHistoryEntry]
  public let currentPage: Int
  public let totalPages: Int
  public let totalItems: Int
}

public struct SessionDetailsParameters: Codable, Sendable, Equatable {
  public let sessionId: String

  public init(sessionId: String) {
    self.sessionId = sessionId
  }
}

public enum SessionMessageRole: String, Codable, Sendable, CaseIterable {
  case user
  case assistant
  case system
  case tool
}

public struct SessionMessageToolCall: Codable, Sendable {
  public let id: String
  public let name: String
  public let args: [String: AnyCodable]
}

public struct SessionMessage: Codable, Sendable {
  public let id: String
  public let role: SessionMessageRole
  public let content: String
  public let timestamp: String
  public let toolCalls: [SessionMessageToolCall]?
}

public struct SessionDetailsSuccess: Sendable {
  public let sessionId: String
  public let projectName: String
  public let model: String
  public let messageCount: Int
  public let status: String
  public let createdAt: String
  public let lastActiveAt: String
  public let summary: String?
  public let messages: [SessionMessage]
  public let workspaceRoot: String
}

public struct SessionDetailsFailure: Sendable, Equatable {
  public let error: String?
}

public enum SessionDetailsResult: Codable, Sendable {
  case success(SessionDetailsSuccess)
  case failure(SessionDetailsFailure)

  public init(from decoder: Decoder) throws {
    let wire = try SessionDetailsWire(from: decoder)
    guard wire.success else {
      self = .failure(.init(error: wire.error))
      return
    }
    guard let sessionId = wire.sessionId,
      let projectName = wire.projectName,
      let model = wire.model,
      let messageCount = wire.messageCount,
      let status = wire.status,
      let createdAt = wire.createdAt,
      let lastActiveAt = wire.lastActiveAt,
      let messages = wire.messages,
      let workspaceRoot = wire.workspaceRoot
    else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: decoder.codingPath, debugDescription: "Successful session details are incomplete"))
    }
    self = .success(.init(
      sessionId: sessionId,
      projectName: projectName,
      model: model,
      messageCount: messageCount,
      status: status,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt,
      summary: wire.summary,
      messages: messages,
      workspaceRoot: workspaceRoot
    ))
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .success(let value):
      try SessionDetailsWire(
        success: true,
        sessionId: value.sessionId,
        projectName: value.projectName,
        model: value.model,
        messageCount: value.messageCount,
        status: value.status,
        createdAt: value.createdAt,
        lastActiveAt: value.lastActiveAt,
        summary: value.summary,
        messages: value.messages,
        workspaceRoot: value.workspaceRoot,
        error: nil
      ).encode(to: encoder)
    case .failure(let value):
      try SessionDetailsWire(success: false, error: value.error).encode(to: encoder)
    }
  }
}

private struct SessionDetailsWire: Codable {
  let success: Bool
  let sessionId: String?
  let projectName: String?
  let model: String?
  let messageCount: Int?
  let status: String?
  let createdAt: String?
  let lastActiveAt: String?
  let summary: String?
  let messages: [SessionMessage]?
  let workspaceRoot: String?
  let error: String?

  init(
    success: Bool,
    sessionId: String? = nil,
    projectName: String? = nil,
    model: String? = nil,
    messageCount: Int? = nil,
    status: String? = nil,
    createdAt: String? = nil,
    lastActiveAt: String? = nil,
    summary: String? = nil,
    messages: [SessionMessage]? = nil,
    workspaceRoot: String? = nil,
    error: String? = nil
  ) {
    self.success = success
    self.sessionId = sessionId
    self.projectName = projectName
    self.model = model
    self.messageCount = messageCount
    self.status = status
    self.createdAt = createdAt
    self.lastActiveAt = lastActiveAt
    self.summary = summary
    self.messages = messages
    self.workspaceRoot = workspaceRoot
    self.error = error
  }
}

public struct SessionAttachParameters: Codable, Sendable, Equatable {
  public let sessionId: String

  public init(sessionId: String) {
    self.sessionId = sessionId
  }
}

public struct SessionAttachResult: Codable, Sendable, Equatable {
  public let success: Bool
  public let sessionId: String?
  public let workspaceRoot: String?
  public let messageCount: Int?
  public let error: String?
}

public struct YoloSetParameters: Codable, Sendable, Equatable {
  public let pattern: String
  public let timeoutSeconds: Int?

  public init(pattern: String, timeoutSeconds: Int? = nil) {
    self.pattern = pattern
    self.timeoutSeconds = timeoutSeconds
  }
}

public struct YoloSetResult: Codable, Sendable, Equatable {
  public let success: Bool
  public let expiresIn: Int?
}

public enum MCPInputSchemaType: String, Codable, Sendable {
  case object
}

public struct MCPInputSchema: Codable, Sendable {
  public let type: MCPInputSchemaType
  public let properties: [String: AnyCodable]
  public let required: [String]?

  public init(
    properties: [String: AnyCodable],
    required: [String]? = nil
  ) {
    type = .object
    self.properties = properties
    self.required = required
  }
}

public struct VscodeMCPToolDescriptor: Codable, Sendable {
  public let name: String
  public let description: String
  public let serverName: String
  public let inputSchema: MCPInputSchema?

  public init(
    name: String,
    description: String,
    serverName: String,
    inputSchema: MCPInputSchema? = nil
  ) {
    self.name = name
    self.description = description
    self.serverName = serverName
    self.inputSchema = inputSchema
  }
}

public struct MCPSetVscodeToolsParameters: Codable, Sendable {
  public let tools: [VscodeMCPToolDescriptor]

  public init(tools: [VscodeMCPToolDescriptor]) {
    self.tools = tools
  }
}

public struct MCPSetVscodeToolsResult: Codable, Sendable, Equatable {
  public let success: Bool
}

public struct MCPInvokeResponseParameters: Codable, Sendable, Equatable {
  public let requestId: String
  public let success: Bool
  public let result: String?
  public let error: String?

  public init(
    requestId: String,
    success: Bool,
    result: String? = nil,
    error: String? = nil
  ) {
    self.requestId = requestId
    self.success = success
    self.result = result
    self.error = error
  }
}

public struct MCPInvokeResponseResult: Codable, Sendable, Equatable {
  public let success: Bool
}

public struct LearnRecommendParameters: Codable, Sendable, Equatable {
  public let deep: Bool?

  public init(deep: Bool? = nil) {
    self.deep = deep
  }
}

public enum LearnAuditStatus: String, Codable, Sendable, CaseIterable {
  case redundant
  case outdated
  case conflicting
}

public struct LearnAuditEntry: Codable, Sendable, Equatable {
  public let skill: String
  public let status: LearnAuditStatus
  public let reason: String
}

public struct LearnRecommendation: Codable, Sendable, Equatable {
  public let slug: String
  public let score: Double
  public let reason: String
}

public struct LearnRecommendResult: Codable, Sendable, Equatable {
  public let success: Bool
  public let projectSummary: String
  public let audit: [LearnAuditEntry]
  public let recommendations: [LearnRecommendation]
  public let gapAnalysis: String?
  public let error: String?
}
