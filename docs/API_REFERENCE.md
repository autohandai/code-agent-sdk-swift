# API Reference

Complete reference for the Swift AgentSDK.

## AutohandSDK (macOS)

`AutohandSDK` is the high-level CLI facade. It owns a public
`AutohandCLIClient`, provides `start()`, `close()`, and `isRunning`, and forwards
typed discovery operations:

```swift
let sdk = AutohandSDK(configuration: .init(cwd: "."))
try sdk.start()
defer { sdk.close() }

let registry: GetSkillsRegistryResult = try await sdk.getSkillsRegistry(
    .init(forceRefresh: true)
)
let installation: InstallSkillResult = try await sdk.installSkill(
    .init(skillName: "release-readiness", scope: .project, force: true)
)
let servers: MCPListServersResult = try await sdk.listMCPServers()
let tools: MCPListToolsResult = try await sdk.listMCPTools(
    .init(serverName: "filesystem")
)
let configs: MCPGetServerConfigsResult = try await sdk.getMCPServerConfigs()
```

The direct-provider `Agent` remains independent of CLI lifecycle. This keeps
existing iOS and provider-backed integrations source-compatible.

## AutohandCLIClient (macOS)

`AutohandCLIClient` owns an Autohand CLI JSON-RPC subprocess. Configure it with
`AutohandCLIConfiguration`, call `start()`, and always call `close()`.

- `prompt(_:)`, `command(_:arguments:)`
- `deepResearch(_:)`, `autoresearch(_:)`
- `supportedCommands()`, `supportsCommand(_:)`
- `goal()`, `createGoal(_:)`, `updateGoal(_:)`, `clearGoal()`
- `queueGoal(_:)`, `startQueuedGoal()`, `goalTemplates()`
- `applyFeatureSettings(_:)`
- `getSkillsRegistry(_:)`, `installSkill(_:)`
- `listMCPServers()`, `listMCPTools(_:)`, `getMCPServerConfigs()`
- `reset()` returns the new CLI conversation session ID.
- `startAutoresearch(_:)`, `autoresearchStatus()`, `stopAutoresearch()`
- `autoresearchHistory()`, `replayAutoresearch(_:)`, `rescoreAutoresearch(_:)`
- `compareAutoresearch(_:)`, `autoresearchPareto()`, `pinAutoresearch(_:)`
- `pruneAutoresearch(_:)`

Autoresearch request/result types are `Codable` and `Sendable`. Lifecycle and
ledger-operation notifications arrive through `AutohandCLIEvent`. Turn-end
notifications decode as `AutohandTurnEndEvent` with token, usage-status,
duration, and context fields.

Persistent-goal inputs use `GoalCreateParameters` and `GoalUpdateParameters`.
`GoalNullableUpdate.unchanged`, `.set(_:)`, and `.clear` distinguish an omitted
budget from an explicitly cleared budget. Goal results use
`GoalFeatureResult.value(_:)` or `.disabled(message:)` so disabled CLI features
remain typed instead of becoming decoding errors.

`AutohandCLIConfiguration` supports the current runtime contract: session
persistence/resume, AGENTS.md behavior, token thresholds, skill sources,
auto-mode/auto-commit, prompt files, provider environment, and startup
`AutohandFeatureFlagSettings`.

### Discovery types

- `GetSkillsRegistryParameters(forceRefresh:)`
- `GetSkillsRegistryResult`, `CommunitySkill`, `SkillsRegistryCategory`
- `InstallSkillParameters(skillName:scope:force:)`, `SkillInstallScope`
- `InstallSkillResult`
- `MCPServerSummary`, `MCPListServersResult`
- `MCPListToolsParameters(serverName:)`, `MCPToolSummary`, `MCPListToolsResult`
- `MCPTransport`, `MCPServerConfigEntry`, `MCPGetServerConfigsResult`

Parameter properties encode as the CLI's exact `forceRefresh`, `skillName`, and
`serverName` JSON keys. Skill scope is restricted to `.user` or `.project`, and
MCP transport is restricted to `.stdio`, `.sse`, or `.http`.

Async requests propagate caller cancellation as `CancellationError`. If a
post-launch feature initialization RPC fails, `start()` closes the child and
restores a retryable stopped state before rethrowing.

## Agent

The core configuration unit for an AI agent.

```swift
public final class Agent: @unchecked Sendable {
    public let name: String
    public let instructions: String
    public let tools: [ToolName]
    public let maxTurns: Int
    public private(set) var model: ModelID?
    public private(set) var provider: (any Provider)?
    public let loopType: LoopType
    public let cwd: String?
    public let memories: String?
    public let customInstructions: [String]?
    public let modelSettings: [String: AnyCodable]?
}
```

### Constructor

```swift
public init(
    name: String,
    instructions: String,
    tools: [ToolName] = [],
    maxTurns: Int = 10,
    model: ModelID? = nil,
    provider: (any Provider)? = nil,
    loopType: LoopType = .react,
    cwd: String? = nil,
    memories: String? = nil,
    customInstructions: [String]? = nil,
    modelSettings: [String: AnyCodable]? = nil
)
```

### Methods

#### setModel(_:)

```swift
public func setModel(_ model: ModelID)
```

Sets the model identifier for the agent.

#### setProvider(_:)

```swift
public func setProvider(_ provider: any Provider)
```

Sets the LLM provider for the agent.

---

## Runner

Executes agents and manages the execution loop.

```swift
public final class Runner: @unchecked Sendable
```

### Static Methods

#### run(agent:prompt:options:)

```swift
public static func run(
    agent: Agent,
    prompt: String,
    options: LoopOptions? = nil
) async throws -> RunResult
```

Runs an agent with the given prompt. Returns the full `RunResult` including session and turn count.

Throws `AgentSDKError.agentConfig` if configuration is invalid.

#### runSync(agent:prompt:options:)

```swift
public static func runSync(
    agent: Agent,
    prompt: String,
    options: LoopOptions? = nil
) async throws -> String
```

Runs an agent and returns the final output string. Throws if max turns are reached.

#### runStream(agent:prompt:options:)

```swift
public static func runStream(
    agent: Agent,
    prompt: String,
    options: LoopOptions? = nil
) -> AsyncThrowingStream<StreamEvent, Error>
```

Runs an agent and yields `StreamEvent` values as they occur.

#### setHookManager(_:)

```swift
public static func setHookManager(_ manager: HookManager)
```

Sets the global hook manager.

#### getHookManager()

```swift
public static func getHookManager() -> HookManager
```

Returns the current hook manager.

#### setPermissionManager(_:)

```swift
public static func setPermissionManager(_ manager: PermissionManager?)
```

Sets the global permission manager.

---

## Provider

Protocol for LLM providers.

```swift
public protocol Provider: Sendable {
    func modelName(_ model: String) -> String

    func chat(
        messages: [Message],
        model: String,
        tools: [ToolSchema]?,
        options: ProviderOptions?
    ) async throws -> ChatResponse

    func chatStream(
        messages: [Message],
        model: String,
        tools: [ToolSchema]?,
        options: ProviderOptions?
    ) -> AsyncThrowingStream<ChatChunk, Error>
}
```

### OpenAIProvider

```swift
public final class OpenAIProvider: Provider {
    public init(apiKey: String, baseURL: URL = URL(string: "https://api.openai.com/v1")!)
}
```

OpenAI-compatible provider. Works with OpenAI, OpenRouter, and any OpenAI-compatible API.

### ProviderFactory

```swift
public enum ProviderFactory {
    public static func create(
        providerName: String,
        apiKey: String,
        baseURL: URL? = nil
    ) throws -> Provider
}
```

Creates a provider by name. Supported: `"openai"`, `"openrouter"`.

### ProviderOptions

```swift
public struct ProviderOptions: Sendable {
    public let timeout: TimeInterval      // Default: 30
    public let maxRetries: Int            // Default: 3
    public let maxTokens: Int?
    public let temperature: Double?
}
```

---

## Tools

### ToolDefinition Protocol

```swift
public protocol ToolDefinition: Sendable {
    var name: String { get }
    var description: String { get }
    var annotations: ToolAnnotations { get }
    var parameters: [String: AnyCodable] { get }

    func execute(params: [String: AnyCodable]) async throws -> ToolResult
}
```

### ToolAnnotations

```swift
public struct ToolAnnotations: Sendable {
    public let readOnlyHint: Bool
    public let destructiveHint: Bool
    public let idempotentHint: Bool
    public let openWorldHint: Bool
}
```

### ToolRegistry

```swift
public class ToolRegistry: @unchecked Sendable {
    public func register(_ tool: ToolDefinition)
    public func execute(toolCall: ToolCall) async throws -> ToolResult
    public func getTool(name: String) -> ToolDefinition?
    public func getAllTools() -> [ToolDefinition]
    public func getSchemas() -> [ToolSchema]
}
```

### DefaultToolRegistry

```swift
public final class DefaultToolRegistry: ToolRegistry
```

Pre-registers all built-in tools: `ReadFileTool`, `WriteFileTool`, `EditFileTool`, `BashTool`, `WebSearchTool`, and 10 Git tools.

`DefaultToolRegistry(allowedTools:)` registers only the named built-ins. `Runner`
uses this initializer with `Agent.tools`; an empty agent list advertises and
executes no tools.

### Built-in Tools

| Tool | Name | Description |
|------|------|-------------|
| `ReadFileTool` | `read_file` | Read file contents |
| `WriteFileTool` | `write_file` | Write content to a file |
| `EditFileTool` | `edit_file` | Exact string replacements in a file |
| `BashTool` | `bash` | Execute shell commands |
| `WebSearchTool` | `web_search` | Search the web via DuckDuckGo |
| `GitStatusTool` | `git_status` | Show working tree status |
| `GitDiffTool` | `git_diff` | Show changes |
| `GitLogTool` | `git_log` | Show commit logs |
| `GitAddTool` | `git_add` | Add files to index |
| `GitCommitTool` | `git_commit` | Record changes |
| `GitPushTool` | `git_push` | Update remote refs |
| `GitPullTool` | `git_pull` | Fetch and integrate |
| `GitBranchTool` | `git_branch` | List branches |
| `GitCheckoutTool` | `git_checkout` | Switch branches |

---

## Loop Strategies

### LoopType

```swift
public enum LoopType: String, Sendable, CaseIterable {
    case react
    case planAndExecute = "plan_and_execute"
    case parallel
    case reflexion
}
```

### LoopStrategy Protocol

```swift
public protocol LoopStrategy: Sendable {
    var loopType: LoopType { get }
    func execute(context: LoopContext) async throws -> RunResult
    func buildInitialMessages(context: LoopContext) async -> [Message]
}
```

### Built-in Strategies

| Strategy | LoopType | Best For |
|----------|----------|----------|
| `ReActStrategy` | `.react` | General-purpose reasoning + acting |
| `PlanAndExecuteStrategy` | `.planAndExecute` | Complex multi-step tasks |
| `ParallelStrategy` | `.parallel` | Independent operations |
| `ReflexionStrategy` | `.reflexion` | Quality-critical tasks |

Each specialized strategy builds and executes its own prompt. Per-run
`LoopOptions` override the strategy defaults for planning steps, parallel-call
guidance, reflection rounds, and quality threshold. These values steer the
model's prompt; the current executor still processes returned tool calls
serially and does not provide deterministic SDK-side parallel scheduling or
quality scoring.

### LoopStrategyRegistry

```swift
public final class LoopStrategyRegistry {
    public func register(_ type: LoopType, strategy: any LoopStrategy)
    public func getStrategy(_ type: LoopType) -> (any LoopStrategy)?
    public func allTypes() -> [LoopType]
}
```

### LoopOptions

```swift
public struct LoopOptions: Sendable {
    public let maxPlanningSteps: Int?
    public let maxParallelCalls: Int?
    public let reflectionSteps: Int?
    public let qualityThreshold: Double?
    public let callbacks: ExecutionCallbacks?
}
```

### ExecutionCallbacks

```swift
public struct ExecutionCallbacks: Sendable {
    public let onTurnStart: (@Sendable (Int, Int) async -> Void)?
    public let onRequestStart: (@Sendable (Int, Int) async -> Void)?
    public let onResponse: (@Sendable (Bool, Int) async -> Void)?
    public let onToolCall: (@Sendable (ToolCallEvent) async -> Void)?
    public let onToolResult: (@Sendable (ToolResultEvent) async -> Void)?
    public let onTurnEnd: (@Sendable (Int, Int) async -> Void)?
    public let onComplete: (@Sendable (Int, String) async -> Void)?
    public let onError: (@Sendable (Error, Int?) async -> Void)?
}
```

---

## Hooks

### HookManager

```swift
public final class HookManager: @unchecked Sendable {
    public init(enabled: Bool = true)

    public var isEnabled: Bool
    public func setEnabled(_ enabled: Bool)

    public func addHook(_ hook: HookDefinition)
    public func removeHook(event: HookEvent, index: Int) -> Bool
    public func getHooks(for event: HookEvent) -> [HookDefinition]
    public func getAllHooks() -> [HookDefinition]
    public func execute(event: HookEvent, context: HookContext) async throws
}
```

### HookEvent

```swift
public enum HookEvent: String, Sendable, CaseIterable {
    case sessionStart, sessionEnd
    case preClear, prePrompt
    case preTool, postTool
    case fileModified
    case stop, postResponse
    case subagentStop
    case permissionRequest
    case notification
    case sessionError
    case automodeStart, automodeIteration, automodeCheckpoint
    case automodePause, automodeResume, automodeCancel
    case automodeComplete, automodeError
    case preLearn, postLearn
    case teamCreated, teammateSpawned, teammateIdle
    case taskAssigned, taskCompleted, teamShutdown
    case reviewStart, reviewEnd, reviewPaused
    case reviewFailed, reviewCompleted
    case modeChange
    case contextCompact, contextOverflow
    case contextWarning, contextCritical
    case beforeExecution, afterExecution
    case onError
}
```

### HookDefinition

```swift
public struct HookDefinition: Sendable {
    public let event: HookEvent
    public let command: String
    public let description: String?
    public let enabled: Bool
    public let timeout: Int          // milliseconds, default: 5000
    public let async: Bool
    public let matcher: String?      // regex pattern
    public let filter: HookFilter?
}
```

### HookContext

```swift
public struct HookContext: Sendable {
    public let sessionID: String
    public let cwd: String
    public let hookEventName: HookEvent
    public let toolName: String?
    public let toolInput: [String: AnyCodable]?
    public let instruction: String?
    public let tokensUsed: Int?
    public let error: String?
    public let errorCode: String?
    // ... additional context fields
}
```

---

## Permissions

### PermissionManager

```swift
public final class PermissionManager: @unchecked Sendable {
    public init(hookManager: HookManager, mode: PermissionMode = .ask)

    public var permissionMode: PermissionMode
    public func setPermissionMode(_ mode: PermissionMode)

    public func requestPermission(_ request: PermissionRequest) async -> PermissionResult
}
```

### PermissionMode

```swift
public enum PermissionMode: String, Sendable, Codable {
    case yolo    // Allow everything
    case ask     // Ask for each tool (default)
    case deny    // Deny everything
}
```

### PermissionDecision

```swift
public enum PermissionDecision: String, Sendable {
    case allow
    case deny
    case ask
    case block
}
```

### PermissionRequest

```swift
public struct PermissionRequest: Sendable {
    public let tool: ToolName
    public let args: [String: AnyCodable]
    public let path: String?
    public let command: String?
}
```

### PermissionResult

```swift
public struct PermissionResult: Sendable {
    public let decision: PermissionDecision
    public let reason: String?
    public let `continue`: Bool
}
```

---

## Core Types

### ToolName

```swift
public enum ToolName: String, Sendable, CaseIterable, Codable {
    case readFile, writeFile, editFile, applyPatch
    case find, glob, searchInFiles
    case bash
    case gitStatus, gitDiff, gitLog, gitCommit, gitAdd
    case gitReset, gitPush, gitPull, gitFetch, gitCheckout
    case gitBranch, gitMerge, gitRebase, gitStash
    case webSearch
    case notebookRead, notebookEdit
    case readPackageManifest, addDependency, removeDependency
    case formatFile, formatDirectory, listFormatters, checkFormatting
    case lintFile, lintDirectory, listLinters
}
```

### Message

```swift
public enum Message: Sendable, Codable {
    case user(UserMessage)
    case assistant(AssistantMessage)
    case system(SystemMessage)
    case tool(ToolMessage)
}
```

### ToolCall

```swift
public struct ToolCall: Sendable, Codable {
    public let id: String
    public let name: ToolName
    public let arguments: String  // JSON string
}
```

### ToolResult

```swift
public enum ToolResult: Sendable {
    case success(data: String, metadata: [String: AnyCodable]? = nil)
    case failure(error: String, metadata: [String: AnyCodable]? = nil)
}
```

### Session

```swift
public struct Session: Sendable, Codable {
    public let id: SessionID
    public var messages: [Message]
    public let workingDirectory: String
    public let createdAt: Date
}
```

### RunResult

```swift
public enum RunResult: Sendable {
    case success(finalOutput: String, session: Session, turns: Int)
    case maxTurnsReached(session: Session, turns: Int)
}
```

### StreamEvent

```swift
public struct StreamEvent: Sendable {
    public let type: StreamEventType  // .content, .toolCall, .toolResult, .toolError, .done
    public let data: String?
    public let tool: ToolName?
    public let toolID: String?
}
```

### ChatResponse

```swift
public struct ChatResponse: Sendable, Codable {
    public let id: String
    public let content: String
    public let toolCalls: [ToolCall]?
    public let finishReason: String?
    public let usage: [String: Int]?
}
```

---

## Errors

### AgentSDKError

```swift
public enum AgentSDKError: Error, LocalizedError, Sendable {
    case timeout(message: String, timeoutMs: Int, context: [String: AnyCodable]?)
    case retryExhausted(message: String, attempts: Int, lastError: Error)
    case validation(message: String, field: String?, value: AnyCodable?)
    case provider(message: String, providerName: String, context: [String: AnyCodable]?)
    case toolExecution(message: String, toolName: String, context: [String: AnyCodable]?)
    case agentConfig(message: String)
    case notFound(message: String, resourceType: String, resourceID: String)
    case executionFailed(message: String, context: [String: AnyCodable]?)
}
```

Properties:
- `code: String` — Error code (TIMEOUT, VALIDATION, PROVIDER_ERROR, etc.)
- `isRetryable: Bool` — Whether the error is safe to retry
- `errorDescription: String?` — Human-readable description

---

## Branded Types

```swift
public struct ToolCallID: Hashable, Sendable, Codable, ExpressibleByStringLiteral
public struct SessionID: Hashable, Sendable, Codable, ExpressibleByStringLiteral
public struct ModelID: Hashable, Sendable, Codable, ExpressibleByStringLiteral
```

Prevent accidental mixing of string identifiers.

---

## AnyCodable

```swift
public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: Any
    public init(_ value: Any)
}
```

Type-erased Codable wrapper for dynamic JSON values in tool parameters and hook contexts.
