# SDLC Workflows With The Swift SDK

## Discovery

```swift
let planner = Agent(
    name: "Planner",
    instructions: "Inspect first and produce an implementation plan.",
    tools: [.readFile, .gitStatus, .gitDiff],
    loopType: .planAndExecute,
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: projectPath
)

let plan = try await Runner.runSync(agent: planner, prompt: "Plan the feature")
print(plan)
```

## Gated Implementation

After host approval, create an implementation agent with write tools and
permission handling:

```swift
let implementer = Agent(
    name: "Implementer",
    instructions: "Implement the approved plan and run verification.",
    tools: [.readFile, .writeFile, .editFile, .bash],
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: projectPath
)

for try await event in Runner.runStream(agent: implementer, prompt: "Execute the approved plan") {
    if event.type == .content {
        print(event.data ?? "", terminator: "")
    }
}
```

## Release Readiness

Ask the agent to inspect the package and report commands, failures, and residual
risk:

```swift
let result = try await Runner.runSync(
    agent: implementer,
    prompt: """
    Run release readiness:
    - swift build
    - swift test
    - inspect docs and examples for API drift
    """
)
```
