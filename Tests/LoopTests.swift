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
}
