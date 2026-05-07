/// Example 08: Memory Management
/// Agent memory persistence across sessions.
///
/// Run: swift run 08-memory-management

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

print("=== Memory Management Example ===\n")

// Phase 1: Save a preference to memory
print("--- Phase 1: Save ---\n")

let saveAgent = Agent(
    name: "MemorySaver",
    instructions: "You save information to memory when asked. Use the write_file tool to persist data.",
    tools: [.writeFile, .readFile],
    maxTurns: 5,
    model: ModelID("gpt-4o"),
    provider: provider
)

let saveStream = Runner.runStream(
    agent: saveAgent,
    prompt: "Save this to a file at /tmp/agent-sdk-memory.txt: 'The user prefers Swift over Objective-C and likes protocol-oriented programming.'"
)

do {
    for try await event in saveStream {
        switch event.type {
        case .content:
            if let data = event.data {
                print(data, terminator: "")
                fflush(stdout)
            }
        case .toolCall:
            print("\n💾 [\(event.tool?.rawValue ?? "")]")
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

// Phase 2: Recall the memory in a fresh session
print("--- Phase 2: Recall ---\n")

let recallAgent = Agent(
    name: "MemoryRecaller",
    instructions: "You recall information from files when asked.",
    tools: [.readFile],
    maxTurns: 5,
    model: ModelID("gpt-4o"),
    provider: provider
)

let recallStream = Runner.runStream(
    agent: recallAgent,
    prompt: "Read the file at /tmp/agent-sdk-memory.txt and tell me what programming preferences are stored there."
)

do {
    for try await event in recallStream {
        switch event.type {
        case .content:
            if let data = event.data {
                print(data, terminator: "")
                fflush(stdout)
            }
        case .toolCall:
            print("\n🔍 [\(event.tool?.rawValue ?? "")]")
        case .done:
            break
        default:
            break
        }
    }
} catch {
    print("Error: \(error.localizedDescription)")
}

print("\n\n✓ Memory management example complete")
