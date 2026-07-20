/// Runner — executes agents and manages the agent execution loop.
/// Mirrors the TypeScript SDK Runner class.

import Foundation

public final class Runner: @unchecked Sendable {
    private static let loopRegistry = LoopStrategyRegistry()
    private static let configuration = RunnerConfigurationState()

    public static func setHookManager(_ manager: HookManager) {
        configuration.setHookManager(manager)
    }

    public static func getHookManager() -> HookManager {
        configuration.snapshot().hookManager
    }

    public static func setPermissionManager(_ manager: PermissionManager?) {
        configuration.setPermissionManager(manager)
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
        let runnerConfiguration = configuration.snapshot()
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
        try await runnerConfiguration.hookManager.execute(event: .beforeExecution, context: context)

        guard let provider = agent.provider else {
            throw AgentSDKError.agentConfig(message: "Agent has no provider configured")
        }

        guard let model = agent.model else {
            throw AgentSDKError.agentConfig(message: "Agent has no model configured")
        }

        guard let strategy = loopRegistry.getStrategy(agent.loopType) else {
            throw AgentSDKError.agentConfig(message: "Unknown loop type: \(agent.loopType.rawValue)")
        }

        let toolRegistry = DefaultToolRegistry(allowedTools: agent.tools)
        let loopContext = LoopContext(
            agent: agent,
            prompt: prompt,
            provider: provider,
            model: model,
            toolRegistry: toolRegistry,
            options: options,
            permissionManager: runnerConfiguration.permissionManager
        )

        let result = try await strategy.execute(context: loopContext)

        let afterContext = HookContext(
            sessionID: "temp-session",
            cwd: agent.cwd ?? FileManager.default.currentDirectoryPath,
            hookEventName: .afterExecution,
            instruction: prompt,
            tokensUsed: result.turns
        )
        try await runnerConfiguration.hookManager.execute(event: .afterExecution, context: afterContext)

        return result
    }

    // MARK: - Run Stream

    public static func runStream(
        agent: Agent,
        prompt: String,
        options: LoopOptions? = nil
    ) -> AsyncThrowingStream<StreamEvent, Error> {
        let runnerConfiguration = configuration.snapshot()
        return AsyncThrowingStream { continuation in
            let execution = Task {
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

                    let toolRegistry = DefaultToolRegistry(allowedTools: agent.tools)

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
                        options: streamOptions,
                        permissionManager: runnerConfiguration.permissionManager
                    )

                    let result = try await strategy.execute(context: loopContext)
                    continuation.yield(StreamEvent(type: .done))
                    continuation.finish()
                    _ = result
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                execution.cancel()
            }
        }
    }
}

private struct RunnerConfigurationSnapshot: @unchecked Sendable {
    let hookManager: HookManager
    let permissionManager: PermissionManager?
}

private final class RunnerConfigurationState: @unchecked Sendable {
    private let lock = NSLock()
    private var hookManager = HookManager()
    private var permissionManager: PermissionManager?

    func setHookManager(_ manager: HookManager) {
        lock.withLock { hookManager = manager }
    }

    func setPermissionManager(_ manager: PermissionManager?) {
        lock.withLock { permissionManager = manager }
    }

    func snapshot() -> RunnerConfigurationSnapshot {
        lock.withLock {
            RunnerConfigurationSnapshot(
                hookManager: hookManager,
                permissionManager: permissionManager
            )
        }
    }
}
