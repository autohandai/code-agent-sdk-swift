/// Example: Loop Strategies
/// Different execution modes for the agent.
///
/// Run: swift run loop-strategies

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

print("=== Loop Strategies Demo ===\n")

let strategies: [(LoopType, String)] = [
    (.react, "ReAct (Reason-Act loop)"),
    (.planAndExecute, "Plan-and-Execute"),
    (.parallel, "Parallel execution"),
    (.reflexion, "Reflexion (self-reflective)"),
]

for (loopType, name) in strategies {
    print("--- \(name) ---\n")

    let agent = Agent(
        name: "LoopAgent",
        instructions: "You are a helpful coding assistant. Be concise.",
        tools: [.readFile, .bash],
        maxTurns: 5,
        model: ModelID("gpt-4o"),
        provider: provider,
        loopType: loopType,
        cwd: FileManager.default.currentDirectoryPath
    )

    let stream = Runner.runStream(
        agent: agent,
        prompt: "List the Swift files in the Sources directory and tell me how many there are."
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
                print("\n[\(loopType.rawValue)] 🔧 \(event.tool?.rawValue ?? "")")
            case .done:
                break
            default:
                break
            }
        }
    } catch {
        print("Error: \(error.localizedDescription)")
    }

    print("\n")
}

print("✓ Loop strategies demo complete")
