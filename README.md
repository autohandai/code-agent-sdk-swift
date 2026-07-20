# Code Agent SDK for Swift

SwiftPM package for building Autohand-style code agents in Swift. It provides
`Agent`, `Runner`, async streams, provider abstractions, tools, hooks, loop
strategies, and permission controls.

**Beta:** this SDK is actively evolving while the Agent SDK APIs stabilize. Pin versions in production and review release notes before upgrading.

## Other Programming Languages (Beta)

The Agent SDK is available in multiple beta language packages. Use the same Autohand code-agent model from another programming language:

- [TypeScript](https://github.com/autohandai/code-agent-sdk-typescript) - `Agent`, `Run`, streaming, and JSON helpers for Node and Bun hosts.
- [Go](https://github.com/autohandai/code-agent-sdk-go) - idiomatic Go package with `context.Context`, typed events, and channel-based streaming.
- [Python](https://github.com/autohandai/code-agent-sdk-python) - async Python package with `async for` event streams and typed Pydantic models.
- [Java](https://github.com/autohandai/code-agent-sdk-java) - Java 21 records, sealed events, and virtual-thread-ready APIs.
- [Swift](https://github.com/autohandai/code-agent-sdk-swift) - this SwiftPM package.
- [Rust](https://github.com/autohandai/code-agent-sdk-rust) - async Rust crate with Tokio, typed events, and stream-based runs.
- [C++](https://github.com/autohandai/code-agent-sdk-cpp) - modern C++20 package with CMake targets and typed event callbacks.
- [C#](https://github.com/autohandai/code-agent-sdk-csharp) - .NET package with `IAsyncEnumerable`, `CancellationToken`, and `System.Text.Json`.

## Requirements

- Swift 6.0+
- macOS 14+ or iOS 17+
- An OpenAI-compatible provider key for live provider-backed runs. For Autohand AI Cloud, set `AUTOHAND_AI_API_KEY` and use `ProviderFactory.create(providerName: "autohandai", ...)`.

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

## CLI-backed discovery, goals, and autoresearch

On macOS, `AutohandCLIClient` adds the same typed replayable autoresearch ledger
available in the TypeScript 1.0.3 SDK while preserving the existing direct-provider
`Agent` and `Runner` APIs:

```swift
let client = AutohandCLIClient(configuration: .init(cwd: ".", unrestricted: true))
try client.start()
defer { client.close() }

if try await client.supportsCommand("/autoresearch") {
    let start = try await client.startAutoresearch(.init(
        objective: "Reduce test runtime",
        metricName: "test_ms",
        metricUnit: "ms",
        direction: .lower,
        measureCommand: "swift test"
    ))
    if let instruction = start.instruction {
        _ = try await client.prompt(instruction)
    }
    let history = try await client.autoresearchHistory()
    _ = try await client.stopAutoresearch()
}
```

Persistent goals use the same seven JSON-RPC operations as the TypeScript SDK:

```swift
if case .value(let result) = try await client.createGoal(.init(
    objective: "Ship the Swift SDK",
    tokenBudget: 40_000
)) {
    print(result.ok)
}

_ = try await client.updateGoal(.init(
    status: .paused,
    tokenBudget: .clear
))
let snapshot = try await client.goal()
let templates = try await client.goalTemplates()
```

For a single high-level lifecycle object, use `AutohandSDK`. It owns an
`AutohandCLIClient` and exposes typed skill-registry and MCP discovery:

```swift
let sdk = AutohandSDK(configuration: .init(cwd: "."))
try sdk.start()
defer { sdk.close() }

let registry = try await sdk.getSkillsRegistry(.init(forceRefresh: true))
let installation = try await sdk.installSkill(.init(
    skillName: "release-readiness",
    scope: .project,
    force: false
))
let servers = try await sdk.listMCPServers()
let tools = try await sdk.listMCPTools(.init(serverName: "filesystem"))
let configs = try await sdk.getMCPServerConfigs()
```

These methods call `autohand.getSkillsRegistry`, `autohand.installSkill`,
`autohand.mcp.listServers`, `autohand.mcp.listTools`, and
`autohand.mcp.getServerConfigs` with the CLI's exact camel-case wire keys.
Installing a skill changes user or project state; discovery calls are read-only.

`AutohandSDK` is the macOS CLI-facing API. The cross-platform `Agent` and
`Runner` remain direct-provider APIs and do not silently launch a subprocess.

`AutohandCLIConfiguration` also mirrors current CLI session, AGENTS.md, token,
skill-source, auto-mode, prompt, feature-flag, and Autohand AI environment
settings. A non-nil `features` value is applied immediately after startup.

Read the [replayable autoresearch guide](./docs/autoresearch.md) for replay,
rescore, comparison, Pareto, pinning, retention, and event semantics.

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

Only the names in `Agent.tools` are advertised to the provider and executable.
An empty list exposes no tools. When a `PermissionManager` is installed on
`Runner`, every requested tool is checked before its implementation runs.

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
- [Replayable Autoresearch](./docs/autoresearch.md)
- [Reliability and Performance](./docs/reliability-and-performance.md)
- [Migration](./docs/MIGRATION.md)
- [SDLC Workflows](./docs/sdlc-workflows.md)
- [Examples](./Examples/README.md)

## Development

```bash
swift build
swift test
Scripts/benchmark-startup.sh
```
