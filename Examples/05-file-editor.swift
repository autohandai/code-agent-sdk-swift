/// Example 05: File Editor
/// File editing workflow with permission routing.
///
/// Run: swift run 05-file-editor

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let hookManager = HookManager()
let permManager = PermissionManager(hookManager: hookManager, mode: .ask)
Runner.setPermissionManager(permManager)

let agent = Agent(
    name: "FileEditor",
    instructions: """
    You edit files based on user requests. Always:
    1. Read the file first to understand current content
    2. Make precise edits using edit_file
    3. Confirm the edit was successful
    """,
    tools: [.readFile, .writeFile, .editFile],
    maxTurns: 10,
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: FileManager.default.currentDirectoryPath
)

print("File editor agent ready.\n")

let stream = Runner.runStream(
    agent: agent,
    prompt: "Create a file called /tmp/agent-sdk-swift-demo.txt with the text 'Hello from AgentSDK for Swift!' and then read it back to confirm."
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
                let decision = await permManager.requestPermission(request)
                if decision.decision == .deny || decision.decision == .block {
                    print("\n🚫 Blocked: \(tool.rawValue) — \(decision.reason ?? "")")
                } else {
                    print("\n📝 \(tool.rawValue)...")
                }
            }
        case .toolResult:
            print(" ✓")
        case .toolError:
            print("\n✗ Error: \(event.data ?? "")")
        case .done:
            print("\n✓ File operations complete")
        }
    }
} catch {
    print("\n✗ Error: \(error.localizedDescription)")
    exit(1)
}
