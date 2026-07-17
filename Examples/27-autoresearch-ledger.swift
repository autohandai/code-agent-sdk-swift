import AgentSDK
import Foundation

@main
struct AutoresearchLedgerExample {
  static func main() async throws {
    let environment = ProcessInfo.processInfo.environment
    let client = AutohandCLIClient(
      configuration: .init(
        cwd: environment["AUTOHAND_TARGET_REPO"] ?? FileManager.default.currentDirectoryPath,
        cliPath: environment["AUTOHAND_CLI_PATH"],
        timeout: 600,
        unrestricted: true,
        environment: ["AUTOHAND_AUTORESEARCH_NO_PUSH": "1"]),
      onEvent: { event in
        switch event {
        case .autoresearchLifecycle(let lifecycle):
          print("[autoresearch:\(lifecycle.phase)] \(lifecycle.statusText)")
        case .autoresearchOperation(let operation):
          print("[ledger:\(operation.phase)] \(operation.operation)")
        case .notification:
          break
        }
      })
    try client.start()
    defer { client.close() }

    guard try await client.supportsCommand("/autoresearch") else {
      throw AutohandCLIClientError.invalidResponse(
        "The connected CLI does not support /autoresearch")
    }

    let started = try await client.startAutoresearch(
      .init(
        objective: "Reduce Swift test runtime without regressing release validation",
        maxIterations: 3,
        timeoutMs: 600_000,
        metricName: "test_ms",
        metricUnit: "ms",
        direction: .lower,
        measureScript: "swift test\nprintf 'METRIC test_ms=1\\n'",
        checksCommand: "swift build -c release",
        filesInScope: ["Sources", "Tests", "Package.swift"],
        secondaryObjectives: [
          .init(name: "release_build_ms", unit: "ms", direction: .lower)
        ],
        constraints: [
          .init(metricName: "release_build_ms", operator: .lessThanOrEqual, threshold: 600_000)
        ],
        sampling: .init(minSamples: 3, maxSamples: 9, confidenceThreshold: 2),
        retention: .init(maxArtifactBytes: 500_000_000, maxArtifactAgeDays: 30)))
    guard started.success, let instruction = started.instruction else {
      throw AutohandCLIClientError.invalidResponse(
        started.error ?? "Autoresearch did not return an instruction")
    }

    _ = try await client.prompt(instruction)
    let history = try await client.autoresearchHistory()
    for attempt in history.attempts {
      print(
        "\(attempt.attemptId) replayable=\(attempt.replayable) materialization=\(attempt.materialization.rawValue)"
      )
    }

    if let candidate = history.attempts.first(where: {
      $0.replayable && $0.materialization != .baseline
    }) {
      _ = try await client.replayAutoresearch(
        .init(attemptId: candidate.attemptId, evaluator: .original))
      _ = try await client.rescoreAutoresearch(.attempt(candidate.attemptId))
      _ = try await client.pinAutoresearch(.init(attemptId: candidate.attemptId, pinned: true))
    }

    let pareto = try await client.autoresearchPareto()
    print("Pareto attempts: \(pareto.attemptIds)")
    let preview = try await client.pruneAutoresearch(.preview)
    print("Prune preview candidates: \(preview.candidates.count)")
    if environment["AUTOHAND_CONFIRM_PRUNE"] == "1" {
      _ = try await client.pruneAutoresearch(.apply)
    }

    _ = try await client.stopAutoresearch()
  }
}
