/// Example: SDK Control Features
/// Demonstrates runtime configuration and control methods.
///
/// Run: swift run sdk-control-features

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

print("=== SDK Control Features ===\n")

// 1. Permission mode control
let hookManager = HookManager()
let permManager = PermissionManager(hookManager: hookManager, mode: .ask)
Runner.setPermissionManager(permManager)

print("✓ Permission manager configured (mode: ask)")

// 2. Hook manager control
hookManager.addHook(HookDefinition(
    event: .beforeExecution,
    command: "echo '[hook] Agent execution starting...'"
))
print("✓ Hook registered: beforeExecution")

// 3. Model switching
let agent = Agent(
    name: "ControlAgent",
    instructions: "You are a helpful assistant.",
    tools: [.readFile, .bash],
    maxTurns: 5,
    model: ModelID("gpt-4o"),
    provider: provider
)

print("✓ Agent created with model: gpt-4o")

agent.setModel(ModelID("gpt-4o"))
print("✓ Model switched to: gpt-4o")

// 4. Provider switching
let newProvider = OpenAIProvider(apiKey: apiKey)
agent.setProvider(newProvider)
print("✓ Provider updated")

// 5. Permission mode switching
permManager.setPermissionMode(.yolo)
print("✓ Permission mode switched to: yolo")
permManager.setPermissionMode(.deny)
print("✓ Permission mode switched to: deny")
permManager.setPermissionMode(.ask)
print("✓ Permission mode switched to: ask")

// 6. Loop type inspection
print("✓ Loop type: \(agent.loopType.rawValue)")

// 7. Tool listing
let registry = DefaultToolRegistry()
let tools = registry.getAllTools()
print("✓ Available tools: \(tools.count)")
for tool in tools.prefix(5) {
    print("  - \(tool.name): \(tool.description.prefix(60))...")
}
if tools.count > 5 {
    print("  ... and \(tools.count - 5) more")
}

print("\n✓ All SDK control features verified")
