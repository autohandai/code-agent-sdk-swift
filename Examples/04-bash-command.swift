/// Example 04: Bash Command
/// Command execution flow with tool call tracking.
///
/// Run: swift run 04-bash-command

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let agent = Agent(
    name: "CommandRunner",
    instructions: "You execute shell commands to help the user. Always explain what you're doing before running commands.",
    tools: [.bash, .readFile],
    maxTurns: 8,
    model: ModelID("gpt-4o"),
    provider: provider
)

print("Running command agent...\n")

let stream = Runner.runStream(
    agent: agent,
    prompt: "Show me the current git status and the last 3 commits."
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
                print("\n⚡ Running: \(tool.rawValue)")
            }
        case .toolResult:
            if let data = event.data {
                let trimmed = data.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    print(trimmed)
                }
            }
        case .toolError:
            print("\n✗ Command failed: \(event.data ?? "")")
        case .done:
            print("\n✓ All commands completed")
        }
    }
} catch {
    print("\n✗ Error: \(error.localizedDescription)")
    exit(1)
}
