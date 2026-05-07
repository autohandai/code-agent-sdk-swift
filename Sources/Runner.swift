/// Runner — executes agents and manages the agent execution loop.
/// Mirrors the TypeScript SDK Runner class.

import Foundation

public final class Runner: @unchecked Sendable {
    private static let loopRegistry = LoopStrategyRegistry()
    private static nonisolated(unsafe) var hookManager = HookManager()
    private static nonisolated(unsafe) var permissionManager: PermissionManager?

    public static func setHookManager(_ manager: HookManager) {
        hookManager = manager
    }

    public static func getHookManager() -> HookManager {
        return hookManager
    }

    public static func setPermissionManager(_ manager: PermissionManager?) {
        permissionManager = manager
    }

    // MARK: - Run Sync

    public static func runSync(agent: Agent, prompt: String, options: LoopOptions? = nil) async throws -> String {
        let result = try await run(agent: agent, prompt: prompt, options: options)

        switch result {
        case .success(let finalOutput, _, _):
            return finalOutput
        case .maxTurnsReached:
            throw AgentSDKError.executionFailed(
                message: "Agent exceeded maximum turns (\(agent.maxTurns)) without reaching a conclusion"
            )
        }
    }

    // MARK: - Run

    public static func run(agent: Agent, prompt: String, options: LoopOptions? = nil) async throws -> RunResult {
        guard !agent.instructions.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AgentSDKError.agentConfig(message: "Agent instructions cannot be empty")
        }

        guard agent.maxTurns > 0 else {
            throw AgentSDKError.agentConfig(message: "Agent maxTurns must be greater than 0")
        }

        let context = HookContext(
            sessionID: "temp-session",
            cwd: agent.cwd ?? FileManager.default.currentDirectoryPath,
            hookEventName: .beforeExecution,
            instruction: prompt
        )
        try await hookManager.execute(event: .beforeExecution, context: context)

        guard let provider = agent.provider else {
            throw AgentSDKError.agentConfig(message: "Agent has no provider configured")
        }

        guard let model = agent.model else {
            throw AgentSDKError.agentConfig(message: "Agent has no model configured")
        }

        guard let strategy = loopRegistry.getStrategy(agent.loopType) else {
            throw AgentSDKError.agentConfig(message: "Unknown loop type: \(agent.loopType.rawValue)")
        }

        let toolRegistry = DefaultToolRegistry()
        let loopContext = LoopContext(
            agent: agent,
            prompt: prompt,
            provider: provider,
            model: model,
            toolRegistry: toolRegistry,
            options: options
        )

        let result = try await strategy.execute(context: loopContext)

        let afterContext = HookContext(
            sessionID: "temp-session",
            cwd: agent.cwd ?? FileManager.default.currentDirectoryPath,
            hookEventName: .afterExecution,
            instruction: prompt,
            tokensUsed: result.turns
        )
        try await hookManager.execute(event: .afterExecution, context: afterContext)

        return result
    }

    // MARK: - Run Stream

    public static func runStream(
        agent: Agent,
        prompt: String,
        options: LoopOptions? = nil
    ) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard !agent.instructions.trimmingCharacters(in: .whitespaces).isEmpty else {
                        throw AgentSDKError.agentConfig(message: "Agent instructions cannot be empty")
                    }

                    guard agent.maxTurns > 0 else {
                        throw AgentSDKError.agentConfig(message: "Agent maxTurns must be greater than 0")
                    }

                    guard let provider = agent.provider else {
                        throw AgentSDKError.agentConfig(message: "Agent has no provider configured")
                    }

                    guard let model = agent.model else {
                        throw AgentSDKError.agentConfig(message: "Agent has no model configured")
                    }

                    guard let strategy = loopRegistry.getStrategy(agent.loopType) else {
                        throw AgentSDKError.agentConfig(message: "Unknown loop type: \(agent.loopType.rawValue)")
                    }

                    let toolRegistry = DefaultToolRegistry()

                    let streamCallbacks = ExecutionCallbacks(
                        onToolCall: { event in
                            continuation.yield(StreamEvent(
                                type: .toolCall,
                                tool: ToolName(rawValue: event.toolName),
                                toolID: event.id
                            ))
                        },
                        onToolResult: { event in
                            if let error = event.error {
                                continuation.yield(StreamEvent(
                                    type: .toolError,
                                    data: error,
                                    tool: ToolName(rawValue: event.toolName),
                                    toolID: event.id
                                ))
                            } else {
                                continuation.yield(StreamEvent(
                                    type: .toolResult,
                                    data: event.data,
                                    tool: ToolName(rawValue: event.toolName),
                                    toolID: event.id
                                ))
                            }
                        },
                        onComplete: { _, finalOutput in
                            continuation.yield(StreamEvent(type: .content, data: finalOutput))
                        }
                    )

                    let streamOptions = LoopOptions(
                        maxPlanningSteps: options?.maxPlanningSteps,
                        maxParallelCalls: options?.maxParallelCalls,
                        reflectionSteps: options?.reflectionSteps,
                        qualityThreshold: options?.qualityThreshold,
                        callbacks: streamCallbacks
                    )

                    let loopContext = LoopContext(
                        agent: agent,
                        prompt: prompt,
                        provider: provider,
                        model: model,
                        toolRegistry: toolRegistry,
                        options: streamOptions
                    )

                    let result = try await strategy.execute(context: loopContext)
                    continuation.yield(StreamEvent(type: .done))
                    continuation.finish()
                    _ = result
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
