# Replayable Autoresearch Ledger

The Swift SDK exposes the Autohand CLI's persisted autoresearch engine through
`AutohandCLIClient`. This macOS-only subprocess client complements the existing
cross-platform provider-backed `Agent` and `Runner`; those APIs remain unchanged.

## Start a session

Use a clean Git repository with at least one commit and check support when your
application may connect to an older CLI:

```swift
let client = AutohandCLIClient(configuration: .init(
    cwd: "/path/to/repository",
    unrestricted: true
))
try client.start()
defer { client.close() }

guard try await client.supportsCommand("/autoresearch") else {
    throw AutohandCLIClientError.invalidResponse("Upgrade the Autohand CLI")
}

let started = try await client.startAutoresearch(.init(
    objective: "Reduce test runtime",
    maxIterations: 3,
    metricName: "test_ms",
    metricUnit: "ms",
    direction: .lower,
    measureCommand: "swift test",
    checksCommand: "swift build -c release"
))

guard started.success, let instruction = started.instruction else {
    throw AutohandCLIClientError.invalidResponse(started.error ?? "Missing instruction")
}
_ = try await client.prompt(instruction)
```

`startAutoresearch` persists configuration and captures the baseline. Its
returned instruction drives the autonomous loop. `stopAutoresearch` pauses the
loop without deleting `.auto/`.

## Typed ledger operations

- `autoresearchStatus()` reads progress, run counts, attempts, and Pareto IDs.
- `autoresearchHistory()` lists immutable attempts and materialization state.
- `replayAutoresearch(_:)` uses the original or current evaluator.
- `rescoreAutoresearch(_:)` applies current policy to stored measurements.
- `compareAutoresearch(_:)` compares samples, checks, and decisions.
- `autoresearchPareto()` lists constraint-passing non-dominated attempts.
- `pinAutoresearch(_:)` protects or releases replay artifacts.
- `pruneAutoresearch(_:)` previews by default; `.apply` explicitly confirms removal.

The event handler receives `.autoresearchLifecycle` and
`.autoresearchOperation` cases. Other notifications remain inspectable through
`.notification`, keeping newer CLI builds forward-compatible.

See [`Examples/27-autoresearch-ledger.swift`](../Examples/27-autoresearch-ledger.swift)
for the complete replayable workflow.
