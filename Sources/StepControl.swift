import Foundation

/// A tool call in a completed CLI step.
public struct AgentStepToolCall: Codable, Sendable {
  public let id: String?
  public let tool: String
  public let args: [String: AnyCodable]

  public init(id: String? = nil, tool: String, args: [String: AnyCodable]) {
    self.id = id
    self.tool = tool
    self.args = args
  }

  private enum CodingKeys: String, CodingKey { case id, tool, args }
  public init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.stringIfPresent(.id)
    tool = try values.decode(String.self, forKey: .tool)
    args = try values.decode([String: AnyCodable].self, forKey: .args)
  }
}

/// A persisted tool result from a completed CLI step.
public struct AgentStepToolResult: Codable, Sendable {
  public let tool: String
  public let success: Bool
  public let output: String?
  public let error: String?

  public init(tool: String, success: Bool, output: String? = nil, error: String? = nil) {
    self.tool = tool
    self.success = success
    self.output = output
    self.error = error
  }

  private enum CodingKeys: String, CodingKey { case tool, success, output, error }
  public init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    tool = try values.decode(String.self, forKey: .tool)
    success = try values.decode(Bool.self, forKey: .success)
    output = try values.stringIfPresent(.output)
    error = try values.stringIfPresent(.error)
  }
}

/// An immutable snapshot taken after the CLI persists a tool step.
public struct AgentStep: Codable, Sendable {
  public let stepNumber: Int
  public let thought: String?
  public let toolCalls: [AgentStepToolCall]
  public let toolResults: [AgentStepToolResult]

  private enum CodingKeys: String, CodingKey { case stepNumber, thought, toolCalls, toolResults }
  public init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    stepNumber = try values.decode(Int.self, forKey: .stepNumber)
    guard stepNumber > 0 else {
      throw DecodingError.dataCorruptedError(
        forKey: .stepNumber, in: values, debugDescription: "Expected a positive step number")
    }
    thought = try values.stringIfPresent(.thought)
    toolCalls = try values.decode([AgentStepToolCall].self, forKey: .toolCalls)
    toolResults = try values.decode([AgentStepToolResult].self, forKey: .toolResults)
  }
}

public struct StepEndEvent: Codable, Sendable {
  public let stepId: String
  public let step: AgentStep
  public let timestamp: String
}

public struct StopConditionContext: Sendable {
  public let steps: [AgentStep]
}

/// Conditions run concurrently after each step. Any true result stops the turn.
/// Use cooperative Task cancellation for work that may outlive a decision.
public typealias StopCondition = @Sendable (StopConditionContext) async throws -> Bool

public struct AutohandPromptOptions: Sendable {
  public var stopWhen: [StopCondition]

  public init(stopWhen: [StopCondition] = []) { self.stopWhen = stopWhen }
}

public enum StopConditionError: Error, Sendable {
  case invalidStepCount
  case emptyToolName
}

public func isStepCount(_ count: Int) throws -> StopCondition {
  guard count > 0 else { throw StopConditionError.invalidStepCount }
  return { $0.steps.count >= count }
}

public func hasToolCall(_ name: String) throws -> StopCondition {
  let tool = name.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !tool.isEmpty else { throw StopConditionError.emptyToolName }
  return { $0.steps.last?.toolCalls.contains(where: { $0.tool == tool }) == true }
}

public enum AutohandRunStatus: String, Sendable {
  case completed, stopped, aborted
}

public struct AutohandRunResult: Sendable {
  public let success: Bool
  public let output: String
  public let steps: [AgentStep]
  public let status: AutohandRunStatus
}

private extension KeyedDecodingContainer {
  // An absent optional string is valid; an explicitly null or non-string value is not.
  func stringIfPresent(_ key: Key) throws -> String? {
    contains(key) ? try decode(String.self, forKey: key) : nil
  }
}

/// Unstructured tasks let a completed decision release the turn even when another
/// host predicate ignores cancellation. Only the prompt controller writes RPCs.
final class StepEvaluation: @unchecked Sendable {
  private let lock = NSLock()
  private var remaining: Int
  private var outcome: Result<Bool, any Error>?
  private var tasks: [Task<Void, Never>] = []

  init(conditions: [StopCondition], steps: [AgentStep]) {
    remaining = conditions.count
    let context = StopConditionContext(steps: steps)
    tasks = conditions.map { condition in
      Task.detached { [self] in
        do { complete(.success(try await condition(context))) }
        catch { complete(.failure(error)) }
      }
    }
  }

  var result: Result<Bool, any Error>? { lock.withLock { outcome } }

  func cancel() { tasks.forEach { $0.cancel() } }

  private func complete(_ result: Result<Bool, any Error>) {
    lock.withLock {
      guard outcome == nil else { return }
      remaining -= 1
      switch result {
      case .success(false) where remaining > 0: break
      default: outcome = result
      }
    }
  }
}
