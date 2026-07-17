/// Core types for the AgentSDK.
/// Mirrors the TypeScript Agent SDK type system with Swift-native idioms.

import Foundation

// MARK: - Branded Types

public struct ToolCallID: Hashable, Sendable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

public struct SessionID: Hashable, Sendable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

public struct ModelID: Hashable, Sendable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

// MARK: - Tool Names

public enum ToolName: String, Sendable, CaseIterable, Codable {
    case readFile = "read_file"
    case writeFile = "write_file"
    case editFile = "edit_file"
    case applyPatch = "apply_patch"
    case find = "find"
    case glob = "glob"
    case searchInFiles = "search_in_files"
    case bash = "bash"
    case gitStatus = "git_status"
    case gitDiff = "git_diff"
    case gitLog = "git_log"
    case gitCommit = "git_commit"
    case gitAdd = "git_add"
    case gitReset = "git_reset"
    case gitPush = "git_push"
    case gitPull = "git_pull"
    case gitFetch = "git_fetch"
    case gitCheckout = "git_checkout"
    case gitBranch = "git_branch"
    case gitMerge = "git_merge"
    case gitRebase = "git_rebase"
    case gitStash = "git_stash"
    case webSearch = "web_search"
    case notebookRead = "notebook_read"
    case notebookEdit = "notebook_edit"
    case readPackageManifest = "read_package_manifest"
    case addDependency = "add_dependency"
    case removeDependency = "remove_dependency"
    case formatFile = "format_file"
    case formatDirectory = "format_directory"
    case listFormatters = "list_formatters"
    case checkFormatting = "check_formatting"
    case lintFile = "lint_file"
    case lintDirectory = "lint_directory"
    case listLinters = "list_linters"
}

// MARK: - Permission Mode

public enum PermissionMode: String, Sendable, Codable {
    case yolo
    case ask
    case deny
}

// MARK: - Tool Call

public struct ToolCall: Sendable, Codable {
    public let id: String
    public let name: ToolName
    public let arguments: String

    public init(id: String, name: ToolName, arguments: String) {
        self.id = id
        self.name = name
        self.arguments = arguments
    }
}

// MARK: - Messages

public enum MessageRole: String, Sendable, Codable {
    case user
    case assistant
    case system
    case tool
}

public enum Message: Sendable, Codable {
    case user(UserMessage)
    case assistant(AssistantMessage)
    case system(SystemMessage)
    case tool(ToolMessage)

    public var role: MessageRole {
        switch self {
        case .user: return .user
        case .assistant: return .assistant
        case .system: return .system
        case .tool: return .tool
        }
    }

    public var content: String {
        switch self {
        case .user(let m): return m.content
        case .assistant(let m): return m.content
        case .system(let m): return m.content
        case .tool(let m): return m.content
        }
    }
}

public struct UserMessage: Sendable, Codable {
    public let role: MessageRole = .user
    public let content: String

    public init(content: String) {
        self.content = content
    }

    enum CodingKeys: String, CodingKey { case role, content }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(String.self, forKey: .content)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
    }
}

public struct AssistantMessage: Sendable, Codable {
    public let role: MessageRole = .assistant
    public let content: String
    public let toolCalls: [ToolCall]?

    public init(content: String, toolCalls: [ToolCall]? = nil) {
        self.content = content
        self.toolCalls = toolCalls
    }

    enum CodingKeys: String, CodingKey { case role, content, toolCalls }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(String.self, forKey: .content)
        toolCalls = try container.decodeIfPresent([ToolCall].self, forKey: .toolCalls)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(toolCalls, forKey: .toolCalls)
    }
}

public struct SystemMessage: Sendable, Codable {
    public let role: MessageRole = .system
    public let content: String

    public init(content: String) {
        self.content = content
    }

    enum CodingKeys: String, CodingKey { case role, content }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(String.self, forKey: .content)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
    }
}

public struct ToolMessage: Sendable, Codable {
    public let role: MessageRole = .tool
    public let content: String
    public let toolCallID: String
    public let toolName: ToolName?

    public init(content: String, toolCallID: String, toolName: ToolName? = nil) {
        self.content = content
        self.toolCallID = toolCallID
        self.toolName = toolName
    }

    enum CodingKeys: String, CodingKey {
        case role, content, toolName
        case toolCallID = "tool_call_id"
    }
}

// MARK: - Tool Schema

public struct ToolSchema: Sendable, Codable {
    public let name: String
    public let description: String
    public let parameters: [String: AnyCodable]

    public init(name: String, description: String, parameters: [String: AnyCodable]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

// MARK: - Tool Result

public enum ToolResult: Sendable {
    case success(data: String, metadata: [String: AnyCodable]? = nil)
    case failure(error: String, metadata: [String: AnyCodable]? = nil)

    public var data: String? {
        if case .success(let data, _) = self { return data }
        return nil
    }

    public var error: String? {
        if case .failure(let error, _) = self { return error }
        return nil
    }
}

// MARK: - Session

public struct Session: Sendable, Codable {
    public let id: SessionID
    public var messages: [Message]
    public let workingDirectory: String
    public let createdAt: Date

    public init(
        id: SessionID,
        messages: [Message] = [],
        workingDirectory: String = FileManager.default.currentDirectoryPath,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.messages = messages
        self.workingDirectory = workingDirectory
        self.createdAt = createdAt
    }
}

// MARK: - Run Result

public enum RunResult: Sendable {
    case success(finalOutput: String, session: Session, turns: Int)
    case maxTurnsReached(session: Session, turns: Int)

    public var finalOutput: String {
        switch self {
        case .success(let output, _, _): return output
        case .maxTurnsReached: return "Max turns reached"
        }
    }

    public var session: Session {
        switch self {
        case .success(_, let session, _): return session
        case .maxTurnsReached(let session, _): return session
        }
    }

    public var turns: Int {
        switch self {
        case .success(_, _, let turns): return turns
        case .maxTurnsReached(_, let turns): return turns
        }
    }
}

// MARK: - Chat Response

public struct ChatResponse: Sendable, Codable {
    public let id: String
    public let content: String
    public let toolCalls: [ToolCall]?
    public let finishReason: String?
    public let usage: [String: Int]?

    public init(
        id: String,
        content: String,
        toolCalls: [ToolCall]? = nil,
        finishReason: String? = nil,
        usage: [String: Int]? = nil
    ) {
        self.id = id
        self.content = content
        self.toolCalls = toolCalls
        self.finishReason = finishReason
        self.usage = usage
    }
}

// MARK: - Stream Event

public enum StreamEventType: String, Sendable, Codable {
    case content
    case toolCall = "tool_call"
    case toolResult = "tool_result"
    case toolError = "tool_error"
    case done
}

public struct StreamEvent: Sendable {
    public let type: StreamEventType
    public let data: String?
    public let tool: ToolName?
    public let toolID: String?

    public init(
        type: StreamEventType,
        data: String? = nil,
        tool: ToolName? = nil,
        toolID: String? = nil
    ) {
        self.type = type
        self.data = data
        self.tool = tool
        self.toolID = toolID
    }
}

// MARK: - AnyCodable

public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            value = NSNull()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map(AnyCodable.init))
        case let dict as [String: Any]:
            try container.encode(dict.mapValues(AnyCodable.init))
        default:
            try container.encodeNil()
        }
    }
}
