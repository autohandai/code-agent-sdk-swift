import Testing
import Foundation
@testable import AgentSDK

@Suite struct HooksTests {

    @Test func hookManagerCreation() {
        let manager = HookManager()
        #expect(manager.isEnabled == true)
    }

    @Test func hookManagerDisabled() {
        let manager = HookManager(enabled: false)
        #expect(manager.isEnabled == false)
    }

    @Test func hookManagerSetEnabled() {
        let manager = HookManager()
        manager.setEnabled(false)
        #expect(manager.isEnabled == false)
        manager.setEnabled(true)
        #expect(manager.isEnabled == true)
    }

    @Test func addAndGetHooks() {
        let manager = HookManager()
        let hook = HookDefinition(
            event: .beforeExecution,
            command: "echo hello"
        )
        manager.addHook(hook)

        let hooks = manager.getHooks(for: .beforeExecution)
        #expect(hooks.count == 1)
        #expect(hooks[0].command == "echo hello")
    }

    @Test func removeHook() {
        let manager = HookManager()
        manager.addHook(HookDefinition(event: .beforeExecution, command: "echo 1"))
        manager.addHook(HookDefinition(event: .beforeExecution, command: "echo 2"))

        #expect(manager.getHooks(for: .beforeExecution).count == 2)
        #expect(manager.removeHook(event: .beforeExecution, index: 0) == true)
        #expect(manager.getHooks(for: .beforeExecution).count == 1)
        #expect(manager.getHooks(for: .beforeExecution)[0].command == "echo 2")
    }

    @Test func removeHookInvalidIndex() {
        let manager = HookManager()
        #expect(manager.removeHook(event: .beforeExecution, index: 0) == false)
    }

    @Test func getAllHooks() {
        let manager = HookManager()
        manager.addHook(HookDefinition(event: .beforeExecution, command: "echo 1"))
        manager.addHook(HookDefinition(event: .afterExecution, command: "echo 2"))

        let all = manager.getAllHooks()
        #expect(all.count == 2)
    }

    @Test func executeWithDisabledManager() async throws {
        let manager = HookManager(enabled: false)
        manager.addHook(HookDefinition(event: .beforeExecution, command: "echo test"))

        let context = HookContext(
            sessionID: "test",
            cwd: "/tmp",
            hookEventName: .beforeExecution
        )

        try await manager.execute(event: .beforeExecution, context: context)
    }

    @Test func hookDefinitionDefaults() {
        let hook = HookDefinition(event: .preTool, command: "echo test")
        #expect(hook.enabled == true)
        #expect(hook.timeout == 5000)
        #expect(hook.async == false)
        #expect(hook.matcher == nil)
        #expect(hook.filter == nil)
    }

    @Test func hookEventsMatchCliNames() {
        #expect(HookEvent.postResponse.rawValue == "post-response")
        #expect(HookEvent.automodeCheckpoint.rawValue == "automode:checkpoint")
        #expect(HookEvent.teammateSpawned.rawValue == "teammate-spawned")
        #expect(HookEvent.reviewCompleted.rawValue == "review:completed")
        #expect(HookEvent.contextCritical.rawValue == "context:critical")
        #expect(HookEvent.autoresearchDecision.rawValue == "autoresearch:decision")
        #expect(HookEvent.autoresearchReplay.rawValue == "autoresearch:replay")
        #expect(HookEvent.autoresearchRescore.rawValue == "autoresearch:rescore")
        #expect(HookEvent.autoresearchPrune.rawValue == "autoresearch:prune")
        #expect(HookEvent.goalWrittenCompleted.rawValue == "goal-written:completed")
    }

    @Test func hookContextCreation() {
        let context = HookContext(
            sessionID: "sess_1",
            cwd: "/tmp",
            hookEventName: .preTool,
            toolName: "read_file",
            instruction: "Read a file"
        )
        #expect(context.sessionID == "sess_1")
        #expect(context.toolName == "read_file")
        #expect(context.instruction == "Read a file")
    }

    @Test func hookContextSupportsCliEventFamilies() {
        let context = HookContext(
            sessionID: "sess_1",
            cwd: "/tmp",
            hookEventName: .teammateSpawned,
            automodeCheckpointCommit: "abc123",
            reviewPath: "src/App.swift",
            teamName: "release",
            teammateName: "planner",
            teamTaskID: "task-1",
            additionalWorkspaces: ["/tmp/extra"]
        )

        #expect(context.automodeCheckpointCommit == "abc123")
        #expect(context.reviewPath == "src/App.swift")
        #expect(context.teamName == "release")
        #expect(context.teammateName == "planner")
        #expect(context.teamTaskID == "task-1")
        #expect(context.additionalWorkspaces == ["/tmp/extra"])
    }
}

@Suite struct PermissionTests {

    @Test func permissionManagerYoloMode() async {
        let hookManager = HookManager()
        let permManager = PermissionManager(hookManager: hookManager, mode: .yolo)

        let request = PermissionRequest(tool: .bash, command: "rm -rf /")
        let result = await permManager.requestPermission(request)

        #expect(result.decision == .allow)
        #expect(result.continue == true)
    }

    @Test func permissionManagerDenyMode() async {
        let hookManager = HookManager()
        let permManager = PermissionManager(hookManager: hookManager, mode: .deny)

        let request = PermissionRequest(tool: .bash)
        let result = await permManager.requestPermission(request)

        #expect(result.decision == .deny)
        #expect(result.continue == false)
    }

    @Test func permissionManagerAskMode() async {
        let hookManager = HookManager()
        let permManager = PermissionManager(hookManager: hookManager, mode: .ask)

        let request = PermissionRequest(tool: .readFile, path: "/tmp/test.txt")
        let result = await permManager.requestPermission(request)

        #expect(result.decision == .ask)
        #expect(result.continue == false)
    }

    @Test func permissionManagerSetMode() {
        let hookManager = HookManager()
        let permManager = PermissionManager(hookManager: hookManager, mode: .ask)

        #expect(permManager.permissionMode == .ask)
        permManager.setPermissionMode(.yolo)
        #expect(permManager.permissionMode == .yolo)
    }

    @Test func permissionRequestCreation() {
        let request = PermissionRequest(
            tool: .writeFile,
            args: ["file_path": AnyCodable("/tmp/test.txt")],
            path: "/tmp/test.txt"
        )
        #expect(request.tool == .writeFile)
        #expect(request.path == "/tmp/test.txt")
    }
}
