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
