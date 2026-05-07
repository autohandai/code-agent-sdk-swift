/// Example 06: Prompt Skills
/// Skills referenced in prompt text via /skill syntax.
///
/// Run: swift run 06-prompt-skills

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let agent = Agent(
    name: "SkillAgent",
    instructions: """
    You are a coding assistant with access to skills.
    When the user references a skill with /skill, apply that skill's guidance.
    """,
    tools: [.readFile, .bash],
    maxTurns: 8,
    model: ModelID("gpt-4o"),
    provider: provider
)

print("Prompt Skills Example\n")
print("Skills are loaded via the agent's customInstructions.\n")

let stream = Runner.runStream(
    agent: agent,
    prompt: "Review the code in Sources/Types.swift using TypeScript best practices for type safety."
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
            print("\n🔧 [\(event.tool?.rawValue ?? "")]")
        case .toolResult:
            print("   ✓")
        case .done:
            print("\n\n✓ Done")
        default:
            break
        }
    }
} catch {
    print("\n✗ Error: \(error.localizedDescription)")
    exit(1)
}
