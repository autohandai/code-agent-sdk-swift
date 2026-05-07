# Memory

The Swift SDK lets hosts provide memory or custom instructions when constructing
an agent.

```swift
let agent = Agent(
    name: "Reviewer",
    instructions: "Review code for maintainability.",
    tools: [.readFile],
    model: ModelID("gpt-4o"),
    provider: provider,
    memories: "The team prefers SwiftPM packages and focused tests.",
    customInstructions: [
        "Mention verification commands explicitly.",
        "Keep summaries concise."
    ]
)
```

For durable memory, store facts in your application and pass relevant snippets
through `memories` or `customInstructions` when creating the next agent.
