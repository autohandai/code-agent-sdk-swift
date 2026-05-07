/// Example 24: High-Level Agent API
/// Recommended API for application code with clean lifecycle.
///
/// Run: swift run 24-high-level-agent

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

print("=== High-Level Agent API ===\n")

let agent = Agent(
    name: "HighLevelAgent",
    instructions: """
    You are reviewing a Swift SDK API.
    Prefer small, typed, composable protocols.
    Call out permission-sensitive work before recommending execution.
    """,
    tools: [.readFile, .bash],
    maxTurns: 8,
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: FileManager.default.currentDirectoryPath
)

// The high-level API: create agent, run, stream, get result
print("Sending prompt...\n")

let stream = Runner.runStream(
    agent: agent,
    prompt: "Review the public SDK API and list the next three production hardening tasks."
)

var fullResponse = ""

do {
    for try await event in stream {
        switch event.type {
        case .content:
            if let data = event.data {
                print(data, terminator: "")
                fflush(stdout)
                fullResponse += data
            }
        case .toolCall:
            print("\n🔧 [\(event.tool?.rawValue ?? "")]")
        case .toolResult:
            print("   ✓")
        case .done:
            break
        default:
            break
        }
    }
} catch {
    print("\n✗ Error: \(error.localizedDescription)")
    exit(1)
}

print("\n\n--- Result ---")
print("Response length: \(fullResponse.count) characters")
print("\n✓ High-level agent example complete")
