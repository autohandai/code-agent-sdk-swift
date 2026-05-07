import Testing
import Foundation
@testable import AgentSDK

@Suite struct ErrorsTests {

    @Test func timeoutError() {
        let error = AgentSDKError.timeout(message: "Request timed out", timeoutMs: 5000)
        #expect(error.code == "TIMEOUT")
        #expect(error.isRetryable == true)
        #expect(error.errorDescription?.contains("TIMEOUT") == true)
    }

    @Test func validationError() {
        let error = AgentSDKError.validation(message: "Invalid input", field: "name", value: nil)
        #expect(error.code == "VALIDATION")
        #expect(error.isRetryable == false)
    }

    @Test func providerErrorRetryable() {
        let error429 = AgentSDKError.provider(
            message: "Rate limited",
            providerName: "openai",
            context: ["statusCode": AnyCodable(429)]
        )
        #expect(error429.isRetryable == true)

        let error500 = AgentSDKError.provider(
            message: "Server error",
            providerName: "openai",
            context: ["statusCode": AnyCodable(500)]
        )
        #expect(error500.isRetryable == true)

        let error400 = AgentSDKError.provider(
            message: "Bad request",
            providerName: "openai",
            context: ["statusCode": AnyCodable(400)]
        )
        #expect(error400.isRetryable == false)
    }

    @Test func toolExecutionError() {
        let error = AgentSDKError.toolExecution(
            message: "Tool failed",
            toolName: "read_file"
        )
        #expect(error.code == "TOOL_EXECUTION")
        #expect(error.isRetryable == false)
    }

    @Test func agentConfigError() {
        let error = AgentSDKError.agentConfig(message: "Invalid config")
        #expect(error.code == "AGENT_CONFIG")
    }

    @Test func notFoundError() {
        let error = AgentSDKError.notFound(
            message: "Not found",
            resourceType: "file",
            resourceID: "/tmp/test.txt"
        )
        #expect(error.code == "NOT_FOUND")
    }

    @Test func executionFailedError() {
        let error = AgentSDKError.executionFailed(message: "Max turns exceeded")
        #expect(error.code == "EXECUTION_FAILED")
    }
}
