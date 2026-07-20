import Foundation

// MARK: - Replayable autoresearch contracts

public enum AutoresearchOptimizationDirection: String, Codable, Sendable {
  case lower
  case higher
}

public enum AutoresearchConstraintOperator: String, Codable, Sendable {
  case lessThan = "<"
  case lessThanOrEqual = "<="
  case greaterThan = ">"
  case greaterThanOrEqual = ">="
}

public enum AutoresearchEvaluatorMode: String, Codable, Sendable {
  case original
  case current
}

public enum AutoresearchMaterializationState: String, Codable, Sendable {
  case baseline
  case committed
  case retained
  case reverted
  case none
}

public struct AutoresearchSubagentOptions: Codable, Sendable {
  public let ideaGeneration: Bool?
  public let measurementAnalysis: Bool?
  public let finalization: Bool?

  public init(
    ideaGeneration: Bool? = nil, measurementAnalysis: Bool? = nil, finalization: Bool? = nil
  ) {
    self.ideaGeneration = ideaGeneration
    self.measurementAnalysis = measurementAnalysis
    self.finalization = finalization
  }
}

public struct AutoresearchSecondaryObjective: Codable, Sendable {
  public let name: String
  public let unit: String
  public let direction: AutoresearchOptimizationDirection

  public init(name: String, unit: String, direction: AutoresearchOptimizationDirection) {
    self.name = name
    self.unit = unit
    self.direction = direction
  }
}

public struct AutoresearchConstraint: Codable, Sendable {
  public let metricName: String
  public let `operator`: AutoresearchConstraintOperator
  public let threshold: Double

  public init(metricName: String, operator: AutoresearchConstraintOperator, threshold: Double) {
    self.metricName = metricName
    self.operator = `operator`
    self.threshold = threshold
  }
}

public struct AutoresearchSamplingOptions: Codable, Sendable {
  public let minSamples: Int?
  public let maxSamples: Int?
  public let confidenceThreshold: Double?

  public init(minSamples: Int? = nil, maxSamples: Int? = nil, confidenceThreshold: Double? = nil) {
    self.minSamples = minSamples
    self.maxSamples = maxSamples
    self.confidenceThreshold = confidenceThreshold
  }
}

public struct AutoresearchRetentionOptions: Codable, Sendable {
  public let maxArtifactBytes: Int64?
  public let maxArtifactAgeDays: Int?

  public init(maxArtifactBytes: Int64? = nil, maxArtifactAgeDays: Int? = nil) {
    self.maxArtifactBytes = maxArtifactBytes
    self.maxArtifactAgeDays = maxArtifactAgeDays
  }
}

public struct AutoresearchStartParameters: Codable, Sendable {
  public let objective: String
  public let maxIterations: Int?
  public let timeoutMs: Int?
  public let metricName: String?
  public let metricUnit: String?
  public let direction: AutoresearchOptimizationDirection?
  public let measureCommand: String?
  public let measureScript: String?
  public let checksCommand: String?
  public let checksScript: String?
  public let filesInScope: [String]?
  public let subagents: AutoresearchSubagentOptions?
  public let secondaryObjectives: [AutoresearchSecondaryObjective]?
  public let constraints: [AutoresearchConstraint]?
  public let sampling: AutoresearchSamplingOptions?
  public let retention: AutoresearchRetentionOptions?
  public let environmentAllowlist: [String]?

  public init(
    objective: String,
    maxIterations: Int? = nil,
    timeoutMs: Int? = nil,
    metricName: String? = nil,
    metricUnit: String? = nil,
    direction: AutoresearchOptimizationDirection? = nil,
    measureCommand: String? = nil,
    measureScript: String? = nil,
    checksCommand: String? = nil,
    checksScript: String? = nil,
    filesInScope: [String]? = nil,
    subagents: AutoresearchSubagentOptions? = nil,
    secondaryObjectives: [AutoresearchSecondaryObjective]? = nil,
    constraints: [AutoresearchConstraint]? = nil,
    sampling: AutoresearchSamplingOptions? = nil,
    retention: AutoresearchRetentionOptions? = nil,
    environmentAllowlist: [String]? = nil
  ) {
    precondition(
      !objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      "Autoresearch objective cannot be empty")
    self.objective = objective
    self.maxIterations = maxIterations
    self.timeoutMs = timeoutMs
    self.metricName = metricName
    self.metricUnit = metricUnit
    self.direction = direction
    self.measureCommand = measureCommand
    self.measureScript = measureScript
    self.checksCommand = checksCommand
    self.checksScript = checksScript
    self.filesInScope = filesInScope
    self.subagents = subagents
    self.secondaryObjectives = secondaryObjectives
    self.constraints = constraints
    self.sampling = sampling
    self.retention = retention
    self.environmentAllowlist = environmentAllowlist
  }
}

public struct AutoresearchMetricAggregate: Codable, Sendable {
  public let median: Double
  public let mad: Double
  public let sampleCount: Int
}

public struct AutoresearchEvaluationSample: Codable, Sendable {
  public let sequence: Int
  public let metrics: [String: Double]
  public let outputObject: String
  public let durationMs: Int
  public let timestamp: String
}

public struct AutoresearchEvaluationChecks: Codable, Sendable {
  public let passed: Bool
  public let outputObject: String?
}

public struct AutoresearchEvaluationExecution: Codable, Sendable {
  public let outcome: String
  public let error: String?
  public let outputObject: String?
}

public struct AutoresearchEvaluationRecord: Codable, Sendable {
  public let schemaVersion: Int
  public let type: String
  public let id: String
  public let attemptId: String
  public let timestamp: String
  public let context: [String: AnyCodable]
  public let evaluatorMode: AutoresearchEvaluatorMode
  public let samples: [AutoresearchEvaluationSample]
  public let aggregates: [String: AutoresearchMetricAggregate]
  public let checks: AutoresearchEvaluationChecks
  public let execution: AutoresearchEvaluationExecution
  public let driftWarnings: [String]
}

public struct AutoresearchConstraintResult: Codable, Sendable {
  public let metricName: String
  public let `operator`: AutoresearchConstraintOperator
  public let threshold: Double
  public let conservativeValue: Double
  public let passed: Bool
  public let conclusive: Bool
}

public struct AutoresearchDecisionRecord: Codable, Sendable {
  public let schemaVersion: Int
  public let type: String
  public let id: String
  public let attemptId: String
  public let timestamp: String
  public let context: [String: AnyCodable]
  public let policyVersion: String
  public let evaluationId: String
  public let source: String
  public let constraintResults: [AutoresearchConstraintResult]
  public let primaryImprovement: Double
  public let confidence: Double
  public let outcome: String
  public let materialized: Bool
  public let explanation: String
}

public struct AutoresearchHistoryAttempt: Codable, Sendable {
  public let attemptId: String
  public let description: String
  public let timestamp: String
  public let legacy: Bool
  public let replayable: Bool
  public let pinned: Bool
  public let latestEvaluation: AutoresearchEvaluationRecord?
  public let latestDecision: AutoresearchDecisionRecord?
  public let materialization: AutoresearchMaterializationState
}

public struct AutoresearchState: Codable, Sendable {
  public let active: Bool
  public let goal: String
  public let iteration: Int
  public let maxIterations: Int
}

public struct AutoresearchStartResult: Codable, Sendable {
  public let success: Bool
  public let message: String?
  public let instruction: String?
  public let active: Bool?
  public let state: AutoresearchState?
  public let statusText: String?
  public let runsLogged: Int?
  public let attempts: [AutoresearchHistoryAttempt]?
  public let paretoAttemptIds: [String]?
  public let error: String?
}

public struct AutoresearchStatusResult: Codable, Sendable {
  public let success: Bool
  public let active: Bool
  public let state: AutoresearchState?
  public let statusText: String
  public let runsLogged: Int
  public let attempts: [AutoresearchHistoryAttempt]?
  public let paretoAttemptIds: [String]?
  public let error: String?
}

public struct AutoresearchStopResult: Codable, Sendable {
  public let success: Bool
  public let message: String?
  public let active: Bool?
  public let state: AutoresearchState?
  public let statusText: String?
  public let runsLogged: Int?
  public let attempts: [AutoresearchHistoryAttempt]?
  public let paretoAttemptIds: [String]?
  public let error: String?
}

public struct AutoresearchHistoryResult: Codable, Sendable {
  public let success: Bool
  public let attempts: [AutoresearchHistoryAttempt]
  public let error: String?
}

public struct AutoresearchReplayParameters: Codable, Sendable {
  public let attemptId: String
  public let evaluator: AutoresearchEvaluatorMode?

  public init(attemptId: String, evaluator: AutoresearchEvaluatorMode? = nil) {
    self.attemptId = attemptId
    self.evaluator = evaluator
  }
}

public struct AutoresearchReplayResult: Codable, Sendable {
  public let success: Bool
  public let attemptId: String?
  public let evaluatorMode: AutoresearchEvaluatorMode?
  public let metrics: [String: Double]?
  public let samples: [AutoresearchEvaluationSample]?
  public let decision: AutoresearchDecisionRecord?
  public let driftWarnings: [String]?
  public let error: String?
}

public struct AutoresearchRescoreParameters: Codable, Sendable {
  public let attemptId: String?
  public let all: Bool?

  private init(attemptId: String?, all: Bool?) {
    self.attemptId = attemptId
    self.all = all
  }

  public static func attempt(_ attemptId: String) -> Self {
    Self(attemptId: attemptId, all: nil)
  }

  public static var allAttempts: Self {
    Self(attemptId: nil, all: true)
  }
}

public struct AutoresearchRescoreResult: Codable, Sendable {
  public let success: Bool
  public let decisions: [AutoresearchDecisionRecord]
  public let error: String?
}

public struct AutoresearchCompareParameters: Codable, Sendable {
  public let leftAttemptId: String
  public let rightAttemptId: String

  public init(leftAttemptId: String, rightAttemptId: String) {
    self.leftAttemptId = leftAttemptId
    self.rightAttemptId = rightAttemptId
  }
}

public struct AutoresearchComparisonSide: Codable, Sendable {
  public let attemptId: String
  public let samples: [AutoresearchEvaluationSample]
  public let aggregates: [String: AutoresearchMetricAggregate]
  public let checks: AutoresearchEvaluationChecks
  public let execution: AutoresearchEvaluationExecution
  public let decision: AutoresearchDecisionRecord?
}

public struct AutoresearchComparison: Codable, Sendable {
  public let left: AutoresearchComparisonSide
  public let right: AutoresearchComparisonSide
}

public struct AutoresearchCompareResult: Codable, Sendable {
  public let success: Bool
  public let comparison: AutoresearchComparison?
  public let error: String?
}

public struct AutoresearchParetoResult: Codable, Sendable {
  public let success: Bool
  public let attemptIds: [String]
  public let error: String?
}

public struct AutoresearchPinParameters: Codable, Sendable {
  public let attemptId: String
  public let pinned: Bool

  public init(attemptId: String, pinned: Bool) {
    self.attemptId = attemptId
    self.pinned = pinned
  }
}

public struct AutoresearchPinResult: Codable, Sendable {
  public let success: Bool
  public let attemptId: String
  public let pinned: Bool
  public let error: String?
}

public struct AutoresearchPruneParameters: Codable, Sendable {
  public let dryRun: Bool?
  public let yes: Bool?

  public init(dryRun: Bool? = nil, yes: Bool? = nil) {
    self.dryRun = dryRun
    self.yes = yes
  }

  public static var preview: Self { Self(dryRun: true) }
  public static var apply: Self { Self(dryRun: false, yes: true) }
}

public struct AutoresearchPruneCandidate: Codable, Sendable {
  public let attemptId: String
  public let objects: [String]
  public let bytes: Int64
  public let isProtected: Bool
  public let reason: String

  enum CodingKeys: String, CodingKey {
    case attemptId, objects, bytes, reason
    case isProtected = "protected"
  }
}

public struct AutoresearchPruneResult: Codable, Sendable {
  public let success: Bool
  public let applied: Bool
  public let candidates: [AutoresearchPruneCandidate]
  public let bytesFreed: Int64
  public let remainingBytes: Int64
  public let error: String?
}

// MARK: - CLI events

public struct AutoresearchLifecycleEvent: Sendable {
  public let phase: String
  public let active: Bool
  public let goal: String?
  public let iteration: Int?
  public let maxIterations: Int?
  public let runsLogged: Int
  public let statusText: String
  public let subcommand: String
  public let message: String?
  public let timestamp: String
}

public struct AutoresearchOperationEvent: Codable, Sendable {
  public let operation: String
  public let phase: String
  public let attemptId: String?
  public let success: Bool
  public let applied: Bool?
  public let error: String?
  public let timestamp: String
}

public enum AutohandCLIEvent: Sendable {
  case turnEnd(AutohandTurnEndEvent)
  case autoresearchLifecycle(AutoresearchLifecycleEvent)
  case autoresearchOperation(AutoresearchOperationEvent)
  case autoModeIteration(AutoModeIterationEvent)
  case notification(method: String, payload: [String: AnyCodable], timestamp: String?)
}

public struct AutohandTurnEndEvent: Codable, Sendable {
  public let turnId: String?
  public let tokensUsed: Int?
  public let tokensUsageStatus: String?
  public let durationMs: Int?
  public let contextPercent: Double?
  public let timestamp: String?
}
