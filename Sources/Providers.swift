/// LLM Provider protocol and implementations.
/// All providers use raw HTTP — no external SDK dependencies.

import Foundation

// MARK: - Provider Options

public struct ProviderOptions: Sendable {
    public let timeout: TimeInterval
    public let maxRetries: Int
    public let maxTokens: Int?
    public let temperature: Double?

    public init(
        timeout: TimeInterval = 30,
        maxRetries: Int = 3,
        maxTokens: Int? = nil,
        temperature: Double? = nil
    ) {
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}

// MARK: - Chat Chunk

public struct ChatChunk: Sendable {
    public let content: String
    public let toolCalls: [ToolCall]?
    public let finishReason: String?

    public init(content: String, toolCalls: [ToolCall]? = nil, finishReason: String? = nil) {
        self.content = content
        self.toolCalls = toolCalls
        self.finishReason = finishReason
    }
}

// MARK: - Provider Protocol

public protocol Provider: Sendable {
    func modelName(_ model: String) -> String

    func chat(
        messages: [Message],
        model: String,
        tools: [ToolSchema]?,
        options: ProviderOptions?
    ) async throws -> ChatResponse

    func chatStream(
        messages: [Message],
        model: String,
        tools: [ToolSchema]?,
        options: ProviderOptions?
    ) -> AsyncThrowingStream<ChatChunk, Error>
}

// MARK: - OpenAI Provider

public final class OpenAIProvider: Provider, @unchecked Sendable {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession

    public init(apiKey: String, baseURL: URL = URL(string: "https://api.openai.com/v1")!) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    public func modelName(_ model: String) -> String {
        return model
    }

    public func chat(
        messages: [Message],
        model: String,
        tools: [ToolSchema]? = nil,
        options: ProviderOptions? = nil
    ) async throws -> ChatResponse {
        let opts = options ?? ProviderOptions()
        let request = try buildRequest(
            messages: messages,
            model: model,
            tools: tools,
            options: opts,
            stream: false
        )

        return try await executeWithRetry(request: request, maxRetries: opts.maxRetries)
    }

    public func chatStream(
        messages: [Message],
        model: String,
        tools: [ToolSchema]? = nil,
        options: ProviderOptions? = nil
    ) -> AsyncThrowingStream<ChatChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let opts = options ?? ProviderOptions()
                    let request = try buildRequest(
                        messages: messages,
                        model: model,
                        tools: tools,
                        options: opts,
                        stream: true
                    )

                    let (bytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw AgentSDKError.provider(
                            message: "Invalid response type",
                            providerName: "openai"
                        )
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw AgentSDKError.provider(
                            message: "HTTP \(httpResponse.statusCode)",
                            providerName: "openai",
                            context: ["statusCode": AnyCodable(httpResponse.statusCode)]
                        )
                    }

                    var buffer = ""
                    var accumulatedToolCalls: [String: ToolCall] = [:]
                    var accumulatedArgs: [String: String] = [:]

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let dataStr = String(line.dropFirst(6))
                        guard dataStr != "[DONE]" else { break }
                        guard let data = dataStr.data(using: .utf8) else { continue }

                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let choice = choices.first,
                           let delta = choice["delta"] as? [String: Any] {

                            var content = ""
                            if let deltaContent = delta["content"] as? String {
                                content = deltaContent
                            }

                            var toolCalls: [ToolCall]? = nil
                            if let deltaToolCalls = delta["tool_calls"] as? [[String: Any]] {
                                for tc in deltaToolCalls {
                                    let index = tc["index"] as? Int ?? 0
                                    let key = "\(index)"
                                    if let id = tc["id"] as? String {
                                        accumulatedToolCalls[key] = ToolCall(
                                            id: id,
                                            name: .bash,
                                            arguments: ""
                                        )
                                    }
                                    if let function = tc["function"] as? [String: Any] {
                                        if let name = function["name"] as? String {
                                            if let existing = accumulatedToolCalls[key] {
                                                if let toolName = ToolName(rawValue: name) {
                                                    accumulatedToolCalls[key] = ToolCall(
                                                        id: existing.id,
                                                        name: toolName,
                                                        arguments: existing.arguments
                                                    )
                                                }
                                            }
                                        }
                                        if let args = function["arguments"] as? String {
                                            accumulatedArgs[key] = (accumulatedArgs[key] ?? "") + args
                                            if let existing = accumulatedToolCalls[key] {
                                                accumulatedToolCalls[key] = ToolCall(
                                                    id: existing.id,
                                                    name: existing.name,
                                                    arguments: accumulatedArgs[key] ?? ""
                                                )
                                            }
                                        }
                                    }
                                }
                                toolCalls = Array(accumulatedToolCalls.values)
                            }

                            let finishReason = choice["finish_reason"] as? String
                            continuation.yield(ChatChunk(
                                content: content,
                                toolCalls: toolCalls,
                                finishReason: finishReason
                            ))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    private func buildRequest(
        messages: [Message],
        model: String,
        tools: [ToolSchema]?,
        options: ProviderOptions,
        stream: Bool
    ) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = options.timeout

        var body: [String: Any] = [
            "model": model,
            "messages": messages.map(encodeMessage),
            "stream": stream,
        ]

        if let maxTokens = options.maxTokens {
            body["max_tokens"] = maxTokens
        }
        if let temperature = options.temperature {
            body["temperature"] = temperature
        }
        if let tools = tools, !tools.isEmpty {
            body["tools"] = tools.map(encodeToolSchema)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func encodeMessage(_ message: Message) -> [String: Any] {
        switch message {
        case .user(let m):
            return ["role": "user", "content": m.content]
        case .assistant(let m):
            var dict: [String: Any] = ["role": "assistant", "content": m.content]
            if let toolCalls = m.toolCalls {
                dict["tool_calls"] = toolCalls.map { tc in
                    [
                        "id": tc.id,
                        "type": "function",
                        "function": [
                            "name": tc.name.rawValue,
                            "arguments": tc.arguments,
                        ],
                    ] as [String: Any]
                }
            }
            return dict
        case .system(let m):
            return ["role": "system", "content": m.content]
        case .tool(let m):
            return [
                "role": "tool",
                "content": m.content,
                "tool_call_id": m.toolCallID,
            ]
        }
    }

    private func encodeToolSchema(_ schema: ToolSchema) -> [String: Any] {
        [
            "type": "function",
            "function": [
                "name": schema.name,
                "description": schema.description,
                "parameters": schema.parameters.mapValues { $0.value },
            ],
        ]
    }

    private func executeWithRetry(
        request: URLRequest,
        maxRetries: Int
    ) async throws -> ChatResponse {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AgentSDKError.provider(
                        message: "Invalid response type",
                        providerName: "openai"
                    )
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    let error = AgentSDKError.provider(
                        message: "HTTP \(httpResponse.statusCode)",
                        providerName: "openai",
                        context: ["statusCode": AnyCodable(httpResponse.statusCode)]
                    )
                    if error.isRetryable && attempt < maxRetries {
                        lastError = error
                        try await Task.sleep(for: .milliseconds(min(1000 * Int(pow(2.0, Double(attempt))), 10000)))
                        continue
                    }
                    throw error
                }

                return try parseResponse(data: data)
            } catch {
                if attempt < maxRetries {
                    lastError = error
                    try await Task.sleep(for: .milliseconds(min(1000 * Int(pow(2.0, Double(attempt))), 10000)))
                    continue
                }
                throw error
            }
        }

        throw AgentSDKError.retryExhausted(
            message: "All retry attempts exhausted",
            attempts: maxRetries,
            lastError: lastError ?? AgentSDKError.provider(
                message: "Unknown error",
                providerName: "openai"
            )
        )
    }

    private func parseResponse(data: Data) throws -> ChatResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AgentSDKError.provider(
                message: "Failed to parse response JSON",
                providerName: "openai"
            )
        }

        let id = json["id"] as? String ?? UUID().uuidString
        let choices = json["choices"] as? [[String: Any]]
        let choice = choices?.first
        let message = choice?["message"] as? [String: Any]
        let content = message?["content"] as? String ?? ""
        let finishReason = choice?["finish_reason"] as? String

        var toolCalls: [ToolCall]? = nil
        if let rawToolCalls = message?["tool_calls"] as? [[String: Any]] {
            toolCalls = rawToolCalls.compactMap { tc in
                guard let id = tc["id"] as? String,
                      let function = tc["function"] as? [String: Any],
                      let name = function["name"] as? String,
                      let toolName = ToolName(rawValue: name),
                      let args = function["arguments"] as? String
                else { return nil }
                return ToolCall(id: id, name: toolName, arguments: args)
            }
        }

        var usage: [String: Int]? = nil
        if let rawUsage = json["usage"] as? [String: Any] {
            usage = rawUsage.compactMapValues { $0 as? Int }
        }

        return ChatResponse(
            id: id,
            content: content,
            toolCalls: toolCalls,
            finishReason: finishReason,
            usage: usage
        )
    }
}

// MARK: - Provider Factory

public enum ProviderFactory {
    public static func create(providerName: String, apiKey: String, baseURL: URL? = nil) throws -> Provider {
        switch providerName {
        case "openai":
            return OpenAIProvider(apiKey: apiKey, baseURL: baseURL ?? URL(string: "https://api.openai.com/v1")!)
        case "openrouter":
            return OpenAIProvider(
                apiKey: apiKey,
                baseURL: baseURL ?? URL(string: "https://openrouter.ai/api/v1")!
            )
        default:
            throw AgentSDKError.provider(
                message: "Unknown provider: \(providerName)",
                providerName: providerName
            )
        }
    }
}
