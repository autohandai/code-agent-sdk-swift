/// Example 13: Permissions
/// Permission request response handling with different modes.
///
/// Run: swift run 13-permissions

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let hookManager = HookManager()

func runWithMode(_ mode: PermissionMode, label: String) async {
    let permManager = PermissionManager(hookManager: hookManager, mode: mode)
    Runner.setPermissionManager(permManager)

    let agent = Agent(
        name: "PermAgent",
        instructions: "You run commands as requested. Be concise.",
        tools: [.bash, .readFile],
        maxTurns: 5,
        model: ModelID("gpt-4o"),
        provider: provider
    )

    print("\n--- \(label) (mode: \(mode.rawValue)) ---\n")

    let stream = Runner.runStream(
        agent: agent,
        prompt: "Run 'echo hello from permissions test' and tell me the output."
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
                if let tool = event.tool {
                    let request = PermissionRequest(tool: tool)
                    let result = await permManager.requestPermission(request)
                    print("\n[Permission: \(result.decision.rawValue) for \(tool.rawValue)]")
                }
            case .done:
                break
            default:
                break
            }
        }
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

print("Testing permission modes...\n")

await runWithMode(.yolo, label: "YOLO Mode")
await runWithMode(.ask, label: "Ask Mode")
await runWithMode(.deny, label: "Deny Mode")

print("\n✓ Permission tests complete")
