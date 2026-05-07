# Code Agent SDK for Swift

SwiftPM package for building Autohand-style code agents in Swift. It provides
`Agent`, `Runner`, async streams, provider abstractions, tools, hooks, loop
strategies, and permission controls.

## Other SDKs

Use the same Autohand code-agent model from another language:

- [TypeScript](https://github.com/autohandai/code-agent-sdk-typescript) - `Agent`, `Run`, streaming, and JSON helpers for Node and Bun hosts.
- [Go](https://github.com/autohandai/code-agent-sdk-go) - idiomatic Go package with `context.Context`, typed events, and channel-based streaming.
- [Python](https://github.com/autohandai/code-agent-sdk-python) - async Python package with `async for` event streams and typed Pydantic models.
- [Java](https://github.com/autohandai/code-agent-sdk-java) - Java 21 records, sealed events, and virtual-thread-ready APIs.
- [Swift](https://github.com/autohandai/code-agent-sdk-swift) - this SwiftPM package.

## Requirements

- Swift 6.0+
- macOS 14+ or iOS 17+
- An OpenAI-compatible provider key for live provider-backed runs

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/autohandai/code-agent-sdk-swift.git", branch: "main"),
]
```

Then depend on `AgentSDK` from your target:

```swift
.executableTarget(
    name: "MyAgentApp",
    dependencies: ["AgentSDK"]
)
```

## Quick Start

```swift
import AgentSDK
import Foundation

let provider = OpenAIProvider(apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!)

let agent = Agent(
    name: "Reviewer",
    instructions: "Review code for correctness and maintainability.",
    tools: [.readFile, .bash],
    maxTurns: 10,
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: FileManager.default.currentDirectoryPath
)

let result = try await Runner.runSync(
    agent: agent,
    prompt: "Summarize this package"
)

print(result)
```

## Streaming

```swift
let stream = Runner.runStream(
    agent: agent,
    prompt: "Review Sources/Types.swift"
)

for try await event in stream {
    switch event.type {
    case .content:
        print(event.data ?? "", terminator: "")
    case .toolCall:
        print("\n[tool: \(event.tool?.rawValue ?? "unknown")]")
    case .done:
        print("\nDone")
    default:
        break
    }
}
```

## Documentation

- [Getting Started](./docs/GETTING_STARTED.md)
- [API Reference](./docs/API_REFERENCE.md)
- [Configuration](./docs/configuration.md)
- [Event Streaming](./docs/event-streaming.md)
- [Error Handling](./docs/error-handling.md)
- [Advanced Patterns](./docs/advanced-patterns.md)
- [Permissions](./docs/permissions.md)
- [Plan Mode](./docs/plan-mode.md)
- [Memory](./docs/memory.md)
- [Migration](./docs/MIGRATION.md)
- [SDLC Workflows](./docs/sdlc-workflows.md)
- [Examples](./Examples/README.md)

## Development

```bash
swift build
swift test
```
