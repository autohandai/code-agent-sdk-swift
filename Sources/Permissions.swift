/// Permission system for tool access control.
/// Mirrors the TypeScript SDK PermissionManager.

import Foundation

// MARK: - Permission Decision

public enum PermissionDecision: String, Sendable {
    case allow
    case deny
    case ask
    case block
}

// MARK: - Permission Request

public struct PermissionRequest: Sendable {
    public let tool: ToolName
    public let args: [String: AnyCodable]
    public let path: String?
    public let command: String?

    public init(
        tool: ToolName,
        args: [String: AnyCodable] = [:],
        path: String? = nil,
        command: String? = nil
    ) {
        self.tool = tool
        self.args = args
        self.path = path
        self.command = command
    }
}

// MARK: - Permission Result

public struct PermissionResult: Sendable {
    public let decision: PermissionDecision
    public let reason: String?
    public let `continue`: Bool

    public init(decision: PermissionDecision, reason: String? = nil, continue: Bool) {
        self.decision = decision
        self.reason = reason
        self.continue = `continue`
    }
}

// MARK: - Permission Manager

public final class PermissionManager: @unchecked Sendable {
    private let hookManager: HookManager
    private var mode: PermissionMode
    private let lock = NSLock()

    public init(hookManager: HookManager, mode: PermissionMode = .ask) {
        self.hookManager = hookManager
        self.mode = mode
    }

    public var permissionMode: PermissionMode {
        lock.lock()
        defer { lock.unlock() }
        return mode
    }

    public func setPermissionMode(_ mode: PermissionMode) {
        lock.lock()
        defer { lock.unlock() }
        self.mode = mode
    }

    public func requestPermission(_ request: PermissionRequest) async -> PermissionResult {
        switch permissionMode {
        case .yolo:
            return PermissionResult(decision: .allow, reason: "YOLO mode enabled", continue: true)
        case .deny:
            return PermissionResult(decision: .deny, reason: "Deny mode enabled", continue: false)
        case .ask:
            let hookDecision = await checkHooks(request)
            if let hookDecision {
                return hookDecision
            }
            return PermissionResult(decision: .ask, reason: "User approval required", continue: false)
        }
    }

    private func checkHooks(_ request: PermissionRequest) async -> PermissionResult? {
        let context = HookContext(
            sessionID: "temp-session",
            cwd: FileManager.default.currentDirectoryPath,
            hookEventName: .permissionRequest,
            toolName: request.tool.rawValue,
            toolInput: request.args,
            filePath: request.path
        )

        do {
            try await hookManager.execute(event: .permissionRequest, context: context)
            return nil
        } catch {
            return PermissionResult(
                decision: .block,
                reason: error.localizedDescription,
                continue: false
            )
        }
    }
}
