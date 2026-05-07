/// Example 01: Hello Agent
/// Minimal prompt and state lookup.
///
/// Run: swift run 01-hello-agent

import AgentSDK
import Foundation

let provider = OpenAIProvider(apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-...")

let agent = Agent(
    name: "HelloAgent",
    instructions: "You are a helpful assistant. Keep responses concise.",
    tools: [.readFile],
    maxTurns: 5,
    model: ModelID("gpt-4o"),
    provider: provider
)

print("Sending prompt...\n")

do {
    let result = try await Runner.runSync(
        agent: agent,
        prompt: "Write a one-line hello world program in Swift."
    )
    print("\nResult:\n\(result)")
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}
