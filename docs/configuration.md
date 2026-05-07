# Configuration

Create an `Agent` with explicit provider, model, tools, loop strategy, and
workspace settings.

```swift
let provider = OpenAIProvider(apiKey: apiKey)

let agent = Agent(
    name: "Reviewer",
    instructions: "Review code for correctness.",
    tools: [.readFile, .writeFile, .bash],
    maxTurns: 10,
    model: ModelID("gpt-4o"),
    provider: provider,
    loopType: .react,
    cwd: "/path/to/project",
    customInstructions: ["Prefer small, tested changes."]
)
```

## Providers

```swift
let openAI = OpenAIProvider(apiKey: apiKey)
let openRouter = try ProviderFactory.create(
    providerName: "openrouter",
    apiKey: openRouterKey
)
```

`OpenAIProvider` works with OpenAI-compatible APIs when supplied a custom
`baseURL`.

## Loop Strategies

```swift
let react = Agent(..., loopType: .react)
let planner = Agent(..., loopType: .planAndExecute)
let parallel = Agent(..., loopType: .parallel)
let reflexion = Agent(..., loopType: .reflexion)
```

## Run Options

```swift
let result = try await Runner.run(
    agent: agent,
    prompt: "Review this package",
    options: LoopOptions(maxTurns: 8)
)
```
