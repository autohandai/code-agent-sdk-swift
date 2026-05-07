/// Example: Basic Agent
/// Minimal agent setup with all configuration options.
///
/// Run: swift run basic-agent

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."

print("=== Basic Agent Setup ===\n")

// 1. Create a provider
let provider = OpenAIProvider(apiKey: apiKey)
print("✓ Provider created: OpenAI")

// 2. Create an agent with full configuration
let agent = Agent(
    name: "BasicAgent",
    instructions: "You are a helpful coding assistant. Keep responses concise and actionable.",
    tools: [
        .readFile,
        .writeFile,
        .editFile,
        .bash,
        .gitStatus,
        .gitDiff,
        .gitLog,
        .webSearch,
    ],
    maxTurns: 15,
    model: ModelID("gpt-4o"),
    provider: provider,
    loopType: .react,
    cwd: FileManager.default.currentDirectoryPath,
    memories: nil,
    customInstructions: [
        "Prefer Swift concurrency patterns.",
        "Use protocols for abstraction.",
        "Write tests for all new code.",
    ],
    modelSettings: [
        "temperature": AnyCodable(0.7),
        "max_tokens": AnyCodable(4096),
    ]
)

print("✓ Agent created: \(agent.name)")
print("  Instructions: \(agent.instructions.prefix(50))...")
print("  Tools: \(agent.tools.map(\.rawValue).joined(separator: ", "))")
print("  Max turns: \(agent.maxTurns)")
print("  Model: \(agent.model?.rawValue ?? "none")")
print("  Loop type: \(agent.loopType.rawValue)")
print("  CWD: \(agent.cwd ?? "none")")
print("  Custom instructions: \(agent.customInstructions?.count ?? 0)")

// 3. Create a hook manager
let hookManager = HookManager()
hookManager.addHook(HookDefinition(
    event: .beforeExecution,
    command: "echo 'Starting agent execution...'",
    description: "Log execution start"
))
hookManager.addHook(HookDefinition(
    event: .afterExecution,
    command: "echo 'Agent execution complete.'",
    description: "Log execution end"
))
Runner.setHookManager(hookManager)
print("✓ Hooks configured: \(hookManager.getAllHooks().count)")

// 4. Create a permission manager
let permManager = PermissionManager(hookManager: hookManager, mode: .ask)
Runner.setPermissionManager(permManager)
print("✓ Permissions configured: \(permManager.permissionMode.rawValue)")

// 5. Run a simple prompt
print("\n--- Running agent ---\n")

let stream = Runner.runStream(
    agent: agent,
    prompt: "List the files in the current directory and tell me what kind of project this is."
)

do {
    for try await event in stream {
        switch event.type {
        case .content:
            if let data = event.data {
                print(data, terminator: "")
                fflush(stdout)
            }
        case .toolCall:
            print("\n⚡ [\(event.tool?.rawValue ?? "")]")
        case .toolResult:
            print("   ✓")
        case .toolError:
            print("   ✗ \(event.data ?? "")")
        case .done:
            print("\n")
        }
    }
} catch {
    print("Error: \(error.localizedDescription)")
}

print("✓ Basic agent example complete")
