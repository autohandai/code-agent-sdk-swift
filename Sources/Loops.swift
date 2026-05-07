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

    public init(
        agent: Agent,
        prompt: String,
        provider: any Provider,
        model: ModelID,
        toolRegistry: ToolRegistry,
        options: LoopOptions? = nil
    ) {
        self.agent = agent
        self.prompt = prompt
        self.provider = provider
        self.model = model
        self.toolRegistry = toolRegistry
        self.options = options
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
    private let maxDuplicateCount = 2

    public func execute(context: LoopContext) async throws -> RunResult {
        let agent = context.agent
        let provider = context.provider
        let model = context.model.rawValue
        let toolRegistry = context.toolRegistry
        let callbacks = context.options?.callbacks

        let userMessage = Message.user(UserMessage(content: context.prompt))
        var session = Session(
            id: SessionID("sess_\(Int(Date().timeIntervalSince1970 * 1000))_\(Int.random(in: 0..<10000))"),
            messages: [userMessage],
            workingDirectory: agent.cwd ?? FileManager.default.currentDirectoryPath
        )

        var messages = await buildInitialMessages(context: context)
        var recentToolCalls: [String: Int] = [:]

        for turn in 0..<agent.maxTurns {
            await callbacks?.onTurnStart?(turn + 1, agent.maxTurns)

            let schemas = toolRegistry.getSchemas()
            await callbacks?.onRequestStart?(messages.count, schemas.count)

            let response = try await provider.chat(
                messages: messages,
                model: model,
                tools: schemas,
                options: nil
            )

            await callbacks?.onResponse?(
                response.toolCalls != nil && !response.toolCalls!.isEmpty,
                response.content.count
            )

            if let toolCalls = response.toolCalls, !toolCalls.isEmpty {
                let assistantMsg = Message.assistant(AssistantMessage(
                    content: response.content,
                    toolCalls: toolCalls
                ))
                session.messages.append(assistantMsg)
                messages.append(assistantMsg)

                for toolCall in toolCalls {
                    let signature = "\(toolCall.name.rawValue):\(toolCall.arguments)"
                    let count = recentToolCalls[signature] ?? 0
                    if count >= maxDuplicateCount {
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

                    let result: ToolResult
                    do {
                        result = try await toolRegistry.execute(toolCall: toolCall)
                    } catch {
                        result = .failure(error: error.localizedDescription)
                    }

                    await callbacks?.onToolResult?(ToolResultEvent(
                        toolName: toolCall.name.rawValue,
                        id: toolCall.id,
                        data: result.data,
                        error: result.error
                    ))

                    let toolMsg = Message.tool(ToolMessage(
                        content: result.data ?? result.error ?? "",
                        toolCallID: toolCall.id,
                        toolName: toolCall.name
                    ))
                    session.messages.append(toolMsg)
                    messages.append(toolMsg)
                }
            } else {
                let finalMsg = Message.assistant(AssistantMessage(content: response.content))
                session.messages.append(finalMsg)
                await callbacks?.onComplete?(turn + 1, response.content)
                return .success(finalOutput: response.content, session: session, turns: turn + 1)
            }
        }

        return .maxTurnsReached(session: session, turns: agent.maxTurns)
    }

    public func buildInitialMessages(context: LoopContext) async -> [Message] {
        let agent = context.agent
        let toolDefs = context.toolRegistry.getAllTools()
        let toolDescriptions = toolDefs.map { "- \($0.name): \($0.description)" }.joined(separator: "\n")

        let systemPrompt = """
        \(agent.instructions)

        You have access to the following tools:
        \(toolDescriptions)

        When using tools, respond with tool calls in the required format.
        After receiving tool results, analyze them and decide on next steps.
        When you have completed the task, provide a final answer without tool calls.
        """

        return [
            .system(SystemMessage(content: systemPrompt)),
            .user(UserMessage(content: context.prompt)),
        ]
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
        let reactStrategy = ReActStrategy()
        return try await reactStrategy.execute(context: context)
    }

    public func buildInitialMessages(context: LoopContext) async -> [Message] {
        let reactStrategy = ReActStrategy()
        var messages = await reactStrategy.buildInitialMessages(context: context)
        let planningPrompt = """
        Before executing, create a step-by-step plan with at most \(maxPlanningSteps) steps.
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
        let reactStrategy = ReActStrategy()
        return try await reactStrategy.execute(context: context)
    }

    public func buildInitialMessages(context: LoopContext) async -> [Message] {
        let reactStrategy = ReActStrategy()
        var messages = await reactStrategy.buildInitialMessages(context: context)
        let parallelPrompt = """
        When possible, execute up to \(maxParallelCalls) independent tool calls in parallel.
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
        let reactStrategy = ReActStrategy()
        return try await reactStrategy.execute(context: context)
    }

    public func buildInitialMessages(context: LoopContext) async -> [Message] {
        let reactStrategy = ReActStrategy()
        var messages = await reactStrategy.buildInitialMessages(context: context)
        let reflectionPrompt = """
        After completing the task, reflect on your work for up to \(reflectionSteps) rounds.
        If quality is below \(qualityThreshold), revise and improve.
        """
        messages.append(.user(UserMessage(content: reflectionPrompt)))
        return messages
    }
}
