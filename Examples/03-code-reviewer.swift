/// Example 03: Code Reviewer
/// File-aware review prompt with edit capabilities.
///
/// Run: swift run 03-code-reviewer

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let agent = Agent(
    name: "CodeReviewer",
    instructions: """
    You are a senior code reviewer. When reviewing code:
    1. Check for correctness and potential bugs
    2. Suggest improvements for readability
    3. Verify error handling is adequate
    4. Be specific — reference line numbers when possible
    """,
    tools: [.readFile, .editFile],
    maxTurns: 10,
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: FileManager.default.currentDirectoryPath
)

print("Reviewing Sources/Types.swift...\n")

let stream = Runner.runStream(
    agent: agent,
    prompt: "Review Sources/Types.swift for code quality issues. Focus on type safety and error handling."
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
            print("\n🔧 [\(event.tool?.rawValue ?? "")] ", terminator: "")
        case .toolResult:
            print("✓")
        case .toolError:
            print("\n✗ [Error: \(event.data ?? "")]")
        case .done:
            print("\n\n✓ Review complete")
        }
    }
} catch {
    print("\n✗ Error: \(error.localizedDescription)")
    exit(1)
}
