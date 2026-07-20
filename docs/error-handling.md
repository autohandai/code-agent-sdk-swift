# Error Handling

Swift APIs throw `AgentSDKError` for known SDK failures and regular `Error`
values for provider/tool failures.

```swift
do {
    let result = try await Runner.runSync(agent: agent, prompt: "Review this package")
    print(result)
} catch let error as AgentSDKError {
    print("SDK error: \(error)")
} catch {
    print("Unexpected error: \(error)")
}
```

Streaming runs surface failures through the async throwing stream:

```swift
do {
    for try await event in Runner.runStream(agent: agent, prompt: "Run checks") {
        print(event)
    }
} catch {
    print("Stream failed: \(error)")
}
```

Common causes include missing provider credentials, unsupported model names,
tool execution failures, and max-turn limits.

CLI-backed calls throw `AutohandCLIClientError`. Cancellation is preserved as
`CancellationError`, so it can be handled separately from timeouts:

```swift
let task = Task { try await sdk.listMCPServers() }
task.cancel()

do {
    _ = try await task.value
} catch is CancellationError {
    // The blocked transport wait was removed by JSON-RPC ID.
}
```

Cancellation does not wait for the CLI operation itself to finish. A late
response for the abandoned ID is discarded, while unrelated control/discovery
requests and later prompts continue to use the same client safely.

Startup is transactional. If configured feature flags cannot be applied after
the process launches, the client terminates that process, resets `isRunning`,
and rethrows. The same client can then retry `start()`.
