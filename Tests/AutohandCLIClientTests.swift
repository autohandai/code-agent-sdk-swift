import Foundation
import Testing

@testable import AgentSDK

@Suite struct AutohandCLIClientTests {
  @Test func currentCLIFlagsUseExactArgumentContract() {
    let configuration = AutohandCLIConfiguration(
      cwd: "/workspace",
      model: "fantail",
      bare: true,
      idleLogout: false,
      unrestricted: true,
      autoMode: true,
      autoSkill: true,
      autoCommit: true,
      contextCompact: true,
      fork: "session-123",
      persistSession: true,
      sessionId: "session-456",
      resume: true,
      continueSession: true,
      sessionPath: "./sessions",
      autoSaveInterval: 30,
      agentsMdEnabled: true,
      agentsMdCreate: true,
      agentsMdPath: "./AGENTS.md",
      agentsMdAutoUpdate: true,
      maxTokens: 40_000,
      compressionThreshold: 0.8,
      summarizationThreshold: 0.9,
      skills: ["swift", "release"],
      skillSources: ["team", "local"],
      installMissingSkills: true,
      maxIterations: 5,
      maxRuntime: 10,
      maxCost: 2.5,
      displayLanguage: "en",
      systemPrompt: "Be precise.",
      systemPromptFile: "./SYSTEM.md",
      appendSystemPrompt: "Use Swift.",
      appendSystemPromptFile: "./APPEND.md",
      mcpConfig: "./mcp.json",
      agents: "./agents",
      pluginDirectory: "./plugins",
      temperature: 0.2,
      yolo: "read_*",
      yoloTimeout: 30,
      autohandAIAPIKey: "test-key",
      autohandAIBaseURL: "https://api.autohand.ai/v1",
      autohandAIPlan: "cloud")

    #expect(
      configuration.cliArguments == [
        "--mode", "rpc",
        "--bare",
        "--unrestricted",
        "--auto-mode",
        "--auto-skill",
        "-c",
        "--no-idle-logout",
        "--context-compact",
        "--persist-session",
        "--session-id", "session-456",
        "--resume",
        "--continue",
        "--fork", "session-123",
        "--session-path", "./sessions",
        "--auto-save-interval", "30",
        "--agents-md",
        "--agents-md-create",
        "--agents-md-path", "./AGENTS.md",
        "--agents-md-auto-update",
        "--max-tokens", "40000",
        "--compression-threshold", "0.8",
        "--summarization-threshold", "0.9",
        "--skills", "swift,release",
        "--skill-sources", "team,local",
        "--install-missing-skills",
        "--max-iterations", "5",
        "--max-runtime", "10",
        "--max-cost", "2.5",
        "--display-language", "en",
        "--model", "fantail",
        "--sys-prompt", "Be precise.",
        "--system-prompt-file", "./SYSTEM.md",
        "--append-sys-prompt", "Use Swift.",
        "--append-system-prompt-file", "./APPEND.md",
        "--mcp-config", "./mcp.json",
        "--agents", "./agents",
        "--plugin-dir", "./plugins",
        "--temperature", "0.2",
        "--yolo", "read_*",
        "--yolo-timeout", "30",
      ])
    #expect(configuration.cliEnvironment["AUTOHAND_AI_API_KEY"] == "test-key")
    #expect(configuration.cliEnvironment["AUTOHAND_AI_BASE_URL"] == "https://api.autohand.ai/v1")
    #expect(configuration.cliEnvironment["AUTOHAND_AI_PLAN"] == "cloud")
  }

  @Test func goalUpdatesPreserveOmittedSetAndClearStates() throws {
    let create = GoalCreateParameters(objective: "Ship Swift parity", tokenBudget: 10_000)
    let createObject = try #require(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(create)) as? [String: Any])
    #expect(createObject["token_budget"] as? Int == 10_000)
    #expect(createObject["tokenBudget"] == nil)

    let update = GoalUpdateParameters(
      status: .paused,
      tokenBudget: .clear,
      timeBudgetSeconds: .set(600))
    let updateObject = try #require(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(update)) as? [String: Any])
    #expect(updateObject["status"] as? String == "paused")
    #expect(updateObject["token_budget"] is NSNull)
    #expect(updateObject["time_budget_seconds"] as? Int == 600)
    #expect(updateObject["min_tokens_before_wrap_up"] == nil)

    let disabled = try JSONDecoder().decode(
      GoalSnapshotResult.self,
      from: Data(#"{"ok":false,"message":"slashGoal disabled"}"#.utf8))
    if case .disabled(let message) = disabled {
      #expect(message == "slashGoal disabled")
    } else {
      Issue.record("Expected a typed disabled-feature result")
    }
  }

  @Test func autoresearchRequestTypesEncodeCLIValues() throws {
    let parameters = AutoresearchStartParameters(
      objective: "Reduce tests",
      maxIterations: 3,
      metricName: "test_ms",
      metricUnit: "ms",
      direction: .lower,
      constraints: [
        .init(metricName: "build_ms", operator: .lessThanOrEqual, threshold: 600_000)
      ],
      sampling: .init(minSamples: 3, maxSamples: 9, confidenceThreshold: 2))
    let object = try #require(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(parameters)) as? [String: Any])
    #expect(object["direction"] as? String == "lower")
    let constraints = try #require(object["constraints"] as? [[String: Any]])
    #expect(constraints[0]["operator"] as? String == "<=")
  }

  #if os(macOS)
    @Test func typedLifecycleAndLedgerMethodsUseRealSubprocessTransport() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = CLIEventRecorder()
      let client = AutohandCLIClient(
        configuration: .init(
          cwd: fixture.directory.path,
          cliPath: fixture.executable.path,
          timeout: 5,
          features: .init(usageV2: true, slashGoal: true, tokenUsageStatus: true)),
        onEvent: { recorder.append($0) })
      try client.start()
      defer { client.close() }

      #expect(try await client.supportsCommand("/autoresearch"))
      if case .value(let snapshot) = try await client.goal() {
        #expect(snapshot.version == 1)
      } else {
        Issue.record("Expected enabled persistent goals")
      }
      #expect(try await mutationOK(client.createGoal(.init(objective: "Ship parity"))))
      #expect(try await mutationOK(client.updateGoal(.init(status: .paused, tokenBudget: .clear))))
      #expect(try await mutationOK(client.clearGoal()))
      #expect(try await mutationOK(client.queueGoal(.init(objective: "Next goal"))))
      #expect(try await mutationOK(client.startQueuedGoal()))
      if case .value(let templates) = try await client.goalTemplates() {
        #expect(templates.first?.name == "release")
      } else {
        Issue.record("Expected enabled goal templates")
      }
      let started = try await client.startAutoresearch(
        .init(
          objective: "Reduce test runtime",
          maxIterations: 3,
          metricName: "test_ms",
          metricUnit: "ms",
          direction: .lower,
          measureCommand: "swift test"))
      #expect(started.success)
      #expect(started.instruction == "Run the next experiment")
      #expect(try await client.autoresearchStatus().runsLogged == 1)

      let history = try await client.autoresearchHistory()
      #expect(history.attempts.first?.attemptId == "attempt-1")
      #expect(
        try await client.replayAutoresearch(
          .init(
            attemptId: "attempt-1", evaluator: .original)
        ).metrics?["test_ms"] == 120)
      #expect(try await client.rescoreAutoresearch(.attempt("attempt-1")).success)
      #expect(
        try await client.compareAutoresearch(
          .init(
            leftAttemptId: "attempt-1", rightAttemptId: "attempt-0")
        ).success)
      #expect(try await client.autoresearchPareto().attemptIds == ["attempt-1"])
      #expect(try await client.pinAutoresearch(.init(attemptId: "attempt-1", pinned: true)).pinned)
      #expect(try await client.pruneAutoresearch(.preview).remainingBytes == 512)
      #expect(try await client.stopAutoresearch().active == false)

      #expect(
        recorder.events.contains { event in
          if case .turnEnd(let usage) = event {
            return usage.tokensUsed == 42 && usage.tokensUsageStatus == "actual"
          }
          return false
        })
      #expect(
        recorder.events.contains { event in
          if case .autoresearchLifecycle(let lifecycle) = event {
            return lifecycle.phase == "start"
          }
          return false
        })
      #expect(
        recorder.events.contains { event in
          if case .autoresearchOperation(let operation) = event {
            return operation.operation == "history"
          }
          return false
        })
    }

    private func mutationOK(_ operation: GoalMutationRPCResult) -> Bool {
      if case .value(let result) = operation { return result.ok }
      return false
    }
  #endif
}

#if os(macOS)
  private final class CLIEventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [AutohandCLIEvent] = []

    var events: [AutohandCLIEvent] { lock.withLock { storage } }
    func append(_ event: AutohandCLIEvent) { lock.withLock { storage.append(event) } }
  }

  private struct FakeCLIFixture {
    let directory: URL
    let executable: URL

    init() throws {
      directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("autohand-swift-sdk-\(UUID().uuidString)")
      executable = directory.appendingPathComponent("autohand-fake")
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try Self.script.write(to: executable, atomically: true, encoding: .utf8)
      try FileManager.default.setAttributes(
        [.posixPermissions: 0o755], ofItemAtPath: executable.path)
    }

    func remove() {
      try? FileManager.default.removeItem(at: directory)
    }

    private static let script = #"""
      #!/bin/sh
      while IFS= read -r line; do
        id="$(printf '%s' "$line" | sed -E 's/.*"id"[ ]*:[ ]*([0-9]+).*/\1/')"
        case "$line" in
          *autohand.applyFlagSettings*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true}}\n' "$id" ;;
          *autohand.getSupportedCommands*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"commands":["help","deep-research","autoresearch"]}}\n' "$id" ;;
          *autohand.goal.get*)
            printf '{"jsonrpc":"2.0","method":"autohand.turnEnd","params":{"turnId":"turn-1","tokensUsed":42,"tokensUsageStatus":"actual","durationMs":125,"contextPercent":12.5,"timestamp":"2026-07-17T00:00:00Z"}}\n'
            printf '{"jsonrpc":"2.0","id":%s,"result":{"version":1,"goal":null,"queue":[],"completed":[],"updatedAt":1784246400}}\n' "$id" ;;
          *autohand.goal.listTemplates*)
            printf '{"jsonrpc":"2.0","id":%s,"result":[{"name":"release","path":"goals/release.md","aliases":[],"allowCommands":false,"requiredPlaceholders":[],"requiredFlags":[],"requiresArgs":false}]}\n' "$id" ;;
          *autohand.goal.create*|*autohand.goal.update*|*autohand.goal.clear*|*autohand.goal.queue*|*autohand.goal.startQueued*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"ok":true,"goal":null,"queue":[]}}\n' "$id" ;;
          *autohand.autoresearch.start*)
            printf '{"jsonrpc":"2.0","method":"autohand.autoresearch.start","params":{"active":true,"goal":"Reduce test runtime","iteration":0,"maxIterations":3,"runsLogged":0,"statusText":"Autoresearch active","subcommand":"start","timestamp":"2026-07-17T00:00:00Z"}}\n'
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"instruction":"Run the next experiment","active":true,"statusText":"Autoresearch active","runsLogged":0}}\n' "$id" ;;
          *autohand.autoresearch.status*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"active":true,"statusText":"Autoresearch active","runsLogged":1,"paretoAttemptIds":["attempt-1"]}}\n' "$id" ;;
          *autohand.autoresearch.stop*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"active":false,"statusText":"Autoresearch paused","runsLogged":1}}\n' "$id" ;;
          *autohand.autoresearch.history*)
            printf '{"jsonrpc":"2.0","method":"autohand.autoresearch.event","params":{"operation":"history","phase":"completed","success":true,"timestamp":"2026-07-17T00:00:01Z"}}\n'
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"attempts":[{"attemptId":"attempt-1","description":"Baseline","timestamp":"2026-07-17T00:00:00Z","legacy":false,"replayable":true,"pinned":false,"materialization":"baseline"}]}}\n' "$id" ;;
          *autohand.autoresearch.replay*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"attemptId":"attempt-1","evaluatorMode":"original","metrics":{"test_ms":120},"samples":[],"driftWarnings":[]}}\n' "$id" ;;
          *autohand.autoresearch.rescore*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"decisions":[]}}\n' "$id" ;;
          *autohand.autoresearch.compare*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true}}\n' "$id" ;;
          *autohand.autoresearch.pareto*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"attemptIds":["attempt-1"]}}\n' "$id" ;;
          *autohand.autoresearch.pin*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"attemptId":"attempt-1","pinned":true}}\n' "$id" ;;
          *autohand.autoresearch.prune*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"applied":false,"candidates":[{"attemptId":"attempt-2","objects":["patch.diff"],"bytes":512,"protected":false,"reason":"retention"}],"bytesFreed":0,"remainingBytes":512}}\n' "$id" ;;
          *)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true}}\n' "$id" ;;
        esac
      done
      """#
  }
#endif
