# Advanced Patterns

## Custom Tools

```swift
struct UppercaseTool: ToolDefinition {
    let name = "uppercase"
    let description = "Convert text to uppercase."
    let annotations = ToolAnnotations(readOnlyHint: true, idempotentHint: true)
    let parameters: [String: AnyCodable] = [:]

    func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        let text = params["text"]?.value as? String ?? ""
        return .success(data: text.uppercased())
    }
}
```

## Hooks

```swift
let hooks = HookManager()
Runner.setHookManager(hooks)
```

Use hooks to observe or gate tool execution in host applications.

## Skills and MCP discovery

Use the high-level macOS facade for typed CLI discovery and installation:

```swift
let sdk = AutohandSDK(configuration: .init(cwd: projectPath))
try sdk.start()
defer { sdk.close() }

let registry = try await sdk.getSkillsRegistry()
let filesystemTools = try await sdk.listMCPTools(.init(serverName: "filesystem"))

if registry.skills.contains(where: { $0.id == "release-readiness" }) {
    let result = try await sdk.installSkill(.init(
        skillName: "release-readiness",
        scope: .project
    ))
    print(result.path ?? "installed")
}
```

Call `sdk.client` when an application also needs lower-level goal,
autoresearch, or prompt RPCs.

## Structured JSON

Use `Codable` validation in the host:

```swift
struct ReleaseRisk: Codable {
    let summary: String
    let risks: [String]
}

let text = try await Runner.runSync(agent: agent, prompt: "Return release risk as JSON")
let risk = try JSONDecoder().decode(ReleaseRisk.self, from: Data(text.utf8))
```

## Sessions And Loop Strategies

Choose `.react` for simple tasks, `.planAndExecute` for larger implementation
work, `.parallel` for independent actions, and `.reflexion` when the agent
should critique its own output between turns. Runtime options override strategy
prompt defaults. They are model guidance; tool calls returned by the model are
currently executed serially:

```swift
let result = try await Runner.run(
    agent: planner,
    prompt: "Plan and implement the change",
    options: .init(maxPlanningSteps: 3)
)
```
