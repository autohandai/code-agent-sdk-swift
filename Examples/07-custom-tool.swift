/// Example 07: Custom Tool
/// Registering and using a custom tool definition.
///
/// Run: swift run 07-custom-tool

import AgentSDK
import Foundation

struct WordCountTool: ToolDefinition {
    let name = "word_count"
    let description = "Count the number of words, lines, and characters in a string."
    let annotations = ToolAnnotations(readOnlyHint: true, idempotentHint: true)
    let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "text": ["type": "string", "description": "Text to analyze"],
        ] as [String: Any]),
        "required": AnyCodable(["text"]),
    ]

    func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        guard let text = params["text"]?.value as? String else {
            return .failure(error: "Missing text parameter")
        }

        let words = text.split(separator: " ").count
        let lines = text.split(separator: "\n").count
        let chars = text.count

        return .success(data: """
        Words: \(words)
        Lines: \(lines)
        Characters: \(chars)
        """)
    }
}

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let agent = Agent(
    name: "CustomToolAgent",
    instructions: "You have access to a word_count tool. Use it when asked to analyze text.",
    tools: [.readFile],
    maxTurns: 5,
    model: ModelID("gpt-4o"),
    provider: provider
)

print("Testing custom tool...\n")

let tool = WordCountTool()
let result = try await tool.execute(params: [
    "text": AnyCodable("The quick brown fox jumps over the lazy dog.")
])
print("WordCountTool result:\n\(result.data ?? result.error ?? "no output")")

print("\n✓ Custom tool example complete")
