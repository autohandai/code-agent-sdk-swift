/// Example 20: SDLC Discovery & Planning
/// Agent inspects the project and produces an implementation plan.
///
/// Run: swift run 20-sdlc-discovery-plan

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let agent = Agent(
    name: "DiscoveryPlanner",
    instructions: """
    You are in discovery mode for a production SDK change.
    Inspect the repository and produce an SDLC plan only.
    Do not edit files.
    Include scope, risks, test strategy, rollout steps, and explicit non-goals.
    """,
    tools: [.readFile, .bash],
    maxTurns: 10,
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: FileManager.default.currentDirectoryPath
)

print("=== SDLC Discovery & Planning ===\n")

let stream = Runner.runStream(
    agent: agent,
    prompt: """
    We are in discovery for a production TypeScript SDK change.
    Inspect the repository and produce an SDLC plan only.
    Do not edit files.
    Include scope, risks, test strategy, rollout steps, and explicit non-goals.
    """
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
        case .toolResult:
            print("   ✓")
        case .done:
            print("\n\n✓ Discovery complete")
        default:
            break
        }
    }
} catch {
    print("\n✗ Error: \(error.localizedDescription)")
    exit(1)
}
