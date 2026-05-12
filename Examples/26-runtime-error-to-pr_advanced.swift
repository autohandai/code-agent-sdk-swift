/// Example 26 Advanced: Runtime Error to Pull Request
/// Build a production incident packet and ask Autohand to create a verified PR.
///
/// Required:
///   AUTOHAND_TARGET_REPO=/path/to/app
///   GITHUB_TOKEN or GH_TOKEN with repo scope

import AgentSDK
import Foundation

struct GitHubCredentials {
    let tokenEnvName: String
    let remote: String
    let baseBranch: String
    let repository: String?
}

struct IncidentPacket: Codable {
    let id: String
    let severity: String
    let service: String
    let firstSeen: String
    let release: String
    let errorSignature: String
    let userImpact: String
    let stackTrace: String
    let logs: [String]
    let request: [String: String]
    let suspectedFiles: [String]
    let reproductionCommand: String
    let validationCommands: [String]
}

func githubCredentialsFromEnv() throws -> GitHubCredentials {
    let env = ProcessInfo.processInfo.environment
    let tokenEnvName: String
    if let token = env["GITHUB_TOKEN"], !token.isEmpty {
        tokenEnvName = "GITHUB_TOKEN"
    } else if let token = env["GH_TOKEN"], !token.isEmpty {
        tokenEnvName = "GH_TOKEN"
    } else {
        throw NSError(domain: "GitHubCredentials", code: 1, userInfo: [NSLocalizedDescriptionKey: "Set GITHUB_TOKEN or GH_TOKEN before running this example."])
    }

    return GitHubCredentials(
        tokenEnvName: tokenEnvName,
        remote: env["AUTOHAND_GITHUB_REMOTE"] ?? "origin",
        baseBranch: env["AUTOHAND_GITHUB_BASE_BRANCH"] ?? "main",
        repository: env["GITHUB_REPOSITORY"]
    )
}

func captureIncidentPacket() -> IncidentPacket {
    IncidentPacket(
        id: "INC-2026-05-12-0417",
        severity: "sev2",
        service: "checkout-api",
        firstSeen: "2026-05-12T09:14:22Z",
        release: "checkout-api@2026.05.12.3",
        errorSignature: "RuntimeError: checkout discount failed while replaying coupon idempotency key",
        userImpact: "Checkout returns HTTP 500 for guest customers using coupon replay from mobile clients.",
        stackTrace: """
        RuntimeError: checkout discount failed while replaying coupon idempotency key
            at CheckoutDiscounts.calculateDiscount(Discounts.swift:42)
            at PaymentIntent.buildPaymentIntent(PaymentIntent.swift:118)
            at CheckoutSession.createCheckoutSession(Session.swift:88)
        """,
        logs: [
            "level=error trace=trk_94 request_id=req_7f2 route=POST /checkout status=500 duration_ms=184",
            "level=warn trace=trk_94 idempotency_key=checkout:cart_live_9834:attempt_2 cache_status=miss",
            "level=info trace=trk_94 feature_flags=discount-v2,coupon-replay",
        ],
        request: [
            "method": "POST",
            "path": "/checkout",
            "payload": #"{"cartId":"cart_live_9834","subtotal":129,"customer":null,"coupon":{"code":"SPRING25","source":"mobile-v5"},"idempotencyKey":"checkout:cart_live_9834:attempt_2"}"#,
            "x-client-version": "ios/5.18.0",
            "x-request-id": "req_7f2",
        ],
        suspectedFiles: [
            "Sources/Checkout/Discounts.swift",
            "Sources/Checkout/PaymentIntent.swift",
            "Sources/Checkout/Session.swift",
            "Tests/CheckoutTests/SessionTests.swift",
        ],
        reproductionCommand: "swift test --filter CheckoutTests/testGuestCouponReplay",
        validationCommands: [
            "swift test --filter CheckoutTests/testGuestCouponReplay",
            "swift test",
            "swift build",
        ]
    )
}

func buildPrompt(incident: IncidentPacket, github: GitHubCredentials) throws -> String {
    let data = try JSONEncoder().encode(incident)
    let incidentJSON = String(data: data, encoding: .utf8) ?? "{}"
    let repoHint = github.repository.map { "- GitHub repository hint: \($0)." } ?? "- Discover the GitHub repository from git remote output."

    return """
    You are a senior QA engineering agent responsible for converting production incidents into verified repair pull requests.

    GitHub credentials:
    - A GitHub token is available in the \(github.tokenEnvName) environment variable. Do not print or commit the token.
    - Use git remote \(github.remote).
    - Open the pull request against \(github.baseBranch).
    \(repoHint)
    - Before pushing, run gh auth status or an equivalent non-secret auth check.

    Incident packet:
    ```json
    \(incidentJSON)
    ```

    Required workflow:
    1. Inspect the target repository and confirm the likely failing path.
    2. Reproduce the incident using the provided payload or nearest existing test harness.
    3. Fix the root cause, not just the thrown exception.
    4. Add a regression test covering guest checkout, coupon replay, and idempotency behavior.
    5. Run the focused test first, then the relevant validation commands.
    6. Create a branch named autohand/fix-checkout-incident-inc-2026-05-12-0417.
    7. Commit the fix with a clear message.
    8. Push the branch and open a pull request.
    9. In the PR body, include the incident id, error signature, files changed, tests run, and any residual risk.
    """
}

let env = ProcessInfo.processInfo.environment
let targetRepo = env["AUTOHAND_TARGET_REPO"] ?? FileManager.default.currentDirectoryPath
let github = try githubCredentialsFromEnv()
let prompt = try buildPrompt(incident: captureIncidentPacket(), github: github)
let apiKey = env["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)

let agent = Agent(
    name: "AdvancedRuntimeErrorRepairAgent",
    instructions: "Work like a careful senior QA engineer. Keep secrets out of logs and pull request text.",
    tools: [.bash, .readFile, .writeFile],
    maxTurns: 18,
    model: ModelID(env["AUTOHAND_MODEL"] ?? "gpt-4o"),
    provider: provider,
    cwd: targetRepo
)

let stream = Runner.runStream(agent: agent, prompt: prompt)

do {
    for try await event in stream {
        switch event.type {
        case .content:
            if let data = event.data {
                print(data, terminator: "")
                fflush(stdout)
            }
        case .toolCall:
            print("\n[tool] \(event.tool?.rawValue ?? "")")
        case .toolError:
            print("\n[tool error] \(event.tool?.rawValue ?? "")")
        case .done:
            break
        default:
            break
        }
    }
} catch {
    print("\nError: \(error.localizedDescription)")
    exit(1)
}
