import Testing
import Foundation
@testable import AgentSDK

@Suite struct LoopTests {

    @Test func reactStrategyType() {
        let strategy = ReActStrategy()
        #expect(strategy.loopType == .react)
    }

    @Test func planAndExecuteStrategyType() {
        let strategy = PlanAndExecuteStrategy(maxPlanningSteps: 3)
        #expect(strategy.loopType == .planAndExecute)
    }

    @Test func parallelStrategyType() {
        let strategy = ParallelStrategy(maxParallelCalls: 5)
        #expect(strategy.loopType == .parallel)
    }

    @Test func reflexionStrategyType() {
        let strategy = ReflexionStrategy(reflectionSteps: 2, qualityThreshold: 0.9)
        #expect(strategy.loopType == .reflexion)
    }

    @Test func loopStrategyRegistryDefaults() {
        let registry = LoopStrategyRegistry()
        #expect(registry.getStrategy(.react) != nil)
        #expect(registry.getStrategy(.planAndExecute) != nil)
        #expect(registry.getStrategy(.parallel) != nil)
        #expect(registry.getStrategy(.reflexion) != nil)
    }

    @Test func loopStrategyRegistryAllTypes() {
        let registry = LoopStrategyRegistry()
        let types = registry.allTypes()
        #expect(types.contains(.react))
        #expect(types.contains(.planAndExecute))
        #expect(types.contains(.parallel))
        #expect(types.contains(.reflexion))
    }

    @Test func loopStrategyRegistryCustomRegistration() {
        let registry = LoopStrategyRegistry()
        let customStrategy = ReActStrategy()
        registry.register(.react, strategy: customStrategy)
        #expect(registry.getStrategy(.react) != nil)
    }

    @Test func reactBuildInitialMessages() async {
        let strategy = ReActStrategy()
        let agent = Agent(name: "Test", instructions: "Be helpful", tools: [.readFile])
        let toolRegistry = DefaultToolRegistry()
        let provider = OpenAIProvider(apiKey: "test-key")

        let context = LoopContext(
            agent: agent,
            prompt: "Read a file",
            provider: provider,
            model: ModelID("gpt-4"),
            toolRegistry: toolRegistry
        )

        let messages = await strategy.buildInitialMessages(context: context)
        #expect(messages.count == 2)
        #expect(messages[0].role == .system)
        #expect(messages[1].role == .user)
        #expect(messages[0].content.contains("Be helpful"))
        #expect(messages[0].content.contains("read_file"))
    }

    @Test func executionCallbacksCreation() {
        let callbacks = ExecutionCallbacks(
            onTurnStart: { turn, max in },
            onComplete: { turns, output in }
        )
        #expect(callbacks.onTurnStart != nil)
        #expect(callbacks.onComplete != nil)
        #expect(callbacks.onToolCall == nil)
    }

    @Test func loopOptionsCreation() {
        let options = LoopOptions(
            maxPlanningSteps: 5,
            maxParallelCalls: 3,
            reflectionSteps: 2,
            qualityThreshold: 0.8
        )
        #expect(options.maxPlanningSteps == 5)
        #expect(options.maxParallelCalls == 3)
        #expect(options.reflectionSteps == 2)
        #expect(options.qualityThreshold == 0.8)
    }

    @Test func specializedStrategiesExecuteWithTheirOwnOptionAwarePrompts() async throws {
        let cases: [(LoopType, LoopOptions, String)] = [
            (.planAndExecute, .init(maxPlanningSteps: 2), "at most 2 steps"),
            (.parallel, .init(maxParallelCalls: 4), "up to 4 independent tool calls"),
            (
                .reflexion,
                .init(reflectionSteps: 3, qualityThreshold: 0.95),
                "up to 3 rounds"
            ),
        ]

        for (loopType, options, expectedPrompt) in cases {
            let provider = LoopRecordingProvider()
            let agent = Agent(
                name: "Strategy",
                instructions: "Follow the selected strategy",
                tools: [],
                maxTurns: 1,
                model: "test-model",
                provider: provider,
                loopType: loopType
            )
            let registry = LoopStrategyRegistry()
            let strategy = try #require(registry.getStrategy(loopType))
            let context = LoopContext(
                agent: agent,
                prompt: "Solve this",
                provider: provider,
                model: "test-model",
                toolRegistry: DefaultToolRegistry(allowedTools: []),
                options: options
            )

            _ = try await strategy.execute(context: context)

            let messages = try #require(provider.messages.first)
            #expect(messages.contains { $0.content.contains(expectedPrompt) })
            if loopType == .reflexion {
                #expect(messages.contains { $0.content.contains("0.95") })
            }
        }
    }
}

private final class LoopRecordingProvider: Provider, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [[Message]] = []

    var messages: [[Message]] { lock.withLock { storage } }

    func modelName(_ model: String) -> String { model }

    func chat(
        messages: [Message],
        model: String,
        tools: [ToolSchema]?,
        options: ProviderOptions?
    ) async throws -> ChatResponse {
        lock.withLock { storage.append(messages) }
        return .init(id: "final", content: "done")
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
