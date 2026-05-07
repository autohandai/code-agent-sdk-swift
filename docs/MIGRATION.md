# Migrating from the TypeScript Agent SDK

The Swift AgentSDK mirrors the TypeScript `@autohandai/agent-sdk-typescript` architecture
with Swift-native idioms. This guide maps TypeScript patterns to their Swift equivalents.

## Key Differences

| TypeScript SDK | Swift SDK |
|---|---|
| `Agent` class with `run()` method | `Agent` class + `Runner.run()` static method |
| Promise-based async | Swift concurrency (`async/await`) |
| `Tool` string union type | `ToolName` enum |
| `Message` discriminated union | `Message` enum with associated values |
| `SDKError` class hierarchy | `AgentSDKError` enum |
| `Provider` interface | `Provider` protocol |
| `ToolDefinition` abstract class | `ToolDefinition` protocol |
| `LoopStrategy` interface | `LoopStrategy` protocol |
| Zod validation | Codable + manual validation |
| `Runner` static class | `Runner` class with static methods |

## Replacing Agent.run()

TypeScript:

```typescript
import { Agent, OpenRouterProvider } from '@autohandai/agent-sdk-typescript';

const agent = new Agent('Assistant', 'You are helpful.', tools);
agent.setProvider(new OpenRouterProvider('api-key', 'gpt-4'));

const result = await agent.run('Summarize the API');
console.log(result);
```

Swift:

```swift
import AgentSDK

let provider = OpenAIProvider(apiKey: "sk-...")

let agent = Agent(
    name: "Assistant",
    instructions: "You are a helpful coding assistant.",
    tools: [.readFile, .bash],
    model: ModelID("gpt-4o"),
    provider: provider
)

let result = try await Runner.runSync(
    agent: agent,
    prompt: "Summarize the API"
)
print(result)
```

## Replacing Provider Configuration

TypeScript:

```typescript
import { OpenRouterProvider } from '@autohandai/agent-sdk-typescript/providers';

const provider = new OpenRouterProvider({ apiKey: 'sk-or-...' });
```

Swift:

```swift
// OpenAI
let provider = OpenAIProvider(apiKey: "sk-...")

// OpenRouter (uses OpenAI-compatible API)
let provider = OpenAIProvider(
    apiKey: "sk-or-...",
    baseURL: URL(string: "https://openrouter.ai/api/v1")!
)

// Via factory
let provider = try ProviderFactory.create(
    providerName: "openrouter",
    apiKey: "sk-or-..."
)
```

## Replacing Tool Registration

TypeScript:

```typescript
import { ToolDefinition } from '@autohandai/agent-sdk-typescript';

class MyTool extends ToolDefinition {
    getName() { return 'my_tool'; }
    getDescription() { return 'Does something.'; }
    getParameters() { return { type: 'object', properties: {} }; }
    async executeInternal(params) {
        return { data: 'result' };
    }
}
```

Swift:

```swift
struct MyTool: ToolDefinition {
    let name = "my_tool"
    let description = "Does something."
    let annotations = ToolAnnotations()
    let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([:] as [String: Any]),
    ]

    func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        return .success(data: "result")
    }
}
```

## Replacing Streaming

TypeScript:

```typescript
for await (const event of agent.stream('Hello')) {
    if (event.type === 'content') {
        process.stdout.write(event.data);
    }
}
```

Swift:

```swift
let stream = Runner.runStream(agent: agent, prompt: "Hello")

for try await event in stream {
    if event.type == .content {
        print(event.data ?? "", terminator: "")
    }
}
```

## Replacing Error Handling

TypeScript:

```typescript
try {
    await agent.run('Do something');
} catch (error) {
    if (error instanceof ToolExecutionError) {
        console.error(`Tool ${error.toolName} failed`);
    }
}
```

Swift:

```swift
do {
    let result = try await Runner.runSync(agent: agent, prompt: "Do something")
} catch let error as AgentSDKError {
    switch error {
    case .toolExecution(_, let toolName, _):
        print("Tool \(toolName) failed")
    default:
        print(error.localizedDescription)
    }
}
```

## Replacing Hooks

TypeScript:

```typescript
import { HookManager } from '@autohandai/agent-sdk-typescript';

const hookManager = new HookManager();
hookManager.addHook({
    event: 'before-execution',
    command: 'echo "Starting..."',
});
```

Swift:

```swift
let hookManager = HookManager()
hookManager.addHook(HookDefinition(
    event: .beforeExecution,
    command: "echo 'Starting...'"
))
Runner.setHookManager(hookManager)
```

## Replacing Permissions

TypeScript:

```typescript
import { PermissionManager } from '@autohandai/agent-sdk-typescript';

const permManager = new PermissionManager(hookManager, 'ask');
const result = await permManager.requestPermission({
    tool: 'bash',
    args: { command: 'rm -rf /' },
});
```

Swift:

```swift
let permManager = PermissionManager(hookManager: hookManager, mode: .ask)
let result = await permManager.requestPermission(
    PermissionRequest(tool: .bash, command: "rm -rf /")
)
```

## Type Mapping Reference

| TypeScript | Swift |
|---|---|
| `string & { __brand: 'ToolCallId' }` | `ToolCallID` |
| `string & { __brand: 'SessionId' }` | `SessionID` |
| `string & { __brand: 'ModelId' }` | `ModelID` |
| `(typeof TOOL_NAMES)[number]` | `ToolName` enum |
| `UserMessage \| AssistantMessage \| ...` | `Message` enum |
| `ToolResultSuccess \| ToolResultError` | `ToolResult` enum |
| `RunResultSuccess \| RunResultMaxTurns` | `RunResult` enum |
| `Record<string, unknown>` | `[String: AnyCodable]` |
| `AsyncGenerator<StreamEvent>` | `AsyncThrowingStream<StreamEvent, Error>` |
| `Promise<T>` | `async throws -> T` |

## When to Stay on the TypeScript SDK

- You need the full CLI wrapper with JSON-RPC subprocess management
- You're building Node.js/Bun server applications
- You need the MCP server integration

For native macOS/iOS applications, the Swift SDK provides a lightweight,
in-process alternative with the same agent execution semantics.
