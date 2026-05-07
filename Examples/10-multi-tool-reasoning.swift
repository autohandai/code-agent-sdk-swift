/// Example 10: Multi-Tool Reasoning
/// Using multiple tools across turns for codebase analysis.
///
/// Run: swift run 10-multi-tool-reasoning

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let tmpDir = "/tmp/multi-tool-example-\(Int.random(in: 1000...9999))"
try FileManager.default.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)

try """
func fibonacci(_ n: Int) -> Int {
    if n <= 0 { return 0 }
    if n == 1 { return 1 }
    var a = 0, b = 1
    for _ in 2...n {
        (a, b) = (b, a + b)
    }
    return b
}

func factorial(_ n: Int) -> Int {
    guard n >= 0 else { fatalError("factorial undefined for negative numbers") }
    var result = 1
    for i in 2...n {
        result *= i
    }
    return result
}

print("fibonacci(10) = \\(fibonacci(10))")
print("factorial(5) = \\(factorial(5))")
""".write(toFile: "\(tmpDir)/math-utils.swift", atomically: true, encoding: .utf8)

print("=== Multi-Tool Reasoning Demo ===\n")
print("Created test project in: \(tmpDir)\n")

let agent = Agent(
    name: "MultiToolAgent",
    instructions: "You analyze codebases using multiple tools across turns.",
    tools: [.readFile, .bash],
    maxTurns: 10,
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: tmpDir
)

let stream = Runner.runStream(
    agent: agent,
    prompt: "First, list all Swift files in this directory. Then read each one. Finally, run 'swift math-utils.swift' and report the results. Summarize the codebase."
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
            print("\n⚡ [\(event.tool?.rawValue ?? "")]")
        case .toolResult:
            if let data = event.data {
                let preview = String(data.prefix(300))
                print(preview)
                if data.count > 300 { print("...") }
            }
        case .done:
            break
        default:
            break
        }
    }
} catch {
    print("\n✗ Error: \(error.localizedDescription)")
}

try? FileManager.default.removeItem(atPath: tmpDir)
print("\n✓ Cleaned up: \(tmpDir)")
