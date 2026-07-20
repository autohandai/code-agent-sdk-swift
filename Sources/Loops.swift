/// Execution loop strategies for agent execution.
/// Mirrors the TypeScript SDK loop system.

import Foundation

// MARK: - Loop Type

public enum LoopType: String, Sendable, CaseIterable {
    case react
    case planAndExecute = "plan_and_execute"
    case parallel
    case reflexion
}

// MARK: - Loop Options

public struct LoopOptions: Sendable {
    public let maxPlanningSteps: Int?
    public let maxParallelCalls: Int?
    public let reflectionSteps: Int?
    public let qualityThreshold: Double?
    public let callbacks: ExecutionCallbacks?

    public init(
        maxPlanningSteps: Int? = nil,
        maxParallelCalls: Int? = nil,
        reflectionSteps: Int? = nil,
        qualityThreshold: Double? = nil,
        callbacks: ExecutionCallbacks? = nil
    ) {
        self.maxPlanningSteps = maxPlanningSteps
        self.maxParallelCalls = maxParallelCalls
        self.reflectionSteps = reflectionSteps
        self.qualityThreshold = qualityThreshold
        self.callbacks = callbacks
    }
}

// MARK: - Execution Callbacks

public struct ExecutionCallbacks: Sendable {
    public let onTurnStart: (@Sendable (Int, Int) async -> Void)?
    public let onRequestStart: (@Sendable (Int, Int) async -> Void)?
    public let onResponse: (@Sendable (Bool, Int) async -> Void)?
    public let onToolCall: (@Sendable (ToolCallEvent) async -> Void)?
    public let onToolResult: (@Sendable (ToolResultEvent) async -> Void)?
    public let onTurnEnd: (@Sendable (Int, Int) async -> Void)?
    public let onComplete: (@Sendable (Int, String) async -> Void)?
    public let onError: (@Sendable (Error, Int?) async -> Void)?

    public init(
        onTurnStart: (@Sendable (Int, Int) async -> Void)? = nil,
        onRequestStart: (@Sendable (Int, Int) async -> Void)? = nil,
        onResponse: (@Sendable (Bool, Int) async -> Void)? = nil,
        onToolCall: (@Sendable (ToolCallEvent) async -> Void)? = nil,
        onToolResult: (@Sendable (ToolResultEvent) async -> Void)? = nil,
        onTurnEnd: (@Sendable (Int, Int) async -> Void)? = nil,
        onComplete: (@Sendable (Int, String) async -> Void)? = nil,
        onError: (@Sendable (Error, Int?) async -> Void)? = nil
    ) {
        self.onTurnStart = onTurnStart
        self.onRequestStart = onRequestStart
        self.onResponse = onResponse
        self.onToolCall = onToolCall
        self.onToolResult = onToolResult
        self.onTurnEnd = onTurnEnd
        self.onComplete = onComplete
        self.onError = onError
    }
}

// MARK: - Tool Events

public struct ToolCallEvent: Sendable {
    public let toolName: String
    public let arguments: String
    public let id: String

    public init(toolName: String, arguments: String, id: String) {
        self.toolName = toolName
        self.arguments = arguments
        self.id = id
    }
}

public struct ToolResultEvent: Sendable {
    public let toolName: String
    public let id: String
    public let data: String?
    public let error: String?

    public init(toolName: String, id: String, data: String? = nil, error: String? = nil) {
        self.toolName = toolName
        self.id = id
        self.data = data
        self.error = error
    }
}

// MARK: - Loop Context

public struct LoopContext: Sendable {
    public let agent: Agent
    public let prompt: String
    public let provider: any Provider
    public let model: ModelID
    public let toolRegistry: ToolRegistry
    public let options: LoopOptions?
    public let permissionManager: PermissionManager?

    public init(
        agent: Agent,
        prompt: String,
        provider: any Provider,
        model: ModelID,
        toolRegistry: ToolRegistry,
        options: LoopOptions? = nil,
        permissionManager: PermissionManager? = nil
    ) {
        self.agent = agent
        self.prompt = prompt
        self.provider = provider
        self.model = model
        self.toolRegistry = toolRegistry
        self.options = options
        self.permissionManager = permissionManager
    }
}

// MARK: - Loop Strategy Protocol

public protocol LoopStrategy: Sendable {
    var loopType: LoopType { get }

    func execute(context: LoopContext) async throws -> RunResult
    func buildInitialMessages(context: LoopContext) async -> [Message]
}

// MARK: - Loop Strategy Registry

public final class LoopStrategyRegistry: @unchecked Sendable {
    private var strategies: [LoopType: any LoopStrategy] = [:]
    private let lock = NSLock()

    public init() {
        register(.react, strategy: ReActStrategy())
        register(.planAndExecute, strategy: PlanAndExecuteStrategy())
        register(.parallel, strategy: ParallelStrategy())
        register(.reflexion, strategy: ReflexionStrategy())
    }

    public func register(_ type: LoopType, strategy: any LoopStrategy) {
        lock.lock()
        defer { lock.unlock() }
        strategies[type] = strategy
    }

    public func getStrategy(_ type: LoopType) -> (any LoopStrategy)? {
        lock.lock()
        defer { lock.unlock() }
        return strategies[type]
    }

    public func allTypes() -> [LoopType] {
        lock.lock()
        defer { lock.unlock() }
        return Array(strategies.keys)
    }
}

// MARK: - ReAct Strategy

public struct ReActStrategy: LoopStrategy {
    public let loopType: LoopType = .react

    public func execute(context: LoopContext) async throws -> RunResult {
        try await executeAgentLoop(
            context: context,
            initialMessages: buildInitialMessages(context: context)
        )
    }

    public func buildInitialMessages(context: LoopContext) async -> [Message] {
        baseMessages(context: context)
    }
}

// MARK: - Plan and Execute Strategy

public struct PlanAndExecuteStrategy: LoopStrategy {
    public let loopType: LoopType = .planAndExecute
    private let maxPlanningSteps: Int

    public init(maxPlanningSteps: Int = 5) {
        self.maxPlanningSteps = maxPlanningSteps
    }

    public func execute(context: LoopContext) async throws -> RunResult {
        try await executeAgentLoop(
            context: context,
            initialMessages: buildInitialMessages(context: context)
        )
    }

    public func buildInitialMessages(context: LoopContext) async -> [Message] {
        var messages = baseMessages(context: context)
        let planningSteps = max(1, context.options?.maxPlanningSteps ?? maxPlanningSteps)
        let planningPrompt = """
        Before executing, create a step-by-step plan with at most \(planningSteps) steps.
        Then execute each step using the available tools.
        """
        messages.append(.user(UserMessage(content: planningPrompt)))
        return messages
    }
}

// MARK: - Parallel Strategy

public struct ParallelStrategy: LoopStrategy {
    public let loopType: LoopType = .parallel
    private let maxParallelCalls: Int

    public init(maxParallelCalls: Int = 3) {
        self.maxParallelCalls = maxParallelCalls
    }

    public func execute(context: LoopContext) async throws -> RunResult {
        try await executeAgentLoop(
            context: context,
            initialMessages: buildInitialMessages(context: context)
        )
    }

    public func buildInitialMessages(context: LoopContext) async -> [Message] {
        var messages = baseMessages(context: context)
        let parallelCalls = max(1, context.options?.maxParallelCalls ?? maxParallelCalls)
        let parallelPrompt = """
        When possible, execute up to \(parallelCalls) independent tool calls in parallel.
        Only parallelize calls that don't depend on each other's results.
        """
        messages.append(.user(UserMessage(content: parallelPrompt)))
        return messages
    }
}

// MARK: - Reflexion Strategy

public struct ReflexionStrategy: LoopStrategy {
    public let loopType: LoopType = .reflexion
    private let reflectionSteps: Int
    private let qualityThreshold: Double

    public init(reflectionSteps: Int = 2, qualityThreshold: Double = 0.8) {
        self.reflectionSteps = reflectionSteps
        self.qualityThreshold = qualityThreshold
    }

    public func execute(context: LoopContext) async throws -> RunResult {
        try await executeAgentLoop(
            context: context,
            initialMessages: buildInitialMessages(context: context)
        )
    }

    public func buildInitialMessages(context: LoopContext) async -> [Message] {
        var messages = baseMessages(context: context)
        let steps = max(1, context.options?.reflectionSteps ?? reflectionSteps)
        let threshold = min(1, max(0, context.options?.qualityThreshold ?? qualityThreshold))
        let reflectionPrompt = """
        After completing the task, reflect on your work for up to \(steps) rounds.
        If quality is below \(threshold), revise and improve.
        """
        messages.append(.user(UserMessage(content: reflectionPrompt)))
        return messages
    }
}

private func baseMessages(context: LoopContext) -> [Message] {
    let toolDescriptions = context.toolRegistry.getAllTools()
        .map { "- \($0.name): \($0.description)" }
        .joined(separator: "\n")
    let availability = toolDescriptions.isEmpty ? "No tools are enabled." : """
        You have access to the following tools:
        \(toolDescriptions)
        """
    let systemPrompt = """
    \(context.agent.instructions)

    \(availability)

    When using tools, respond with tool calls in the required format.
    After receiving tool results, analyze them and decide on next steps.
    When you have completed the task, provide a final answer without tool calls.
    """
    return [
        .system(SystemMessage(content: systemPrompt)),
        .user(UserMessage(content: context.prompt)),
    ]
}

private func executeAgentLoop(
    context: LoopContext,
    initialMessages: [Message]
) async throws -> RunResult {
    let agent = context.agent
    let callbacks = context.options?.callbacks
    let userMessage = Message.user(UserMessage(content: context.prompt))
    var session = Session(
        id: SessionID("sess_\(Int(Date().timeIntervalSince1970 * 1000))_\(Int.random(in: 0..<10000))"),
        messages: [userMessage],
        workingDirectory: agent.cwd ?? FileManager.default.currentDirectoryPath
    )
    var messages = initialMessages
    var recentToolCalls: [String: Int] = [:]

    for turn in 0..<agent.maxTurns {
        try Task.checkCancellation()
        await callbacks?.onTurnStart?(turn + 1, agent.maxTurns)
        let schemas = context.toolRegistry.getSchemas()
        await callbacks?.onRequestStart?(messages.count, schemas.count)
        let response = try await context.provider.chat(
            messages: messages,
            model: context.model.rawValue,
            tools: schemas,
            options: nil
        )
        await callbacks?.onResponse?(
            response.toolCalls?.isEmpty == false,
            response.content.count
        )

        guard let toolCalls = response.toolCalls, !toolCalls.isEmpty else {
            session.messages.append(.assistant(AssistantMessage(content: response.content)))
            await callbacks?.onComplete?(turn + 1, response.content)
            return .success(finalOutput: response.content, session: session, turns: turn + 1)
        }

        let assistantMessage = Message.assistant(AssistantMessage(
            content: response.content,
            toolCalls: toolCalls
        ))
        session.messages.append(assistantMessage)
        messages.append(assistantMessage)

        for toolCall in toolCalls {
            try Task.checkCancellation()
            let signature = "\(toolCall.name.rawValue):\(toolCall.arguments)"
            let count = recentToolCalls[signature] ?? 0
            if count >= 2 {
                let warning = Message.tool(ToolMessage(
                    content: "WARNING: Duplicate tool call detected. Please review previous results.",
                    toolCallID: toolCall.id,
                    toolName: toolCall.name
                ))
                session.messages.append(warning)
                messages.append(warning)
                continue
            }
            recentToolCalls[signature] = count + 1

            await callbacks?.onToolCall?(ToolCallEvent(
                toolName: toolCall.name.rawValue,
                arguments: toolCall.arguments,
                id: toolCall.id
            ))

            let result = await executeTool(toolCall, context: context)
            await callbacks?.onToolResult?(ToolResultEvent(
                toolName: toolCall.name.rawValue,
                id: toolCall.id,
                data: result.data,
                error: result.error
            ))
            let toolMessage = Message.tool(ToolMessage(
                content: result.data ?? result.error ?? "",
                toolCallID: toolCall.id,
                toolName: toolCall.name
            ))
            session.messages.append(toolMessage)
            messages.append(toolMessage)
        }
        await callbacks?.onTurnEnd?(turn + 1, agent.maxTurns)
    }
    return .maxTurnsReached(session: session, turns: agent.maxTurns)
}

private func executeTool(_ toolCall: ToolCall, context: LoopContext) async -> ToolResult {
    if let permissionManager = context.permissionManager {
        let arguments = context.toolRegistry.parameters(for: toolCall)
        let permission = await permissionManager.requestPermission(.init(
            tool: toolCall.name,
            args: arguments,
            path: arguments["file_path"]?.value as? String,
            command: arguments["command"]?.value as? String
        ))
        guard permission.continue else {
            return .failure(
                error: permission.reason ?? "Permission \(permission.decision.rawValue)"
            )
        }
    }
    do {
        return try await context.toolRegistry.execute(toolCall: toolCall)
    } catch {
        return .failure(error: error.localizedDescription)
    }
}
