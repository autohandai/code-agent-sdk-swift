import Testing
import Foundation
@testable import AgentSDK

@Suite struct TypesTests {

    @Test func toolCallID() {
        let id = ToolCallID("call_123")
        #expect(id.rawValue == "call_123")
        #expect(id == ToolCallID("call_123"))
        #expect(id != ToolCallID("call_456"))
    }

    @Test func sessionID() {
        let id = SessionID("sess_abc")
        #expect(id.rawValue == "sess_abc")
    }

    @Test func modelID() {
        let id = ModelID("gpt-4")
        #expect(id.rawValue == "gpt-4")
    }

    @Test func toolNameRawValues() {
        #expect(ToolName.readFile.rawValue == "read_file")
        #expect(ToolName.writeFile.rawValue == "write_file")
        #expect(ToolName.bash.rawValue == "bash")
        #expect(ToolName.gitStatus.rawValue == "git_status")
    }

    @Test func toolNameFromRawValue() {
        #expect(ToolName(rawValue: "read_file") == .readFile)
        #expect(ToolName(rawValue: "nonexistent") == nil)
    }

    @Test func messageCreation() {
        let userMsg = Message.user(UserMessage(content: "Hello"))
        #expect(userMsg.role == .user)
        #expect(userMsg.content == "Hello")

        let assistantMsg = Message.assistant(AssistantMessage(content: "Hi there"))
        #expect(assistantMsg.role == .assistant)

        let systemMsg = Message.system(SystemMessage(content: "You are helpful"))
        #expect(systemMsg.role == .system)

        let toolMsg = Message.tool(ToolMessage(content: "result", toolCallID: "call_1"))
        #expect(toolMsg.role == .tool)
    }

    @Test func toolCallCreation() {
        let call = ToolCall(id: "call_1", name: .readFile, arguments: #"{"file_path":"/tmp/test.txt"}"#)
        #expect(call.id == "call_1")
        #expect(call.name == .readFile)
        #expect(call.arguments.contains("file_path"))
    }

    @Test func toolResultSuccess() {
        let result = ToolResult.success(data: "file contents")
        #expect(result.data == "file contents")
        #expect(result.error == nil)
    }

    @Test func toolResultFailure() {
        let result = ToolResult.failure(error: "not found")
        #expect(result.data == nil)
        #expect(result.error == "not found")
    }

    @Test func sessionCreation() {
        let session = Session(id: SessionID("sess_1"), workingDirectory: "/tmp")
        #expect(session.id.rawValue == "sess_1")
        #expect(session.workingDirectory == "/tmp")
        #expect(session.messages.isEmpty)
    }

    @Test func runResultSuccess() {
        let session = Session(id: SessionID("sess_1"))
        let result = RunResult.success(finalOutput: "Done", session: session, turns: 3)
        #expect(result.finalOutput == "Done")
        #expect(result.turns == 3)
    }

    @Test func runResultMaxTurns() {
        let session = Session(id: SessionID("sess_1"))
        let result = RunResult.maxTurnsReached(session: session, turns: 10)
        #expect(result.finalOutput == "Max turns reached")
        #expect(result.turns == 10)
    }

    @Test func streamEventCreation() {
        let event = StreamEvent(type: .toolCall, tool: .readFile, toolID: "call_1")
        #expect(event.type == .toolCall)
        #expect(event.tool == .readFile)
        #expect(event.toolID == "call_1")
    }

    @Test func permissionMode() {
        #expect(PermissionMode.yolo.rawValue == "yolo")
        #expect(PermissionMode.ask.rawValue == "ask")
        #expect(PermissionMode.deny.rawValue == "deny")
    }
}
