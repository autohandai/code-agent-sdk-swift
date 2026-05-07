/// Example 23: System Prompts
/// Configuring system prompts with append and replace modes.
///
/// Run: swift run 23-system-prompts

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let mode = ProcessInfo.processInfo.environment["PROMPT_MODE"] ?? "append"

print("=== System Prompt Configuration ===\n")
print("Mode: \(mode)\n")

let agent: Agent
if mode == "replace" {
    agent = Agent(
        name: "CustomPromptAgent",
        instructions: """
        You are a release-review agent.
        Inspect the repository carefully.
        Return concise findings with file references and verification steps.
        """,
        tools: [.readFile, .bash],
        maxTurns: 8,
        model: ModelID("gpt-4o"),
        provider: provider,
        cwd: FileManager.default.currentDirectoryPath
    )
} else {
    agent = Agent(
        name: "AppendedPromptAgent",
        instructions: """
        You are a helpful coding assistant.
        For this SDK repository, prefer Swift concurrency patterns.
        Call out permission-sensitive operations before recommending execution.
        Keep responses focused on SDK API design.
        """,
        tools: [.readFile, .bash],
        maxTurns: 8,
        model: ModelID("gpt-4o"),
        provider: provider,
        cwd: FileManager.default.currentDirectoryPath
    )
}

let stream = Runner.runStream(
    agent: agent,
    prompt: "Review the public SDK surface for system prompt ergonomics."
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
            print("\n🔍 [\(event.tool?.rawValue ?? "")]")
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

print("\n\n✓ System prompt example complete")
