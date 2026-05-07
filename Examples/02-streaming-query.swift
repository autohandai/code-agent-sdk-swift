/// Example 02: Streaming Query
/// Structured event handling with real-time output.
///
/// Run: swift run 02-streaming-query

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let agent = Agent(
    name: "StreamingAgent",
    instructions: "You are a helpful coding assistant. Be concise.",
    tools: [.readFile, .bash],
    maxTurns: 10,
    model: ModelID("gpt-4o"),
    provider: provider
)

print("Streaming prompt...\n")

let stream = Runner.runStream(
    agent: agent,
    prompt: "List the files in the current directory and explain what each one does."
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
            print("\n━━ [Tool: \(event.tool?.rawValue ?? "unknown")] ━━")
        case .toolResult:
            if let data = event.data {
                let preview = String(data.prefix(200))
                print(preview)
                if data.count > 200 { print("...") }
            }
        case .toolError:
            print("\n✗ [Tool Error: \(event.data ?? "unknown")]")
        case .done:
            print("\n\n✓ Done")
        }
    }
} catch {
    print("\n✗ Error: \(error.localizedDescription)")
    exit(1)
}
