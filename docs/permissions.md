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

During a stream, inspect tool-call events and decide whether to continue:

```swift
for try await event in Runner.runStream(agent: agent, prompt: "Create a file") {
    if event.type == .toolCall, let tool = event.tool {
        let request = PermissionRequest(tool: tool)
        let decision = await permissionManager.requestPermission(request)
        if decision.decision == .deny {
            print("Blocked \(tool.rawValue)")
        }
    }
}
```

Modes are `.ask`, `.deny`, and `.yolo`.
