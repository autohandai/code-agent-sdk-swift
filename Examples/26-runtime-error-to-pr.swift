/// Example 26: Runtime Error to Pull Request
/// Capture an application runtime error and ask Autohand to create a repair PR.
///
/// Run: AUTOHAND_TARGET_REPO=/path/to/app swift Examples/26-runtime-error-to-pr.swift

import AgentSDK
import Foundation

struct Cart {
    let subtotal: Double
    let customer: Customer?
}

struct Customer {
    let loyaltyTier: String
}

func checkoutDiscount(_ cart: Cart) throws -> Double {
    do {
        guard let customer = cart.customer else {
            throw NSError(
                domain: "CheckoutDiscount",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "missing customer"]
            )
        }
        if customer.loyaltyTier == "gold" {
            return cart.subtotal * 0.15
        }
        return cart.subtotal * 0.05
    } catch {
        throw NSError(
            domain: "CheckoutDiscount",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "checkout discount failed: \(error.localizedDescription)"]
        )
    }
}

func captureRuntimeError() -> String {
    do {
        _ = try checkoutDiscount(Cart(subtotal: 129, customer: nil))
    } catch {
        return "\(error)"
    }

    return """
    RuntimeError: checkout discount failed: missing customer
        at CheckoutDiscounts.checkoutDiscount(Discounts.swift:42)
        at CheckoutSession.createCheckoutSession(Session.swift:88)
    Request: POST /checkout
    Payload: {"subtotal":129,"customer":null}
    """
}

let targetRepo = ProcessInfo.processInfo.environment["AUTOHAND_TARGET_REPO"] ?? FileManager.default.currentDirectoryPath
let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "sk-..."
let provider = OpenAIProvider(apiKey: apiKey)
let capturedError = captureRuntimeError()

let agent = Agent(
    name: "RuntimeErrorRepairAgent",
    instructions: """
    You are a QA engineering agent that turns production error reports into small repair pull requests.
    Reproduce the failure when the repository makes that possible.
    Fix the root cause, add or update a focused regression test, run the relevant validation command, commit the fix, push a branch, and create a pull request.
    Keep the pull request description concise and include the error signature, the fix summary, and the validation result.
    """,
    tools: [.bash, .readFile, .writeFile],
    maxTurns: 14,
    model: ModelID(ProcessInfo.processInfo.environment["AUTOHAND_MODEL"] ?? "gpt-4o"),
    provider: provider,
    cwd: targetRepo
)

print("=== Runtime Error to Pull Request ===\n")

let stream = Runner.runStream(
    agent: agent,
    prompt: """
    A runtime error was captured by the application error boundary.
    Use this error report to repair the application automatically.

    Captured error:
    ```text
    \(capturedError)
    ```

    Expected user impact:
    A checkout session should still calculate a safe default discount when the customer object is missing.

    Please create a pull request with the fix.
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

print("\nRuntime error repair request complete.")
