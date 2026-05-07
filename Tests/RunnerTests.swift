import Testing
import Foundation
@testable import AgentSDK

@Suite struct RunnerTests {

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
    }
}
