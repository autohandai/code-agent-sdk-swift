import Testing
import Foundation
@testable import AgentSDK

@Suite(.serialized) struct RunnerTests {

    @Test func runnerRunSyncValidationEmptyInstructions() async {
        let agent = Agent(name: "Test", instructions: "")
        do {
            _ = try await Runner.runSync(agent: agent, prompt: "Hello")
            #expect(Bool(false), "Expected error not thrown")
        } catch let error as AgentSDKError {
            #expect(error.code == "AGENT_CONFIG")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test func runnerRunSyncValidationMaxTurns() async {
        let agent = Agent(name: "Test", instructions: "Be helpful", maxTurns: 0)
        do {
            _ = try await Runner.runSync(agent: agent, prompt: "Hello")
            #expect(Bool(false), "Expected error not thrown")
        } catch let error as AgentSDKError {
            #expect(error.code == "AGENT_CONFIG")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test func runnerRunSyncValidationNoProvider() async {
        let agent = Agent(name: "Test", instructions: "Be helpful")
        do {
            _ = try await Runner.runSync(agent: agent, prompt: "Hello")
            #expect(Bool(false), "Expected error not thrown")
        } catch let error as AgentSDKError {
            #expect(error.code == "AGENT_CONFIG")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test func runnerRunSyncValidationNoModel() async {
        let provider = OpenAIProvider(apiKey: "test-key")
        let agent = Agent(name: "Test", instructions: "Be helpful", provider: provider)
        do {
            _ = try await Runner.runSync(agent: agent, prompt: "Hello")
            #expect(Bool(false), "Expected error not thrown")
        } catch let error as AgentSDKError {
            #expect(error.code == "AGENT_CONFIG")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test func runnerHookManager() {
        let manager = HookManager()
        Runner.setHookManager(manager)
        #expect(Runner.getHookManager() === manager)
    }

    @Test func runnerPermissionManager() {
        let hookManager = HookManager()
        let permManager = PermissionManager(hookManager: hookManager, mode: .yolo)
        Runner.setPermissionManager(permManager)
        #expect(permManager.permissionMode == .yolo)
        Runner.setPermissionManager(nil)
    }

    @Test func runnerExposesOnlyAgentEnabledTools() async throws {
        let provider = RecordingProvider(responses: [
            .init(id: "final", content: "done")
        ])
        let agent = Agent(
            name: "Scoped",
            instructions: "Use only enabled tools",
            tools: [.readFile],
            maxTurns: 1,
            model: "test-model",
            provider: provider
        )

        _ = try await Runner.run(agent: agent, prompt: "Inspect")

        #expect(provider.recordedToolNames == [["read_file"]])
        #expect(provider.recordedMessages.first?.first?.content.contains("write_file") == false)
    }

    @Test func runnerEnforcesPermissionBeforeExecutingTool() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("agent-sdk-permission-\(UUID().uuidString)")
        let marker = directory.appendingPathComponent("should-not-exist")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let provider = RecordingProvider(responses: [
            .init(
                id: "tool",
                content: "",
                toolCalls: [
                    .init(
                        id: "call-1",
                        name: .bash,
                        arguments: #"{"command":"touch \#(marker.path)"}"#
                    )
                ]
            ),
            .init(id: "final", content: "permission handled"),
        ])
        let permissionManager = PermissionManager(hookManager: HookManager(), mode: .deny)
        Runner.setPermissionManager(permissionManager)
        defer { Runner.setPermissionManager(nil) }
        let agent = Agent(
            name: "Safe",
            instructions: "Respect permissions",
            tools: [.bash],
            maxTurns: 2,
            model: "test-model",
            provider: provider
        )

        _ = try await Runner.run(agent: agent, prompt: "Create marker")

        #expect(FileManager.default.fileExists(atPath: marker.path) == false)
        #expect(provider.recordedMessages.last?.contains { message in
            message.role == .tool && message.content.contains("Deny mode enabled")
        } == true)
    }

    @Test func runnerConfigurationSupportsConcurrentUpdatesAndSnapshots() async {
        Runner.setHookManager(HookManager())
        let deny = PermissionManager(hookManager: HookManager(), mode: .deny)
        let allow = PermissionManager(hookManager: HookManager(), mode: .yolo)

        let succeeded = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for index in 0..<40 {
                group.addTask {
                    Runner.setPermissionManager(index.isMultiple(of: 2) ? deny : allow)
                    let provider = RecordingProvider(responses: [
                        .init(id: "final-\(index)", content: "done")
                    ])
                    let agent = Agent(
                        name: "Concurrent \(index)",
                        instructions: "Finish without tools",
                        tools: [],
                        maxTurns: 1,
                        model: "test-model",
                        provider: provider
                    )
                    return (try? await Runner.run(agent: agent, prompt: "Finish")) != nil
                }
            }
            var values: [Bool] = []
            for await value in group { values.append(value) }
            return values
        }

        Runner.setPermissionManager(nil)
        #expect(succeeded.count == 40)
        #expect(succeeded.allSatisfy { $0 })
    }

    @Test func cancellingRunStreamConsumerCancelsProviderExecution() async throws {
        Runner.setPermissionManager(nil)
        let probe = CancellationProbe()
        let provider = SuspendingProvider(probe: probe)
        let agent = Agent(
            name: "Streaming",
            instructions: "Wait for the provider",
            tools: [],
            maxTurns: 1,
            model: "test-model",
            provider: provider
        )
        let stream = Runner.runStream(agent: agent, prompt: "Wait")
        let consumer = Task {
            do {
                for try await _ in stream {}
            } catch is CancellationError {
                // Expected when the consumer is cancelled.
            } catch {
                Issue.record("Unexpected stream error: \(error)")
            }
        }

        await probe.waitUntilStarted()
        consumer.cancel()
        await consumer.value
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { await probe.waitUntilCancelled() }
            group.addTask {
                try await Task.sleep(for: .seconds(1))
                throw RunnerTestError.timeout
            }
            _ = try await group.next()
            group.cancelAll()
        }
    }
}

private final class RecordingProvider: Provider, @unchecked Sendable {
    private let lock = NSLock()
    private var responses: [ChatResponse]
    private var messageStorage: [[Message]] = []
    private var toolNameStorage: [[String]] = []

    init(responses: [ChatResponse]) {
        self.responses = responses
    }

    var recordedMessages: [[Message]] { lock.withLock { messageStorage } }
    var recordedToolNames: [[String]] { lock.withLock { toolNameStorage } }

    func modelName(_ model: String) -> String { model }

    func chat(
        messages: [Message],
        model: String,
        tools: [ToolSchema]?,
        options: ProviderOptions?
    ) async throws -> ChatResponse {
        lock.withLock {
            messageStorage.append(messages)
            toolNameStorage.append((tools ?? []).map(\.name).sorted())
            return responses.isEmpty
                ? .init(id: "fallback", content: "done")
                : responses.removeFirst()
        }
    }

    func chatStream(
        messages: [Message],
        model: String,
        tools: [ToolSchema]?,
        options: ProviderOptions?
    ) -> AsyncThrowingStream<ChatChunk, Error> {
        AsyncThrowingStream { $0.finish() }
    }
}

private enum RunnerTestError: Error {
    case timeout
}

private actor CancellationProbe {
    private var started = false
    private var cancelled = false
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var cancellationWaiters: [CheckedContinuation<Void, Never>] = []

    func markStarted() {
        started = true
        let waiters = startWaiters
        startWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    func markCancelled() {
        cancelled = true
        let waiters = cancellationWaiters
        cancellationWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { startWaiters.append($0) }
    }

    func waitUntilCancelled() async {
        if cancelled { return }
        await withCheckedContinuation { cancellationWaiters.append($0) }
    }
}

private final class SuspendingProvider: Provider, @unchecked Sendable {
    private let probe: CancellationProbe

    init(probe: CancellationProbe) {
        self.probe = probe
    }

    func modelName(_ model: String) -> String { model }

    func chat(
        messages: [Message],
        model: String,
        tools: [ToolSchema]?,
        options: ProviderOptions?
    ) async throws -> ChatResponse {
        await probe.markStarted()
        do {
            try await Task.sleep(for: .seconds(30))
            return .init(id: "unexpected", content: "unexpected")
        } catch {
            await probe.markCancelled()
            throw error
        }
    }

    func chatStream(
        messages: [Message],
        model: String,
        tools: [ToolSchema]?,
        options: ProviderOptions?
    ) -> AsyncThrowingStream<ChatChunk, Error> {
        AsyncThrowingStream { $0.finish() }
    }
}
