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
