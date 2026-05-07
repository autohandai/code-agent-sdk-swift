# Plan Mode

The Swift SDK does not expose a separate CLI-style plan-mode flag because it is
an in-process agent package. Use a planning-oriented `Agent` and a
plan-and-execute loop strategy for read-first workflows.

```swift
let planner = Agent(
    name: "Planner",
    instructions: "Inspect and produce a plan. Do not modify files.",
    tools: [.readFile, .gitStatus, .gitDiff],
    loopType: .planAndExecute,
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: projectPath
)

let plan = try await Runner.runSync(
    agent: planner,
    prompt: "Plan this refactor"
)
```

Review the plan in your host, then create an implementation agent with write
tools enabled.
