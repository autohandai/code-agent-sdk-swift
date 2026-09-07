import Foundation
import Testing

@testable import AgentSDK

#if os(macOS)
  @Suite struct ExtendedRPCFeaturesTests {
    @Test func discoversEffectiveAgents() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      var config = configuration(for: fixture)
      config.environment["AUTOHAND_TEST_AGENTS"] = #"{"agents":[{"id":"reviewer","name":"reviewer","description":"Review changes","tools":["read_file"],"model":"fantail","source":"extension","extensionId":"example.review","extensionVersion":"1.0.0","extensionScope":"project"}]}"#
      let sdk = AutohandSDK(configuration: config)
      try sdk.start()
      defer { sdk.close() }
      let agents = try await sdk.supportedAgents()
      #expect(agents.count == 1)
      let agent = try #require(agents.first)
      #expect(agent.id == "reviewer")
      #expect(agent.tools == ["read_file"])
      #expect(agent.model == "fantail")
      #expect(agent.source == "extension")
      #expect(agent.extensionId == "example.review")
      #expect(agent.extensionVersion == "1.0.0")
      #expect(agent.extensionScope == .project)
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.getSupportedAgents")
      #expect((request["params"] as? [String: Any])?.isEmpty == true)
    }

    @Test(arguments: ["{}", #"{"agents":null}"#, #"{"agents":[{}]}"#,
      #"{"agents":[{"id":"one","name":"one","description":"Agent","tools":[1]}]}"#,
      #"{"agents":[{"id":"one","name":"one","description":"Agent","tools":[],"extensionScope":"invalid"}]}"#])
    func rejectsMalformedAgentDiscovery(result: String) async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      var config = configuration(for: fixture)
      config.environment["AUTOHAND_TEST_AGENTS"] = result
      let sdk = AutohandSDK(configuration: config)
      try sdk.start()
      defer { sdk.close() }
      await #expect(throws: (any Error).self) { try await sdk.supportedAgents() }
    }

    @Test func permissionAcknowledgementUsesExactWireContract() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.acknowledgePermission(.init(requestId: "permission-1"))

      #expect(result.success)
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.permissionAcknowledged")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.count == 1)
      #expect(parameters["requestId"] as? String == "permission-1")
    }

    @Test func directoryAccessResponseUsesExactWireContract() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.respondToDirectoryAccess(.init(requestId: "directory-1", granted: true))

      #expect(result.success)
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.directoryAccessResponse")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.count == 2)
      #expect(parameters["requestId"] as? String == "directory-1")
      #expect(parameters["granted"] as? Bool == true)
    }

    @Test func directoryAccessAcknowledgementUsesExactWireContract() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.acknowledgeDirectoryAccess(.init(requestId: "directory-2"))

      #expect(result.success)
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.directoryAccessAcknowledged")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.count == 1)
      #expect(parameters["requestId"] as? String == "directory-2")
    }

    @Test func multiFileChangeDecisionDecodesNestedResultAndWireContract() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.decideChanges(.init(
        batchId: "batch-1",
        action: .acceptSelected,
        selectedChangeIds: ["change-1", "change-2"]
      ))

      #expect(result.success)
      #expect(result.appliedCount == 2)
      #expect(result.errors?.first?.changeId == "change-3")
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.changesDecision")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters["batchId"] as? String == "batch-1")
      #expect(parameters["action"] as? String == "accept_selected")
      #expect(parameters["selectedChangeIds"] as? [String] == ["change-1", "change-2"])
    }

    @Test func sessionHistoryDecodesPaginationAndTypedEntries() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.sessionHistory(.init(page: 2, pageSize: 10))

      #expect(result.currentPage == 2)
      #expect(result.totalItems == 25)
      #expect(result.sessions.first?.status == .completed)
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.getHistory")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters["page"] as? Int == 2)
      #expect(parameters["pageSize"] as? Int == 10)
    }

    @Test func sessionDetailsDecodesTypedSuccessAndFailureUnion() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.sessionDetails(.init(sessionId: "session-42"))

      guard case .success(let details) = result else {
        Issue.record("Expected successful session details")
        return
      }
      #expect(details.messages.first?.content == "Done")
      #expect(details.messages.first?.toolCalls?.first?.name == "write_file")
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.getSession")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.count == 1)
      #expect(parameters["sessionId"] as? String == "session-42")

      let failure = try JSONDecoder().decode(
        SessionDetailsResult.self,
        from: Data(#"{"success":false,"error":"not found"}"#.utf8)
      )
      guard case .failure(let error) = failure else {
        Issue.record("Expected failed session details")
        return
      }
      #expect(error.error == "not found")
    }

    @Test func sessionAttachmentDecodesTypedMetadata() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.attachSession(.init(sessionId: "session-existing"))

      #expect(result.success)
      #expect(result.sessionId == "session-existing")
      #expect(result.messageCount == 7)
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.session.attach")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters["sessionId"] as? String == "session-existing")
    }

    @Test func timedYoloModeSupportsCanonicalAndCompatibilityWireNames() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let canonical = try await sdk.setYoloMode(.init(pattern: "*", timeoutSeconds: 900))
      let compatibility = try await sdk.setYoloMode(
        .init(pattern: "workspace/**", timeoutSeconds: 60),
        useCompatibilityAlias: true
      )

      #expect(canonical.success)
      #expect(canonical.expiresIn == 900)
      #expect(compatibility.success)
      let requests = try requests(in: fixture)
      #expect(requests[requests.count - 2]["method"] as? String == "autohand.yoloSet")
      #expect(requests.last?["method"] as? String == "autohand.yolo.set")
      let parameters = try #require(requests[requests.count - 2]["params"] as? [String: Any])
      #expect(parameters["pattern"] as? String == "*")
      #expect(parameters["timeoutSeconds"] as? Int == 900)
    }

    @Test func vscodeMCPToolRegistrationSerializesTypedDescriptors() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }
      let schema = MCPInputSchema(
        properties: ["issue": AnyCodable(["type": "string"])],
        required: ["issue"]
      )

      let result = try await sdk.registerVscodeMCPTools(.init(tools: [
        .init(
          name: "open_issue",
          description: "Open an issue",
          serverName: "vscode",
          inputSchema: schema
        )
      ]))

      #expect(result.success)
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.mcp.setVscodeTools")
      let parameters = try #require(request["params"] as? [String: Any])
      let tools = try #require(parameters["tools"] as? [[String: Any]])
      let inputSchema = try #require(tools.first?["inputSchema"] as? [String: Any])
      #expect(inputSchema["type"] as? String == "object")
      #expect(inputSchema["required"] as? [String] == ["issue"])
    }

    @Test func mcpInvocationResponseUsesExactCompletionPayload() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.completeMCPInvocation(.init(
        requestId: "invoke-1",
        success: false,
        error: "tool unavailable"
      ))

      #expect(result.success)
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.mcp.invokeResponse")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters["requestId"] as? String == "invoke-1")
      #expect(parameters["success"] as? Bool == false)
      #expect(parameters["error"] as? String == "tool unavailable")
      #expect(parameters["result"] == nil)
    }

    @Test func projectLearningRecommendationsDecodeAuditAndRanking() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.recommendProjectLearning(.init(deep: true))

      #expect(result.success)
      #expect(result.audit.first?.status == .outdated)
      #expect(result.recommendations.first?.score == 0.97)
      #expect(result.gapAnalysis == "Deep contract gap")
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.learn.recommend")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters["deep"] as? Bool == true)
    }

    @Test func projectLearningUpdatesDecodeTypedResultsAndEmptyParameters() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.updateProjectLearning()

      #expect(result.success)
      #expect(result.updated == 1)
      #expect(result.results.first?.status == .updated)
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.learn.update")
      #expect((request["params"] as? [String: Any])?.isEmpty == true)
    }

    @Test func skillGenerationUsesTypedScopeAndResult() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.generateProjectLearning(.init(scope: .project))

      #expect(result.success)
      #expect(result.skillName == "swift-sdk-learning")
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.learn.generate")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.count == 1)
      #expect(parameters["scope"] as? String == "project")
    }

    @Test func toolsRegistryDecodesTypedEntriesAndDiagnostics() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.toolsRegistry()

      #expect(result.tools.first?.source == .builtin)
      #expect(result.tools.first?.scope == .project)
      #expect(result.diagnostics.first?.reason == "Invalid schema")
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.getToolsRegistry")
      #expect((request["params"] as? [String: Any])?.isEmpty == true)
    }

    @Test func contextCompactionUsesExactRuntimeControlContract() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.setContextCompaction(.init(enabled: true))

      #expect(result.enabled)
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.setContextCompact")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.count == 1)
      #expect(parameters["enabled"] as? Bool == true)
    }

    @Test func autoModeIterationRejectsMalformedAndDeliversTypedEvent() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let events = recorder.events.compactMap { event -> AutoModeIterationEvent? in
        if case .autoModeIteration(let value) = event { return value }
        return nil
      }
      #expect(events.count == 1)
      #expect(events.first?.actions == ["edit", "test"])
      #expect(events.first?.tokensUsed == 1_200)
    }

    @Test func autoModeCompletionRejectsMalformedAndDeliversTypedEvent() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let events = recorder.events.compactMap { event -> AutoModeCompleteEvent? in
        if case .autoModeComplete(let value) = event { return value }
        return nil
      }
      #expect(events.count == 1)
      #expect(events.first?.iterations == 3)
      #expect(events.first?.filesModified == 5)
    }

    @Test func autoModeErrorRejectsMalformedAndDeliversTypedEvent() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let events = recorder.events.compactMap { event -> AutoModeErrorEvent? in
        if case .autoModeError(let value) = event { return value }
        return nil
      }
      #expect(events.count == 1)
      #expect(events.first?.error == "iteration limit reached")
    }

    @Test func preToolHookRejectsMalformedAndDeliversTypedEvent() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let events = recorder.events.compactMap { event -> HookPreToolEvent? in
        if case .hookPreTool(let value) = event { return value }
        return nil
      }
      #expect(events.count == 1)
      #expect(events.first?.toolName == "read_file")
      #expect(events.first?.args["path"]?.value as? String == "README.md")
    }

    @Test func postToolHookRejectsMalformedAndDeliversTypedEvent() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let events = recorder.events.compactMap { event -> HookPostToolEvent? in
        if case .hookPostTool(let value) = event { return value }
        return nil
      }
      #expect(events.count == 1)
      #expect(events.first?.success == true)
      #expect(events.first?.duration == 12.5)
      #expect(events.first?.output == "contents")
    }

    @Test func prePromptHookRejectsMalformedAndDeliversTypedEvent() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let events = recorder.events.compactMap { event -> HookPrePromptEvent? in
        if case .hookPrePrompt(let value) = event { return value }
        return nil
      }
      #expect(events.count == 1)
      #expect(events.first?.instruction == "Summarize the SDK")
      #expect(events.first?.mentionedFiles == ["README.md", "Package.swift"])
    }

    @Test func postResponseHookRejectsMalformedAndDeliversTypedEvent() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let events = recorder.events.compactMap { event -> HookPostResponseEvent? in
        if case .hookPostResponse(let value) = event { return value }
        return nil
      }
      #expect(events.count == 1)
      #expect(events.first?.tokensUsageStatus == .actual)
      #expect(events.first?.toolCallsCount == 1)
      #expect(events.first?.duration == 20.5)
    }

    @Test func remainingHookNotificationsDeliverExactTypedPayloads() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let file = try #require(recorder.events.compactMap { event -> HookFileModifiedEvent? in
        if case .hookFileModified(let value) = event { return value }
        return nil
      }.first)
      #expect(file.changeType == .modify)
      let sessionError = try #require(recorder.events.compactMap { event -> HookSessionErrorEvent? in
        if case .hookSessionError(let value) = event { return value }
        return nil
      }.first)
      #expect(sessionError.context?["retryAfter"]?.value as? Int == 60)
      let stop = try #require(recorder.events.compactMap { event -> HookStopEvent? in
        if case .hookStop(let value) = event { return value }
        return nil
      }.first)
      #expect(stop.tokensUsageStatus == .unavailable)
      #expect(stop.duration == 300.5)
      let start = try #require(recorder.events.compactMap { event -> HookSessionStartEvent? in
        if case .hookSessionStart(let value) = event { return value }
        return nil
      }.first)
      #expect(start.sessionType == .resume)
      let end = try #require(recorder.events.compactMap { event -> HookSessionEndEvent? in
        if case .hookSessionEnd(let value) = event { return value }
        return nil
      }.first)
      #expect(end.reason == .clear)
      let subagent = try #require(recorder.events.compactMap { event -> HookSubagentStopEvent? in
        if case .hookSubagentStop(let value) = event { return value }
        return nil
      }.first)
      #expect(subagent.error == "Review failed")
      let permission = try #require(recorder.events.compactMap { event -> HookPermissionRequestEvent? in
        if case .hookPermissionRequest(let value) = event { return value }
        return nil
      }.first)
      #expect(permission.args?["content"]?.value as? String == "updated")
      let notification = try #require(recorder.events.compactMap { event -> HookNotificationEvent? in
        if case .hookNotification(let value) = event { return value }
        return nil
      }.first)
      #expect(notification.message == "Context is nearly full")
      let compacted = try #require(recorder.events.compactMap { event -> HookContextCompactedEvent? in
        if case .hookContextCompacted(let value) = event { return value }
        return nil
      }.first)
      #expect(compacted.usagePercent == 0.6125)
      #expect(compacted.summary == "Earlier turns summarized")
      let overflow = try #require(recorder.events.compactMap { event -> HookContextOverflowEvent? in
        if case .hookContextOverflow(let value) = event { return value }
        return nil
      }.first)
      #expect(overflow.tokensBefore == 120_000)
      #expect(overflow.usagePercent == 1.05)
      let warning = try #require(recorder.events.compactMap { event -> HookContextWarningEvent? in
        if case .hookContextWarning(let value) = event { return value }
        return nil
      }.first)
      #expect(warning.usagePercent == 0.805)
      let critical = try #require(recorder.events.compactMap { event -> HookContextCriticalEvent? in
        if case .hookContextCritical(let value) = event { return value }
        return nil
      }.first)
      #expect(critical.usagePercent == 0.9575)
    }

    @Test func malformedKnownHooksUseExactMethodNotificationFallback() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let fallbackMethods = Set(recorder.events.compactMap { event -> String? in
        guard case .notification(let method, let payload, _) = event,
          payload["malformedMarker"]?.value as? String == method
        else { return nil }
        return method
      })
      #expect(fallbackMethods == Set([
        "autohand.hook.preTool", "autohand.hook.postTool",
        "autohand.hook.fileModified", "autohand.hook.prePrompt",
        "autohand.hook.postResponse", "autohand.hook.sessionError",
        "autohand.hook.stop", "autohand.hook.sessionStart",
        "autohand.hook.sessionEnd", "autohand.hook.subagentStop",
        "autohand.hook.permissionRequest", "autohand.hook.notification",
        "autohand.hook.contextCompacted", "autohand.hook.contextOverflow",
        "autohand.hook.contextWarning", "autohand.hook.contextCritical",
      ]))
    }

    @Test func nonObjectNotificationParamsPreserveExactTopLevelShape() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let rawEvents: [String: Any] = Dictionary(
        uniqueKeysWithValues: recorder.events.compactMap { event in
          guard case .rawNotification(let method, let params) = event else { return nil }
          return (method, params.value)
        })
      let knownArray = try #require(rawEvents["autohand.hook.preTool"] as? [Any])
      #expect(knownArray[0] as? Int == 1)
      #expect(knownArray[1] as? String == "known-array")
      #expect(rawEvents["autohand.hook.stop"] is NSNull)
      #expect(rawEvents["autohand.hook.notification"] as? String == "known-scalar")
      let futureArray = try #require(rawEvents["autohand.future.array"] as? [Any])
      #expect(futureArray[0] as? Int == 2)
      #expect(futureArray[1] as? String == "future-array")
      #expect(rawEvents["autohand.future.null"] is NSNull)
      #expect(rawEvents["autohand.future.scalar"] as? Int == 42)
    }

    @Test func mcpInvocationRequestRejectsMalformedAndDeliversTypedEvent() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let events = recorder.events.compactMap { event -> MCPInvocationRequestEvent? in
        if case .mcpInvocationRequest(let value) = event { return value }
        return nil
      }
      #expect(events.count == 1)
      #expect(events.first?.toolName == "vscode.openFile")
      #expect(events.first?.args["path"]?.value as? String == "Sources/Agent.swift")
    }

    @Test func mcpToolsChangedRejectsMalformedAndDeliversTypedEvent() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let events = recorder.events.compactMap { event -> MCPToolsChangedEvent? in
        if case .mcpToolsChanged(let value) = event { return value }
        return nil
      }
      #expect(events.count == 1)
      #expect(events.first?.tools.first?.name == "open_file")
      #expect(events.first?.tools.first?.serverName == "vscode")
    }

    @Test func learningProgressRejectsMalformedAndPreservesUnknownFallback() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let recorder = FeatureEventRecorder()
      let sdk = AutohandSDK(
        configuration: configuration(for: fixture),
        onEvent: { recorder.append($0) })
      try sdk.start()
      defer { sdk.close() }

      _ = try await sdk.client.prompt("feature-events")

      let progressEvents = recorder.events.compactMap { event -> LearnProgressEvent? in
        if case .learnProgress(let value) = event { return value }
        return nil
      }
      #expect(progressEvents.count == 1)
      #expect(progressEvents.first?.status == .loadingRegistry)

      let unknownEvents = recorder.events.compactMap { event -> [String: AnyCodable]? in
        if case .notification(let method, let payload, _) = event,
          method == "autohand.future.event"
        {
          return payload
        }
        return nil
      }
      #expect(unknownEvents.count == 1)
      #expect(unknownEvents.first?["value"]?.value as? String == "kept")
    }

    private func configuration(for fixture: FakeCLIFixture) -> AutohandCLIConfiguration {
      .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 5,
        environment: ["AUTOHAND_TEST_REQUEST_LOG": fixture.requestLog.path]
      )
    }

    private func requests(in fixture: FakeCLIFixture) throws -> [[String: Any]] {
      let contents = try String(contentsOf: fixture.requestLog, encoding: .utf8)
      return try contents.split(separator: "\n").map { line in
        try #require(JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])
      }
    }
  }
#endif

#if os(macOS)
  private final class FeatureEventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [AutohandCLIEvent] = []

    var events: [AutohandCLIEvent] { lock.withLock { storage } }
    func append(_ event: AutohandCLIEvent) { lock.withLock { storage.append(event) } }
  }
#endif
