# Getting Started with AgentSDK for Swift

This guide walks through installing the Swift AgentSDK, configuring a provider,
and running your first agent.

## Prerequisites

- macOS 14+ or iOS 17+
- Swift 6.0+
- An API key from your AI provider (OpenAI, OpenRouter, etc.)

## 1. Add the Package

Add AgentSDK to your `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyAgentApp",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../AgentSDK"),
    ],
    targets: [
        .executableTarget(
            name: "MyAgentApp",
            dependencies: ["AgentSDK"]
        ),
    ]
)
```

Or add via Xcode: File → Add Package Dependencies → local path to AgentSDK.

## 2. Your First Agent

Create `main.swift`:

```swift
import AgentSDK
import Foundation

let provider = OpenAIProvider(apiKey: "sk-...")

let agent = Agent(
    name: "Assistant",
    instructions: "You are a helpful coding assistant.",
    tools: [.readFile, .writeFile, .bash],
    maxTurns: 10,
    model: ModelID("gpt-4o"),
    provider: provider
)

let result = try await Runner.runSync(
    agent: agent,
    prompt: "Write a hello world program in Swift"
)

print(result)
```

Run it:

```bash
swift run
```

## 3. Streaming Events

For real-time output, use `runStream()`:

```swift
import AgentSDK
import Foundation

let provider = OpenAIProvider(apiKey: "sk-...")

let agent = Agent(
    name: "Assistant",
    instructions: "You are a helpful coding assistant.",
    tools: [.readFile, .bash],
    model: ModelID("gpt-4o"),
    provider: provider
)

let stream = Runner.runStream(
    agent: agent,
    prompt: "What files are in the current directory?"
)

for try await event in stream {
    switch event.type {
    case .content:
        if let data = event.data {
            print(data, terminator: "")
        }
    case .toolCall:
        print("\n[Tool: \(event.tool?.rawValue ?? "unknown")]")
    case .toolResult:
        print("[Tool result: \(event.data?.prefix(100) ?? "")]")
    case .toolError:
        print("[Tool error: \(event.data ?? "")]")
    case .done:
        print("\n[Done]")
    }
}
```

## 4. Working with Files

```swift
let agent = Agent(
    name: "Reviewer",
    instructions: "You review code for correctness and style.",
    tools: [.readFile, .editFile],
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: "/path/to/project"
)

let result = try await Runner.runSync(
    agent: agent,
    prompt: "Review Sources/Types.swift for issues"
)
```

## 5. Handling Permissions

```swift
let hookManager = HookManager()
let permManager = PermissionManager(
    hookManager: hookManager,
    mode: .ask
)

Runner.setPermissionManager(permManager)

let agent = Agent(
    name: "SafeAgent",
    instructions: "Be careful with destructive operations.",
    tools: [.readFile, .writeFile, .bash],
    model: ModelID("gpt-4o"),
    provider: provider
)

let stream = Runner.runStream(
    agent: agent,
    prompt: "Create a new Swift file"
)

for try await event in stream {
    switch event.type {
    case .toolCall:
        if let tool = event.tool {
            let request = PermissionRequest(tool: tool)
            let decision = await permManager.requestPermission(request)
            if decision.decision == .deny {
                print("\n[Blocked: \(tool.rawValue)]")
            }
        }
    case .content:
        if let data = event.data {
            print(data, terminator: "")
        }
    default:
        break
    }
}
```

## 6. Using Different Loop Strategies

```swift
// Plan-and-Execute for complex multi-step tasks
let planner = Agent(
    name: "Planner",
    instructions: "Plan first, then execute step by step.",
    tools: [.readFile, .writeFile, .editFile, .bash],
    loopType: .planAndExecute,
    model: ModelID("gpt-4o"),
    provider: provider
)

// Parallel for independent operations
let parallel = Agent(
    name: "Parallel",
    instructions: "Execute independent tasks in parallel.",
    tools: [.readFile, .webSearch],
    loopType: .parallel,
    model: ModelID("gpt-4o"),
    provider: provider
)
```

## 7. Custom Tools

```swift
struct CustomTool: ToolDefinition {
    let name = "uppercase"
    let description = "Convert text to uppercase."
    let annotations = ToolAnnotations(readOnlyHint: true, idempotentHint: true)
    let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "text": ["type": "string", "description": "Text to convert"],
        ] as [String: Any]),
        "required": AnyCodable(["text"]),
    ]

    func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        guard let text = params["text"]?.value as? String else {
            return .failure(error: "Missing text parameter")
        }
        return .success(data: text.uppercased())
    }
}

let registry = ToolRegistry()
registry.register(CustomTool())
registry.register(ReadFileTool())
registry.register(BashTool())
```

## 8. Using Hooks

```swift
let hookManager = HookManager()

hookManager.addHook(HookDefinition(
    event: .beforeExecution,
    command: "echo 'Agent starting...'"
))

hookManager.addHook(HookDefinition(
    event: .afterExecution,
    command: "echo 'Agent finished.'"
))

Runner.setHookManager(hookManager)
```

## Next Steps

- Read [API_REFERENCE.md](./API_REFERENCE.md) for complete method documentation
- See [MIGRATION.md](./MIGRATION.md) if migrating from the TypeScript SDK
- Check the `Examples/` directory for more patterns
