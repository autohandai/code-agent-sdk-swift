# Event Streaming

Use `Runner.runStream` to receive `StreamEvent` values while the run is active.

```swift
let stream = Runner.runStream(
    agent: agent,
    prompt: "Explain this repository"
)

for try await event in stream {
    switch event.type {
    case .content:
        print(event.data ?? "", terminator: "")
    case .toolCall:
        print("\n[tool: \(event.tool?.rawValue ?? "unknown")]")
    case .toolResult:
        print("\n[result: \(event.data ?? "")]")
    case .toolError:
        print("\n[tool error: \(event.data ?? "")]")
    case .done:
        print("\nDone")
    }
}
```

Events include content chunks, tool calls, tool results, tool errors, and final
completion.
