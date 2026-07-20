/// Tool system: protocol, registry, and built-in tool implementations.
/// Mirrors the TypeScript SDK ToolDefinition + ToolRegistry pattern.

import Foundation

// MARK: - Tool Annotations

public enum ToolHint: String, Sendable {
    case readOnly
    case destructive
    case idempotent
    case openWorld
}

public struct ToolAnnotations: Sendable {
    public let readOnlyHint: Bool
    public let destructiveHint: Bool
    public let idempotentHint: Bool
    public let openWorldHint: Bool

    public init(
        readOnlyHint: Bool = false,
        destructiveHint: Bool = false,
        idempotentHint: Bool = false,
        openWorldHint: Bool = false
    ) {
        self.readOnlyHint = readOnlyHint
        self.destructiveHint = destructiveHint
        self.idempotentHint = idempotentHint
        self.openWorldHint = openWorldHint
    }
}

// MARK: - Tool Definition Protocol

public protocol ToolDefinition: Sendable {
    var name: String { get }
    var description: String { get }
    var annotations: ToolAnnotations { get }
    var parameters: [String: AnyCodable] { get }

    func execute(params: [String: AnyCodable]) async throws -> ToolResult
}

// MARK: - Tool Registry

public class ToolRegistry: @unchecked Sendable {
    private var tools: [String: ToolDefinition] = [:]
    private let lock = NSLock()

    public init() {}

    public func register(_ tool: ToolDefinition) {
        lock.lock()
        defer { lock.unlock() }
        tools[tool.name] = tool
    }

    public func execute(toolCall: ToolCall) async throws -> ToolResult {
        let tool = getTool(name: toolCall.name.rawValue)

        guard let tool else {
            return .failure(error: "Tool not found: \(toolCall.name.rawValue)")
        }

        return try await tool.execute(params: parameters(for: toolCall))
    }

    public func parameters(for toolCall: ToolCall) -> [String: AnyCodable] {
        guard let data = toolCall.arguments.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json.mapValues { AnyCodable($0) }
    }

    public func getTool(name: String) -> ToolDefinition? {
        lock.lock()
        defer { lock.unlock() }
        return tools[name]
    }

    public func getAllTools() -> [ToolDefinition] {
        lock.lock()
        defer { lock.unlock() }
        return Array(tools.values)
    }

    public func getSchemas() -> [ToolSchema] {
        lock.lock()
        defer { lock.unlock() }
        return tools.values.map { tool in
            ToolSchema(
                name: tool.name,
                description: tool.description,
                parameters: tool.parameters
            )
        }
    }
}

// MARK: - Default Tool Registry

public final class DefaultToolRegistry: ToolRegistry, @unchecked Sendable {
    public override init() {
        super.init()
        registerBuiltIns(allowedTools: nil)
    }

    /// Creates a registry containing only the tools explicitly enabled by an agent.
    public init(allowedTools: [ToolName]) {
        super.init()
        registerBuiltIns(allowedTools: Set(allowedTools.map(\.rawValue)))
    }

    public static func allToolNames() -> [ToolName] {
        let registry = DefaultToolRegistry()
        return registry.getAllTools().compactMap { ToolName(rawValue: $0.name) }
    }

    private func registerBuiltIns(allowedTools: Set<String>?) {
        let builtIns: [any ToolDefinition] = [
            ReadFileTool(),
            WriteFileTool(),
            EditFileTool(),
            BashTool(),
            WebSearchTool(),
            GitStatusTool(),
            GitDiffTool(),
            GitLogTool(),
            GitAddTool(),
            GitCommitTool(),
            GitPushTool(),
            GitPullTool(),
            GitBranchTool(),
            GitCheckoutTool(),
        ]
        for tool in builtIns where allowedTools?.contains(tool.name) ?? true {
            register(tool)
        }
    }
}

// MARK: - Read File Tool

public struct ReadFileTool: ToolDefinition {
    public let name = "read_file"
    public let description = "Read the contents of a file at the given path."
    public let annotations = ToolAnnotations(readOnlyHint: true, idempotentHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "file_path": ["type": "string", "description": "Path to the file to read"],
        ] as [String: Any]),
        "required": AnyCodable(["file_path"]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        guard let filePath = params["file_path"]?.value as? String else {
            return .failure(error: "Missing required parameter: file_path")
        }

        let path = (filePath as NSString).standardizingPath
        guard FileManager.default.fileExists(atPath: path) else {
            return .failure(error: "File not found: \(path)")
        }

        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            return .success(data: content)
        } catch {
            return .failure(error: "Failed to read file: \(error.localizedDescription)")
        }
    }
}

// MARK: - Write File Tool

public struct WriteFileTool: ToolDefinition {
    public let name = "write_file"
    public let description = "Write content to a file, creating it if it doesn't exist."
    public let annotations = ToolAnnotations(destructiveHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "file_path": ["type": "string", "description": "Path to the file to write"],
            "content": ["type": "string", "description": "Content to write to the file"],
        ] as [String: Any]),
        "required": AnyCodable(["file_path", "content"]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        guard let filePath = params["file_path"]?.value as? String else {
            return .failure(error: "Missing required parameter: file_path")
        }
        guard let content = params["content"]?.value as? String else {
            return .failure(error: "Missing required parameter: content")
        }

        let path = (filePath as NSString).standardizingPath
        let directory = (path as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)

        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            return .success(data: "File written successfully: \(path)")
        } catch {
            return .failure(error: "Failed to write file: \(error.localizedDescription)")
        }
    }
}

// MARK: - Edit File Tool

public struct EditFileTool: ToolDefinition {
    public let name = "edit_file"
    public let description = "Perform exact string replacements in an existing file."
    public let annotations = ToolAnnotations(destructiveHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "file_path": ["type": "string", "description": "Path to the file to edit"],
            "old_string": ["type": "string", "description": "Text to replace"],
            "new_string": ["type": "string", "description": "Replacement text"],
        ] as [String: Any]),
        "required": AnyCodable(["file_path", "old_string", "new_string"]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        guard let filePath = params["file_path"]?.value as? String else {
            return .failure(error: "Missing required parameter: file_path")
        }
        guard let oldString = params["old_string"]?.value as? String else {
            return .failure(error: "Missing required parameter: old_string")
        }
        guard let newString = params["new_string"]?.value as? String else {
            return .failure(error: "Missing required parameter: new_string")
        }

        let path = (filePath as NSString).standardizingPath
        guard FileManager.default.fileExists(atPath: path) else {
            return .failure(error: "File not found: \(path)")
        }

        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            guard let range = content.range(of: oldString) else {
                return .failure(error: "old_string not found in file")
            }
            let newContent = content.replacingCharacters(in: range, with: newString)
            try newContent.write(toFile: path, atomically: true, encoding: .utf8)
            return .success(data: "File edited successfully: \(path)")
        } catch {
            return .failure(error: "Failed to edit file: \(error.localizedDescription)")
        }
    }
}

// MARK: - Bash Tool

public struct BashTool: ToolDefinition {
    public let name = "bash"
    public let description = "Execute a shell command and return its output."
    public let annotations = ToolAnnotations(destructiveHint: true, openWorldHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "command": ["type": "string", "description": "Shell command to execute"],
            "work_dir": ["type": "string", "description": "Working directory for the command"],
        ] as [String: Any]),
        "required": AnyCodable(["command"]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        guard let command = params["command"]?.value as? String else {
            return .failure(error: "Missing required parameter: command")
        }

        let workDir = params["work_dir"]?.value as? String
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        if let workDir {
            process.currentDirectoryURL = URL(fileURLWithPath: workDir)
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                return .success(data: output)
            } else {
                return .failure(error: "Command exited with status \(process.terminationStatus): \(output)")
            }
        } catch {
            return .failure(error: "Failed to execute command: \(error.localizedDescription)")
        }
    }
}

// MARK: - Web Search Tool

public struct WebSearchTool: ToolDefinition {
    public let name = "web_search"
    public let description = "Search the web for information."
    public let annotations = ToolAnnotations(readOnlyHint: true, openWorldHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "query": ["type": "string", "description": "Search query"],
        ] as [String: Any]),
        "required": AnyCodable(["query"]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        guard let query = params["query"]?.value as? String else {
            return .failure(error: "Missing required parameter: query")
        }

        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.duckduckgo.com/?q=\(encodedQuery)&format=json&no_html=1") else {
            return .failure(error: "Failed to encode search query")
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let abstract = json["Abstract"] as? String, !abstract.isEmpty {
                return .success(data: abstract)
            }
            return .success(data: "No results found for query: \(query)")
        } catch {
            return .failure(error: "Web search failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Git Tools

public struct GitStatusTool: ToolDefinition {
    public let name = "git_status"
    public let description = "Show the working tree status."
    public let annotations = ToolAnnotations(readOnlyHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "work_dir": ["type": "string", "description": "Working directory"],
        ] as [String: Any]),
        "required": AnyCodable([]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        return try await runGitCommand(args: ["status", "--porcelain"], workDir: params["work_dir"]?.value as? String)
    }
}

public struct GitDiffTool: ToolDefinition {
    public let name = "git_diff"
    public let description = "Show changes between commits, commit and working tree, etc."
    public let annotations = ToolAnnotations(readOnlyHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "work_dir": ["type": "string", "description": "Working directory"],
        ] as [String: Any]),
        "required": AnyCodable([]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        return try await runGitCommand(args: ["diff"], workDir: params["work_dir"]?.value as? String)
    }
}

public struct GitLogTool: ToolDefinition {
    public let name = "git_log"
    public let description = "Show commit logs."
    public let annotations = ToolAnnotations(readOnlyHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "count": ["type": "number", "description": "Number of commits to show"],
            "work_dir": ["type": "string", "description": "Working directory"],
        ] as [String: Any]),
        "required": AnyCodable([]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        let count = params["count"]?.value as? Int ?? 10
        return try await runGitCommand(
            args: ["log", "--oneline", "-n", "\(count)"],
            workDir: params["work_dir"]?.value as? String
        )
    }
}

public struct GitAddTool: ToolDefinition {
    public let name = "git_add"
    public let description = "Add file contents to the index."
    public let annotations = ToolAnnotations(destructiveHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "files": ["type": "string", "description": "Files to add (space-separated or . for all)"],
            "work_dir": ["type": "string", "description": "Working directory"],
        ] as [String: Any]),
        "required": AnyCodable(["files"]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        guard let files = params["files"]?.value as? String else {
            return .failure(error: "Missing required parameter: files")
        }
        return try await runGitCommand(
            args: ["add"] + files.split(separator: " ").map(String.init),
            workDir: params["work_dir"]?.value as? String
        )
    }
}

public struct GitCommitTool: ToolDefinition {
    public let name = "git_commit"
    public let description = "Record changes to the repository."
    public let annotations = ToolAnnotations(destructiveHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "message": ["type": "string", "description": "Commit message"],
            "work_dir": ["type": "string", "description": "Working directory"],
        ] as [String: Any]),
        "required": AnyCodable(["message"]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        guard let message = params["message"]?.value as? String else {
            return .failure(error: "Missing required parameter: message")
        }
        return try await runGitCommand(
            args: ["commit", "-m", message],
            workDir: params["work_dir"]?.value as? String
        )
    }
}

public struct GitPushTool: ToolDefinition {
    public let name = "git_push"
    public let description = "Update remote refs along with associated objects."
    public let annotations = ToolAnnotations(destructiveHint: true, openWorldHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "work_dir": ["type": "string", "description": "Working directory"],
        ] as [String: Any]),
        "required": AnyCodable([]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        return try await runGitCommand(args: ["push"], workDir: params["work_dir"]?.value as? String)
    }
}

public struct GitPullTool: ToolDefinition {
    public let name = "git_pull"
    public let description = "Fetch from and integrate with another repository."
    public let annotations = ToolAnnotations(destructiveHint: true, openWorldHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "work_dir": ["type": "string", "description": "Working directory"],
        ] as [String: Any]),
        "required": AnyCodable([]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        return try await runGitCommand(args: ["pull"], workDir: params["work_dir"]?.value as? String)
    }
}

public struct GitBranchTool: ToolDefinition {
    public let name = "git_branch"
    public let description = "List, create, or delete branches."
    public let annotations = ToolAnnotations(readOnlyHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "work_dir": ["type": "string", "description": "Working directory"],
        ] as [String: Any]),
        "required": AnyCodable([]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        return try await runGitCommand(args: ["branch", "-a"], workDir: params["work_dir"]?.value as? String)
    }
}

public struct GitCheckoutTool: ToolDefinition {
    public let name = "git_checkout"
    public let description = "Switch branches or restore working tree files."
    public let annotations = ToolAnnotations(destructiveHint: true)
    public let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "branch": ["type": "string", "description": "Branch to checkout"],
            "work_dir": ["type": "string", "description": "Working directory"],
        ] as [String: Any]),
        "required": AnyCodable(["branch"]),
    ]

    public func execute(params: [String: AnyCodable]) async throws -> ToolResult {
        guard let branch = params["branch"]?.value as? String else {
            return .failure(error: "Missing required parameter: branch")
        }
        return try await runGitCommand(args: ["checkout", branch], workDir: params["work_dir"]?.value as? String)
    }
}

// MARK: - Git Helper

private func runGitCommand(args: [String], workDir: String?) async throws -> ToolResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = args
    if let workDir {
        process.currentDirectoryURL = URL(fileURLWithPath: workDir)
    }

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus == 0 {
            return .success(data: output.isEmpty ? "Success" : output)
        } else {
            return .failure(error: output.isEmpty ? "Git command failed" : output)
        }
    } catch {
        return .failure(error: "Failed to run git command: \(error.localizedDescription)")
    }
}
