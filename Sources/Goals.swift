import Foundation

// MARK: - Persistent goal contracts

public enum GoalStatus: String, Codable, Sendable {
  case active
  case paused
  case budgetLimited
  case complete
}

public struct GoalState: Codable, Sendable {
  public let goalId: String
  public let objective: String
  public let status: GoalStatus
  public let tokenBudget: Int?
  public let timeBudgetSeconds: Int?
  public let minTokensBeforeWrapUp: Int?
  public let minTimeSecondsBeforeWrapUp: Int?
  public let tokensUsed: Int
  public let timeUsedSeconds: Int
  public let createdAt: Int64
  public let updatedAt: Int64
}

public struct QueuedGoal: Codable, Sendable {
  public let queueId: String
  public let objective: String
  public let tokenBudget: Int?
  public let timeBudgetSeconds: Int?
  public let minTokensBeforeWrapUp: Int?
  public let minTimeSecondsBeforeWrapUp: Int?
  public let source: String
  public let template: String?
  public let templateFlags: [String: String]?
  public let templateArgs: String?
  public let createdAt: Int64
}

public struct CompletedGoal: Codable, Sendable {
  public let goalId: String
  public let objective: String
  public let status: GoalStatus
  public let tokensUsed: Int
  public let timeUsedSeconds: Int
  public let createdAt: Int64
  public let completedAt: Int64
}

public struct GoalSnapshot: Codable, Sendable {
  public let version: Int
  public let goal: GoalState?
  public let queue: [QueuedGoal]
  public let completed: [CompletedGoal]
  public let updatedAt: Int64
}

public struct GoalTelemetry: Codable, Sendable {
  public let timeRemainingSeconds: Int?
  public let tokensRemaining: Int?
  public let completionFloorMet: Bool?
}

public struct GoalMutationResult: Codable, Sendable {
  public let ok: Bool
  public let goal: GoalState?
  public let queue: [QueuedGoal]
  public let telemetry: GoalTelemetry?
  public let message: String?
  public let queued: [QueuedGoal]?
  public let started: QueuedGoal?
  public let completed: CompletedGoal?
  public let completedRun: [CompletedGoal]?
  public let dequeued: QueuedGoal?
  public let removed: QueuedGoal?
}

public struct GoalTemplateMetadata: Codable, Sendable {
  public let name: String
  public let path: String
  public let description: String?
  public let aliases: [String]
  public let allowCommands: Bool
  public let requiredPlaceholders: [String]
  public let requiredFlags: [String]
  public let requiresArgs: Bool
}

public enum GoalFeatureResult<Value: Codable & Sendable>: Codable, Sendable {
  case value(Value)
  case disabled(message: String)

  private struct Disabled: Codable {
    let ok: Bool
    let message: String
  }

  public init(from decoder: Decoder) throws {
    if let disabled = try? Disabled(from: decoder), disabled.ok == false {
      self = .disabled(message: disabled.message)
    } else {
      self = .value(try Value(from: decoder))
    }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .value(let value): try value.encode(to: encoder)
    case .disabled(let message): try Disabled(ok: false, message: message).encode(to: encoder)
    }
  }
}

public typealias GoalSnapshotResult = GoalFeatureResult<GoalSnapshot>
public typealias GoalMutationRPCResult = GoalFeatureResult<GoalMutationResult>
public typealias GoalTemplatesResult = GoalFeatureResult<[GoalTemplateMetadata]>

public struct GoalCreateParameters: Codable, Sendable {
  public let objective: String
  public let tokenBudget: Int?
  public let timeBudgetSeconds: Int?
  public let minTokensBeforeWrapUp: Int?
  public let minTimeSecondsBeforeWrapUp: Int?

  public init(
    objective: String,
    tokenBudget: Int? = nil,
    timeBudgetSeconds: Int? = nil,
    minTokensBeforeWrapUp: Int? = nil,
    minTimeSecondsBeforeWrapUp: Int? = nil
  ) {
    self.objective = objective
    self.tokenBudget = tokenBudget
    self.timeBudgetSeconds = timeBudgetSeconds
    self.minTokensBeforeWrapUp = minTokensBeforeWrapUp
    self.minTimeSecondsBeforeWrapUp = minTimeSecondsBeforeWrapUp
  }

  enum CodingKeys: String, CodingKey {
    case objective
    case tokenBudget = "token_budget"
    case timeBudgetSeconds = "time_budget_seconds"
    case minTokensBeforeWrapUp = "min_tokens_before_wrap_up"
    case minTimeSecondsBeforeWrapUp = "min_time_seconds_before_wrap_up"
  }
}

public enum GoalNullableUpdate<Value: Encodable & Sendable>: Sendable {
  case unchanged
  case set(Value)
  case clear
}

public struct GoalUpdateParameters: Encodable, Sendable {
  public let objective: String?
  public let status: GoalStatus?
  public let tokenBudget: GoalNullableUpdate<Int>
  public let timeBudgetSeconds: GoalNullableUpdate<Int>
  public let minTokensBeforeWrapUp: GoalNullableUpdate<Int>
  public let minTimeSecondsBeforeWrapUp: GoalNullableUpdate<Int>

  public init(
    objective: String? = nil,
    status: GoalStatus? = nil,
    tokenBudget: GoalNullableUpdate<Int> = .unchanged,
    timeBudgetSeconds: GoalNullableUpdate<Int> = .unchanged,
    minTokensBeforeWrapUp: GoalNullableUpdate<Int> = .unchanged,
    minTimeSecondsBeforeWrapUp: GoalNullableUpdate<Int> = .unchanged
  ) {
    self.objective = objective
    self.status = status
    self.tokenBudget = tokenBudget
    self.timeBudgetSeconds = timeBudgetSeconds
    self.minTokensBeforeWrapUp = minTokensBeforeWrapUp
    self.minTimeSecondsBeforeWrapUp = minTimeSecondsBeforeWrapUp
  }

  enum CodingKeys: String, CodingKey {
    case objective, status
    case tokenBudget = "token_budget"
    case timeBudgetSeconds = "time_budget_seconds"
    case minTokensBeforeWrapUp = "min_tokens_before_wrap_up"
    case minTimeSecondsBeforeWrapUp = "min_time_seconds_before_wrap_up"
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(objective, forKey: .objective)
    try container.encodeIfPresent(status, forKey: .status)
    try encode(tokenBudget, to: &container, key: .tokenBudget)
    try encode(timeBudgetSeconds, to: &container, key: .timeBudgetSeconds)
    try encode(minTokensBeforeWrapUp, to: &container, key: .minTokensBeforeWrapUp)
    try encode(minTimeSecondsBeforeWrapUp, to: &container, key: .minTimeSecondsBeforeWrapUp)
  }

  private func encode(
    _ update: GoalNullableUpdate<Int>,
    to container: inout KeyedEncodingContainer<CodingKeys>,
    key: CodingKeys
  ) throws {
    switch update {
    case .unchanged: break
    case .set(let value): try container.encode(value, forKey: key)
    case .clear: try container.encodeNil(forKey: key)
    }
  }
}
