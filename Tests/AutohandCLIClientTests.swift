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
    @Test func discoveryAPIsAreTypedAndUseExactCamelCaseWireKeys() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 5,
        environment: ["AUTOHAND_TEST_REQUEST_LOG": fixture.requestLog.path]
      ))
      try sdk.start()
      defer { sdk.close() }

      let registry = try await sdk.getSkillsRegistry(.init(forceRefresh: true))
      #expect(registry.skills.first?.name == "Release Readiness")
      #expect(registry.categories == [.init(name: "quality", count: 1)])

      let install = try await sdk.installSkill(.init(
        skillName: "release-readiness",
        scope: .project,
        force: true
      ))
      #expect(install.success)
      #expect(install.path == ".autohand/skills/release-readiness")

      let servers = try await sdk.listMCPServers()
      #expect(servers.servers == [.init(name: "filesystem", status: "connected", toolCount: 2)])
      let tools = try await sdk.listMCPTools(.init(serverName: "filesystem"))
      #expect(tools.tools.first?.serverName == "filesystem")
      let configs = try await sdk.getMCPServerConfigs()
      #expect(configs.configs.first?.transport == .stdio)
      #expect(configs.configs.first?.autoConnect == true)

      let requests = try requestObjects(in: fixture.requestLog)
      let byMethod = Dictionary(uniqueKeysWithValues: requests.compactMap { request in
        (request["method"] as? String).map { ($0, request) }
      })
      let registryParams = try #require(
        byMethod["autohand.getSkillsRegistry"]?["params"] as? [String: Any])
      #expect(registryParams["forceRefresh"] as? Bool == true)
      #expect(registryParams["force_refresh"] == nil)
      let installParams = try #require(
        byMethod["autohand.installSkill"]?["params"] as? [String: Any])
      #expect(installParams["skillName"] as? String == "release-readiness")
      #expect(installParams["scope"] as? String == "project")
      #expect(installParams["force"] as? Bool == true)
      #expect(installParams["skill_name"] == nil)
      let toolParams = try #require(
        byMethod["autohand.mcp.listTools"]?["params"] as? [String: Any])
      #expect(toolParams["serverName"] as? String == "filesystem")
      #expect(toolParams["server_name"] == nil)
      #expect(byMethod["autohand.mcp.listServers"] != nil)
      #expect(byMethod["autohand.mcp.getServerConfigs"] != nil)
    }

    @Test func resetUsesExactEmptyParametersAndDecodesSession() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 5,
        environment: ["AUTOHAND_TEST_REQUEST_LOG": fixture.requestLog.path]
      ))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.reset()
      #expect(result.sessionId == "reset-session")

      let request = try #require(requestObjects(in: fixture.requestLog).first {
        $0["method"] as? String == "autohand.reset"
      })
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.isEmpty)
    }

    @Test func browserHandoffCreationUsesExactCamelCaseParameters() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 5,
        environment: ["AUTOHAND_TEST_REQUEST_LOG": fixture.requestLog.path]
      ))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.createBrowserHandoff(.init(
        extensionId: "extension-1",
        installUrl: "https://example.test/install"
      ))
      #expect(result.token == "handoff-token")
      #expect(result.sessionId == "browser-session")
      #expect(result.url == "https://example.test/handoff")

      let request = try #require(requestObjects(in: fixture.requestLog).first {
        $0["method"] as? String == "autohand.browserHandoff.create"
      })
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.count == 2)
      #expect(parameters["extensionId"] as? String == "extension-1")
      #expect(parameters["installUrl"] as? String == "https://example.test/install")
      #expect(parameters["extension_id"] == nil)
      #expect(parameters["install_url"] == nil)
    }

    @Test func browserHandoffAttachmentUsesExactTokenAndDecodesResult() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 5,
        environment: ["AUTOHAND_TEST_REQUEST_LOG": fixture.requestLog.path]
      ))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.attachBrowserHandoff(.init(token: "handoff-token"))
      #expect(result.success)
      #expect(result.sessionId == "browser-session")
      #expect(result.messageCount == 3)

      let request = try #require(requestObjects(in: fixture.requestLog).first {
        $0["method"] as? String == "autohand.browserHandoff.attach"
      })
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.count == 1)
      #expect(parameters["token"] as? String == "handoff-token")
    }

    @Test func latestBrowserHandoffAttachmentUsesExactEmptyParameters() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 5,
        environment: ["AUTOHAND_TEST_REQUEST_LOG": fixture.requestLog.path]
      ))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.attachLatestBrowserHandoff()
      #expect(result.success)
      #expect(result.sessionId == "latest-session")
      #expect(result.messageCount == 5)

      let request = try #require(requestObjects(in: fixture.requestLog).first {
        $0["method"] as? String == "autohand.browserHandoff.attachLatest"
      })
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.isEmpty)
    }

    @Test func autoModeStartUsesExactCamelCaseParametersAndDecodesResult() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 5,
        environment: ["AUTOHAND_TEST_REQUEST_LOG": fixture.requestLog.path]
      ))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.startAutoMode(.init(
        prompt: "Ship the SDK",
        maxIterations: 8,
        completionPromise: "DONE",
        useWorktree: true,
        checkpointInterval: 2,
        maxRuntime: 600,
        maxCost: 4.5
      ))
      #expect(result.success)
      #expect(result.sessionId == "auto-session")

      let request = try #require(requestObjects(in: fixture.requestLog).first {
        $0["method"] as? String == "autohand.automode.start"
      })
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.count == 7)
      #expect(parameters["prompt"] as? String == "Ship the SDK")
      #expect(parameters["maxIterations"] as? Int == 8)
      #expect(parameters["completionPromise"] as? String == "DONE")
      #expect(parameters["useWorktree"] as? Bool == true)
      #expect(parameters["checkpointInterval"] as? Int == 2)
      #expect(parameters["maxRuntime"] as? Int == 600)
      #expect(parameters["maxCost"] as? Double == 4.5)
      #expect(parameters["max_iterations"] == nil)
    }

    @Test func autoModeStatusUsesExactEmptyParametersAndDecodesNestedState() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 5,
        environment: ["AUTOHAND_TEST_REQUEST_LOG": fixture.requestLog.path]
      ))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.autoModeStatus()
      #expect(result.active)
      #expect(!result.paused)
      #expect(result.state?.status == .running)
      #expect(result.state?.currentIteration == 2)
      #expect(result.state?.lastCheckpoint?.commit == "checkpoint-1")

      let request = try #require(requestObjects(in: fixture.requestLog).first {
        $0["method"] as? String == "autohand.automode.status"
      })
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.isEmpty)
    }

    @Test func startupInitializationFailureRollsBackAndCanRetry() throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let client = AutohandCLIClient(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 2,
        features: .init(usageV2: true),
        environment: ["AUTOHAND_FAIL_FEATURE_ONCE_MARKER": fixture.failureMarker.path]
      ))

      #expect(throws: AutohandCLIClientError.self) {
        try client.start()
      }
      #expect(client.isRunning == false)

      try client.start()
      #expect(client.isRunning)
      client.close()
      #expect(client.isRunning == false)
    }

    @Test func cancellingAsyncRequestReturnsPromptly() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let client = AutohandCLIClient(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 10
      ))
      try client.start()
      defer { client.close() }

      let started = Date()
      let task = Task { try await client.prompt("wait forever") }
      try await Task.sleep(for: .milliseconds(50))
      task.cancel()
      do {
        _ = try await task.value
        Issue.record("Expected request cancellation")
      } catch is CancellationError {
        #expect(Date().timeIntervalSince(started) < 0.5)
      } catch {
        Issue.record("Expected CancellationError, got \(error)")
      }

      let servers = try await client.listMCPServers()
      #expect(servers.servers.first?.name == "filesystem")
    }

    @Test func cancellingPromptQueuedBehindAnotherPromptReturnsPromptly() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let client = AutohandCLIClient(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 10
      ))
      try client.start()
      defer { client.close() }

      let blocking = Task { try await client.prompt("hold transport") }
      try await Task.sleep(for: .milliseconds(30))
      let queued = Task { try await client.prompt("queued prompt") }
      try await Task.sleep(for: .milliseconds(30))
      let cancelledAt = Date()
      queued.cancel()

      do {
        _ = try await queued.value
        Issue.record("Expected queued request cancellation")
      } catch is CancellationError {
        #expect(Date().timeIntervalSince(cancelledAt) < 0.5)
      } catch {
        Issue.record("Expected CancellationError, got \(error)")
      }

      blocking.cancel()
      _ = try? await blocking.value

      let commands = try await client.supportedCommands()
      #expect(commands.contains("/autoresearch"))
    }

    @Test func controlRPCCompletesWhilePromptIsInFlight() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let client = AutohandCLIClient(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 5,
        environment: ["AUTOHAND_PROMPT_DELAY": "2"]
      ))
      try client.start()
      defer { client.close() }

      let prompt = Task { try await client.prompt("hold prompt open") }
      try await Task.sleep(for: .milliseconds(50))
      let started = Date()
      let servers = try await client.listMCPServers()

      #expect(servers.servers.first?.name == "filesystem")
      #expect(Date().timeIntervalSince(started) < 1.5)
      prompt.cancel()
      _ = try? await prompt.value
    }

    @Test func concurrentPromptsRemainSerialized() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let client = AutohandCLIClient(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 5
      ))
      try client.start()
      defer { client.close() }

      let started = Date()
      async let first = client.prompt("first prompt")
      async let second = client.prompt("second prompt")
      let results = try await [first, second]

      #expect(results.allSatisfy { $0.success })
      #expect(Date().timeIntervalSince(started) >= 0.3)
    }

    @Test func spontaneousExitCanRestartWithoutOldRouterPoisoningNewProcess() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let client = AutohandCLIClient(configuration: .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 2,
        environment: ["AUTOHAND_EXIT_ONCE_MARKER": fixture.failureMarker.path]
      ))
      try client.start()

      do {
        _ = try await client.listMCPServers()
        Issue.record("Expected the first CLI generation to exit")
      } catch is AutohandCLIClientError {
        // Expected: the first generation exits before replying.
      }
      #expect(client.isRunning == false)

      try client.start()
      let servers = try await client.listMCPServers()
      #expect(servers.servers.first?.name == "filesystem")
      client.close()
    }

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

    private func requestObjects(in file: URL) throws -> [[String: Any]] {
      let contents = try String(contentsOf: file, encoding: .utf8)
      return try contents.split(separator: "\n").map { line in
        try #require(
          JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])
      }
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
    let requestLog: URL
    let failureMarker: URL

    init() throws {
      directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("autohand-swift-sdk-\(UUID().uuidString)")
      executable = directory.appendingPathComponent("autohand-fake")
      requestLog = directory.appendingPathComponent("requests.jsonl")
      failureMarker = directory.appendingPathComponent("feature-failed-once")
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try Data().write(to: requestLog)
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
        if [ -n "$AUTOHAND_TEST_REQUEST_LOG" ]; then
          printf '%s\n' "$line" >> "$AUTOHAND_TEST_REQUEST_LOG"
        fi
        id="$(printf '%s' "$line" | sed -E 's/.*"id"[ ]*:[ ]*([0-9]+).*/\1/')"
        case "$line" in
          *autohand.applyFlagSettings*)
            if [ -n "$AUTOHAND_FAIL_FEATURE_ONCE_MARKER" ] && [ ! -f "$AUTOHAND_FAIL_FEATURE_ONCE_MARKER" ]; then
              : > "$AUTOHAND_FAIL_FEATURE_ONCE_MARKER"
              printf '{"jsonrpc":"2.0","id":%s,"error":{"code":-32000,"message":"feature init failed"}}\n' "$id"
            else
              printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true}}\n' "$id"
            fi ;;
          *autohand.getSkillsRegistry*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"skills":[{"id":"release-readiness","name":"Release Readiness","description":"Audit a release","category":"quality","tags":["release"],"rating":4.9,"downloadCount":42,"isFeatured":true,"isCurated":true}],"categories":[{"name":"quality","count":1}]}}\n' "$id" ;;
          *autohand.installSkill*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"skillName":"release-readiness","path":".autohand/skills/release-readiness"}}\n' "$id" ;;
          *autohand.mcp.listServers*)
            if [ -n "$AUTOHAND_EXIT_ONCE_MARKER" ] && [ ! -f "$AUTOHAND_EXIT_ONCE_MARKER" ]; then
              : > "$AUTOHAND_EXIT_ONCE_MARKER"
              exit 0
            fi
            printf '{"jsonrpc":"2.0","id":%s,"result":{"servers":[{"name":"filesystem","status":"connected","toolCount":2}]}}\n' "$id" ;;
          *autohand.mcp.listTools*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"tools":[{"name":"read_file","description":"Read a file","serverName":"filesystem"}]}}\n' "$id" ;;
          *autohand.mcp.getServerConfigs*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"configs":[{"name":"filesystem","transport":"stdio","command":"node","args":["server.js"],"env":{"MODE":"safe"},"autoConnect":true}]}}\n' "$id" ;;
          *autohand.reset*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"sessionId":"reset-session"}}\n' "$id" ;;
          *autohand.browserHandoff.create*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"token":"handoff-token","sessionId":"browser-session","workspaceRoot":"/workspace","createdAt":"2026-07-20T00:00:00Z","expiresAt":"2026-07-20T00:05:00Z","url":"https://example.test/handoff"}}\n' "$id" ;;
          *autohand.browserHandoff.attachLatest*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"sessionId":"latest-session","workspaceRoot":"/workspace","messageCount":5}}\n' "$id" ;;
          *autohand.browserHandoff.attach*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"sessionId":"browser-session","workspaceRoot":"/workspace","messageCount":3}}\n' "$id" ;;
          *autohand.automode.start*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true,"sessionId":"auto-session"}}\n' "$id" ;;
          *autohand.automode.status*)
            printf '{"jsonrpc":"2.0","id":%s,"result":{"active":true,"paused":false,"state":{"sessionId":"auto-session","status":"running","currentIteration":2,"maxIterations":8,"filesCreated":1,"filesModified":3,"branch":"autohand/auto-session","lastCheckpoint":{"commit":"checkpoint-1","message":"iteration 2","timestamp":"2026-07-20T00:02:00Z"}}}}\n' "$id" ;;
          *autohand.prompt*)
            (sleep "${AUTOHAND_PROMPT_DELAY:-0.2}"; printf '{"jsonrpc":"2.0","id":%s,"result":{"success":true}}\n' "$id") & ;;
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
