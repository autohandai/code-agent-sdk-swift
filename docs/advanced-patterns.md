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
should critique its own output between turns.
