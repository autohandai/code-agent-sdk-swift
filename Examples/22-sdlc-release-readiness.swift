/// Example 22: SDLC Release Readiness
/// Agent runs production gates and reports release risk.
///
/// Run: swift run 22-sdlc-release-readiness

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let agent = Agent(
    name: "ReleaseReviewer",
    instructions: """
    You run release-readiness checks for SDK repositories.
    Run the standard commands and report results.
    If a command fails, stop and explain the failure with file references.
    If all commands pass, summarize residual risks and production readiness.
    """,
    tools: [.bash, .readFile],
    maxTurns: 12,
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: FileManager.default.currentDirectoryPath
)

print("=== SDLC Release Readiness ===\n")

var toolResults: [(name: String, success: Bool)] = []

let stream = Runner.runStream(
    agent: agent,
    prompt: """
    Run a release-readiness pass for this Swift SDK.
    Use the standard commands: swift build, swift test.
    If a command fails, stop and explain the failure with file references.
    If all commands pass, summarize residual risks and production readiness.
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
            print("\n🚀 [\(event.tool?.rawValue ?? "")]")
        case .toolResult:
            if let tool = event.tool {
                toolResults.append((name: tool.rawValue, success: true))
            }
            print("   ✓")
        case .toolError:
            if let tool = event.tool {
                toolResults.append((name: tool.rawValue, success: false))
            }
            print("   ✗")
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

if !toolResults.isEmpty {
    print("\n--- Tool Summary ---")
    for result in toolResults {
        print("\(result.name): \(result.success ? "pass" : "fail")")
    }
}

print("\n✓ Release readiness check complete")
