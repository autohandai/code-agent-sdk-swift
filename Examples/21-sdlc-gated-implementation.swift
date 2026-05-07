/// Example 21: SDLC Gated Implementation
/// Plan first, execute only after an explicit gate.
///
/// Run: swift run 21-sdlc-gated-implementation

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let executePlan = ProcessInfo.processInfo.environment["EXECUTE_PLAN"] == "1"

print("=== SDLC Gated Implementation ===\n")

// Phase 1: Planning (always runs)
print("--- Planning Phase ---\n")

let planAgent = Agent(
    name: "Planner",
    instructions: """
    Create an implementation plan for the requested change.
    Use repository inspection only. Do not edit files.
    Return numbered steps with test coverage and rollback notes.
    """,
    tools: [.readFile, .bash],
    maxTurns: 8,
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: FileManager.default.currentDirectoryPath
)

let planStream = Runner.runStream(
    agent: planAgent,
    prompt: "Create an implementation plan for adding a new tool called 'json_validate' that validates JSON strings against a schema."
)

do {
    for try await event in planStream {
        switch event.type {
        case .content:
            if let data = event.data {
                print(data, terminator: "")
                fflush(stdout)
            }
        case .toolCall:
            print("\n📋 [\(event.tool?.rawValue ?? "")]")
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

if !executePlan {
    print("--- Gate Closed ---")
    print("Set EXECUTE_PLAN=1 after reviewing the plan to run the implementation phase.")
} else {
    // Phase 2: Implementation
    print("--- Implementation Phase ---\n")

    let implAgent = Agent(
        name: "Implementer",
        instructions: "Implement the approved plan. Keep changes scoped. Run checks.",
        tools: [.readFile, .writeFile, .editFile, .bash],
        maxTurns: 10,
        model: ModelID("gpt-4o"),
        provider: provider,
        cwd: FileManager.default.currentDirectoryPath
    )

    let implStream = Runner.runStream(
        agent: implAgent,
        prompt: "Implement the approved plan. Keep changes scoped. Summarize changed files."
    )

    do {
        for try await event in implStream {
            switch event.type {
            case .content:
                if let data = event.data {
                    print(data, terminator: "")
                    fflush(stdout)
                }
            case .toolCall:
                print("\n⚡ [\(event.tool?.rawValue ?? "")]")
            case .done:
                break
            default:
                break
            }
        }
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

print("\n✓ SDLC gated workflow complete")
