# Permissions

Use `PermissionManager` to approve, deny, or ask before tool execution.

```swift
let hookManager = HookManager()
let permissionManager = PermissionManager(
    hookManager: hookManager,
    mode: .ask
)

Runner.setPermissionManager(permissionManager)
```

`Runner` now checks the manager before every tool implementation. `.deny`
returns a failed tool result without executing the tool, `.yolo` executes, and
`.ask` returns an approval-required result without executing. A host can obtain
approval, switch the manager's mode, and rerun. Tool arguments, file paths, and
commands are included in the request when present.

Streaming callbacks remain useful for observing decisions:

```swift
for try await event in Runner.runStream(agent: agent, prompt: "Create a file") {
    if event.type == .toolCall, let tool = event.tool {
        print("Permission checked before \(tool.rawValue)")
    }
    if event.type == .toolError {
        print(event.data ?? "Tool was blocked")
    }
}
```

Modes are `.ask`, `.deny`, and `.yolo`.

Set the manager back to `nil` to disable permission gating:

```swift
Runner.setPermissionManager(nil)
```
