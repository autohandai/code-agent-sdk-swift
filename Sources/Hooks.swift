/// Hook system for lifecycle event interception.
/// Mirrors the TypeScript SDK HookManager.

import Foundation

// MARK: - Hook Events

public enum HookEvent: String, Sendable, CaseIterable {
    case sessionStart = "session-start"
    case sessionEnd = "session-end"
    case preClear = "pre-clear"
    case prePrompt = "pre-prompt"
    case preTool = "pre-tool"
    case postTool = "post-tool"
    case fileModified = "file-modified"
    case stop
    case subagentStop = "subagent-stop"
    case permissionRequest = "permission-request"
    case notification
    case sessionError = "session-error"
    case beforeExecution = "before-execution"
    case afterExecution = "after-execution"
    case onError = "on-error"
}

// MARK: - Hook Filter

public struct HookFilter: Sendable {
    public let tools: [String]?
    public let paths: [String]?

    public init(tools: [String]? = nil, paths: [String]? = nil) {
        self.tools = tools
        self.paths = paths
    }
}

// MARK: - Hook Definition

public struct HookDefinition: Sendable {
    public let event: HookEvent
    public let command: String
    public let description: String?
    public let enabled: Bool
    public let timeout: Int
    public let async: Bool
    public let matcher: String?
    public let filter: HookFilter?

    public init(
        event: HookEvent,
        command: String,
        description: String? = nil,
        enabled: Bool = true,
        timeout: Int = 5000,
        async: Bool = false,
        matcher: String? = nil,
        filter: HookFilter? = nil
    ) {
        self.event = event
        self.command = command
        self.description = description
        self.enabled = enabled
        self.timeout = timeout
        self.async = async
        self.matcher = matcher
        self.filter = filter
    }
}

// MARK: - Hook Context

public struct HookContext: Sendable {
    public let sessionID: String
    public let cwd: String
    public let hookEventName: HookEvent
    public let toolName: String?
    public let toolInput: [String: AnyCodable]?
    public let toolUseID: String?
    public let toolResponse: AnyCodable?
    public let toolSuccess: Bool?
    public let filePath: String?
    public let changeType: String?
    public let instruction: String?
    public let mentionedFiles: [String]?
    public let tokensUsed: Int?
    public let toolCallsCount: Int?
    public let turnToolCalls: Int?
    public let turnDuration: Int?
    public let duration: Int?
    public let error: String?
    public let errorCode: String?
    public let sessionType: String?
    public let sessionEndReason: String?
    public let subagentID: String?
    public let subagentName: String?
    public let subagentType: String?
    public let subagentSuccess: Bool?
    public let subagentError: String?
    public let subagentDuration: Int?
    public let permissionType: String?
    public let notificationType: String?
    public let notificationMessage: String?

    public init(
        sessionID: String,
        cwd: String,
        hookEventName: HookEvent,
        toolName: String? = nil,
        toolInput: [String: AnyCodable]? = nil,
        toolUseID: String? = nil,
        toolResponse: AnyCodable? = nil,
        toolSuccess: Bool? = nil,
        filePath: String? = nil,
        changeType: String? = nil,
        instruction: String? = nil,
        mentionedFiles: [String]? = nil,
        tokensUsed: Int? = nil,
        toolCallsCount: Int? = nil,
        turnToolCalls: Int? = nil,
        turnDuration: Int? = nil,
        duration: Int? = nil,
        error: String? = nil,
        errorCode: String? = nil,
        sessionType: String? = nil,
        sessionEndReason: String? = nil,
        subagentID: String? = nil,
        subagentName: String? = nil,
        subagentType: String? = nil,
        subagentSuccess: Bool? = nil,
        subagentError: String? = nil,
        subagentDuration: Int? = nil,
        permissionType: String? = nil,
        notificationType: String? = nil,
        notificationMessage: String? = nil
    ) {
        self.sessionID = sessionID
        self.cwd = cwd
        self.hookEventName = hookEventName
        self.toolName = toolName
        self.toolInput = toolInput
        self.toolUseID = toolUseID
        self.toolResponse = toolResponse
        self.toolSuccess = toolSuccess
        self.filePath = filePath
        self.changeType = changeType
        self.instruction = instruction
        self.mentionedFiles = mentionedFiles
        self.tokensUsed = tokensUsed
        self.toolCallsCount = toolCallsCount
        self.turnToolCalls = turnToolCalls
        self.turnDuration = turnDuration
        self.duration = duration
        self.error = error
        self.errorCode = errorCode
        self.sessionType = sessionType
        self.sessionEndReason = sessionEndReason
        self.subagentID = subagentID
        self.subagentName = subagentName
        self.subagentType = subagentType
        self.subagentSuccess = subagentSuccess
        self.subagentError = subagentError
        self.subagentDuration = subagentDuration
        self.permissionType = permissionType
        self.notificationType = notificationType
        self.notificationMessage = notificationMessage
    }
}

// MARK: - Hook Result

public struct HookResult: Sendable {
    public let success: Bool
    public let duration: Int
    public let stdout: String?
    public let stderr: String?
    public let error: String?

    public init(
        success: Bool,
        duration: Int,
        stdout: String? = nil,
        stderr: String? = nil,
        error: String? = nil
    ) {
        self.success = success
        self.duration = duration
        self.stdout = stdout
        self.stderr = stderr
        self.error = error
    }
}

// MARK: - Hook Manager

public final class HookManager: @unchecked Sendable {
    private var hooks: [HookEvent: [HookDefinition]] = [:]
    private var enabled = true
    private let lock = NSLock()

    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public var isEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return enabled
    }

    public func setEnabled(_ enabled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        self.enabled = enabled
    }

    public func addHook(_ hook: HookDefinition) {
        lock.lock()
        defer { lock.unlock() }
        hooks[hook.event, default: []].append(hook)
    }

    public func removeHook(event: HookEvent, index: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard var eventHooks = hooks[event], index < eventHooks.count else { return false }
        eventHooks.remove(at: index)
        hooks[event] = eventHooks
        return true
    }

    public func getHooks(for event: HookEvent) -> [HookDefinition] {
        lock.lock()
        defer { lock.unlock() }
        return hooks[event] ?? []
    }

    public func getAllHooks() -> [HookDefinition] {
        lock.lock()
        defer { lock.unlock() }
        return hooks.values.flatMap { $0 }
    }

    public func execute(event: HookEvent, context: HookContext) async throws {
        guard isEnabled else { return }

        let eventHooks = getHooks(for: event).filter { $0.enabled }

        for hook in eventHooks {
            if let matcher = hook.matcher {
                let target = getMatchTarget(event: event, context: context)
                if let target, target.range(of: matcher, options: .regularExpression) == nil {
                    continue
                }
            }

            let result = try await executeHook(hook, context)

            if let stdout = result.stdout,
               let data = stdout.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let decision = json["decision"] as? String,
               decision == "block" {
                throw AgentSDKError.executionFailed(
                    message: json["stopReason"] as? String ?? "Hook blocked execution"
                )
            }
        }
    }

    private func executeHook(_ hook: HookDefinition, _ context: HookContext) async throws -> HookResult {
        let startTime = Date()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", hook.command]

        var env = ProcessInfo.processInfo.environment
        env["HOOK_EVENT"] = hook.event.rawValue
        env["HOOK_WORKSPACE"] = context.cwd
        env["HOOK_SESSION_ID"] = context.sessionID
        process.environment = env

        if let workDir = context.cwd as String? {
            process.currentDirectoryURL = URL(fileURLWithPath: workDir)
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()

            if hook.async {
                return HookResult(success: true, duration: 0)
            }

            let timeoutNs = UInt64(hook.timeout) * 1_000_000
            let result = try await withThrowingTaskGroup(of: HookResult.self) { group in
                group.addTask {
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    return HookResult(
                        success: process.terminationStatus == 0,
                        duration: Int(Date().timeIntervalSince(startTime) * 1000),
                        stdout: output
                    )
                }

                group.addTask {
                    try await Task.sleep(nanoseconds: timeoutNs)
                    if process.isRunning {
                        process.terminate()
                    }
                    return HookResult(
                        success: false,
                        duration: Int(Date().timeIntervalSince(startTime) * 1000),
                        error: "Hook timed out after \(hook.timeout)ms"
                    )
                }

                let first = try await group.next()!
                group.cancelAll()
                return first
            }

            return result
        } catch {
            return HookResult(
                success: false,
                duration: Int(Date().timeIntervalSince(startTime) * 1000),
                error: error.localizedDescription
            )
        }
    }

    private func getMatchTarget(event: HookEvent, context: HookContext) -> String? {
        switch event {
        case .preTool, .postTool:
            return context.toolName
        case .fileModified:
            return context.filePath
        case .prePrompt:
            return context.instruction
        default:
            return nil
        }
    }
}
