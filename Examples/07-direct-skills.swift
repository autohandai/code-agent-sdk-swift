/// Example 07: Direct Skills
/// Direct skill names and local SKILL.md paths.
///
/// Run: swift run 07-direct-skills

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let agent = Agent(
    name: "DirectSkillAgent",
    instructions: """
    You are a coding assistant with loaded skills.
    Apply the loaded skills to all code you write and review.
    """,
    tools: [.readFile, .writeFile, .bash],
    maxTurns: 8,
    model: ModelID("gpt-4o"),
    provider: provider,
    customInstructions: [
        "Skill: typescript-best-practices — Use strict TypeScript, prefer interfaces over types for public APIs, avoid any.",
        "Skill: testing — Write tests before implementation, use describe/it blocks, cover edge cases.",
    ]
)

print("Direct Skills Example\n")
print("Skills loaded: typescript-best-practices, testing\n")

let stream = Runner.runStream(
    agent: agent,
    prompt: "Write a small utility function in /tmp/skill-demo.swift that validates an email address. Include tests."
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
            print("\n📝 [\(event.tool?.rawValue ?? "")]")
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
