/// Structured error hierarchy for AgentSDK.
/// Mirrors the TypeScript SDK error system with Swift-native idioms.

import Foundation

// MARK: - Base Error

public enum AgentSDKError: Error, LocalizedError, Sendable {
    case timeout(message: String, timeoutMs: Int, context: [String: AnyCodable]? = nil)
    case retryExhausted(message: String, attempts: Int, lastError: Error)
    case validation(message: String, field: String?, value: AnyCodable?)
    case provider(message: String, providerName: String, context: [String: AnyCodable]? = nil)
    case toolExecution(message: String, toolName: String, context: [String: AnyCodable]? = nil)
    case agentConfig(message: String)
    case notFound(message: String, resourceType: String, resourceID: String)
    case executionFailed(message: String, context: [String: AnyCodable]? = nil)

    public var errorDescription: String? {
        switch self {
        case .timeout(let message, _, _): return "[TIMEOUT] \(message)"
        case .retryExhausted(let message, _, _): return "[RETRY_EXHAUSTED] \(message)"
        case .validation(let message, _, _): return "[VALIDATION] \(message)"
        case .provider(let message, _, _): return "[PROVIDER_ERROR] \(message)"
        case .toolExecution(let message, _, _): return "[TOOL_EXECUTION] \(message)"
        case .agentConfig(let message): return "[AGENT_CONFIG] \(message)"
        case .notFound(let message, _, _): return "[NOT_FOUND] \(message)"
        case .executionFailed(let message, _): return "[EXECUTION_FAILED] \(message)"
        }
    }

    public var code: String {
        switch self {
        case .timeout: return "TIMEOUT"
        case .retryExhausted: return "RETRY_EXHAUSTED"
        case .validation: return "VALIDATION"
        case .provider: return "PROVIDER_ERROR"
        case .toolExecution: return "TOOL_EXECUTION"
        case .agentConfig: return "AGENT_CONFIG"
        case .notFound: return "NOT_FOUND"
        case .executionFailed: return "EXECUTION_FAILED"
        }
    }

    public var isRetryable: Bool {
        switch self {
        case .timeout:
            return true
        case .provider(_, _, let context):
            if let statusCode = context?["statusCode"]?.value as? Int {
                return statusCode == 408 || statusCode == 429 || statusCode >= 500
            }
            return true
        default:
            return false
        }
    }
}
