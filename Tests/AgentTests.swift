import Testing
import Foundation
@testable import AgentSDK

@Suite struct AgentTests {

    @Test func agentCreation() {
        let agent = Agent(
            name: "TestAgent",
            instructions: "You are a test agent.",
            tools: [.readFile, .bash],
            maxTurns: 5
        )

        #expect(agent.name == "TestAgent")
        #expect(agent.instructions == "You are a test agent.")
        #expect(agent.tools == [.readFile, .bash])
        #expect(agent.maxTurns == 5)
        #expect(agent.loopType == .react)
    }

    @Test func agentDefaultValues() {
        let agent = Agent(name: "Minimal", instructions: "Be helpful")

        #expect(agent.tools.isEmpty)
        #expect(agent.maxTurns == 10)
        #expect(agent.model == nil)
        #expect(agent.provider == nil)
    }

    @Test func agentWithModelAndProvider() {
        let provider = OpenAIProvider(apiKey: "test-key")
        let agent = Agent(
            name: "GPTAgent",
            instructions: "Use GPT",
            model: ModelID("gpt-4"),
            provider: provider
        )

        #expect(agent.model == ModelID("gpt-4"))
        #expect(agent.provider != nil)
    }

    @Test func agentSetModel() {
        let agent = Agent(name: "Test", instructions: "Test")
        #expect(agent.model == nil)

        agent.setModel(ModelID("gpt-4"))
        #expect(agent.model == ModelID("gpt-4"))
    }

    @Test func agentSetProvider() {
        let agent = Agent(name: "Test", instructions: "Test")
        #expect(agent.provider == nil)

        let provider = OpenAIProvider(apiKey: "test-key")
        agent.setProvider(provider)
        #expect(agent.provider != nil)
    }

    @Test func agentWithLoopType() {
        let agent = Agent(
            name: "Planner",
            instructions: "Plan first",
            loopType: .planAndExecute
        )
        #expect(agent.loopType == .planAndExecute)
    }

    @Test func agentWithCustomInstructions() {
        let agent = Agent(
            name: "Custom",
            instructions: "Base instructions",
            customInstructions: ["Be concise", "Use bullet points"]
        )
        #expect(agent.customInstructions?.count == 2)
    }

    @Test func agentWithCWD() {
        let agent = Agent(
            name: "FS",
            instructions: "Filesystem agent",
            cwd: "/tmp/test"
        )
        #expect(agent.cwd == "/tmp/test")
    }
}
