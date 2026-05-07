/// Example 25: Structured JSON Output
/// Agent returns structured JSON with validation.
///
/// Run: swift run 25-structured-json

import AgentSDK
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

struct ReleaseRisk: Codable {
    let summary: String
    let risks: [Risk]

    struct Risk: Codable {
        let title: String
        let severity: String
        let mitigation: String
    }
}

print("=== Structured JSON Output ===\n")

let agent = Agent(
    name: "JSONAgent",
    instructions: """
    You return structured JSON responses.
    Always return valid JSON without markdown wrapping.
    """,
    tools: [.readFile],
    maxTurns: 5,
    model: ModelID("gpt-4o"),
    provider: provider,
    cwd: FileManager.default.currentDirectoryPath
)

let stream = Runner.runStream(
    agent: agent,
    prompt: """
    Assess this SDK repository for publish readiness. Do not execute commands.

    Return only valid JSON. Do not wrap the response in Markdown.
    Use this JSON schema:
    {
      "summary": "string",
      "risks": [
        {
          "title": "string",
          "severity": "low | medium | high",
          "mitigation": "string"
        }
      ]
    }
    If you cannot inspect the repository, still return a JSON object.
    Use summary to explain the limitation and set risks to an empty array.
    """
)

var jsonText = ""

do {
    for try await event in stream {
        switch event.type {
        case .content:
            if let data = event.data {
                print(data, terminator: "")
                fflush(stdout)
                jsonText += data
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
    print("\n✗ Error: \(error.localizedDescription)")
    exit(1)
}

print("\n\n--- Parsed JSON ---")
if let jsonData = jsonText.data(using: .utf8),
   let risk = try? JSONDecoder().decode(ReleaseRisk.self, from: jsonData) {
    print("Summary: \(risk.summary)")
    print("Risks found: \(risk.risks.count)")
    for r in risk.risks {
        print("  - [\(r.severity)] \(r.title): \(r.mitigation)")
    }
} else {
    print("Could not parse JSON from response")
}

print("\n✓ Structured JSON example complete")
