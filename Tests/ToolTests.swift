import Testing
import Foundation
@testable import AgentSDK

@Suite struct ToolTests {

    @Test func readFileToolSuccess() async throws {
        let tool = ReadFileTool()
        #expect(tool.name == "read_file")
        #expect(tool.annotations.readOnlyHint == true)

        let tmpFile = "/tmp/agent_sdk_test_read.txt"
        try "test content".write(toFile: tmpFile, atomically: true, encoding: .utf8)

        let result = try await tool.execute(params: ["file_path": AnyCodable(tmpFile)])
        #expect(result.data == "test content")

        try? FileManager.default.removeItem(atPath: tmpFile)
    }

    @Test func readFileToolNotFound() async throws {
        let tool = ReadFileTool()
        let result = try await tool.execute(params: ["file_path": AnyCodable("/tmp/nonexistent_file.txt")])
        #expect(result.error?.contains("not found") == true)
    }

    @Test func readFileToolMissingParam() async throws {
        let tool = ReadFileTool()
        let result = try await tool.execute(params: [:])
        #expect(result.error?.contains("Missing") == true)
    }

    @Test func writeFileTool() async throws {
        let tool = WriteFileTool()
        #expect(tool.name == "write_file")
        #expect(tool.annotations.destructiveHint == true)

        let tmpFile = "/tmp/agent_sdk_test_write.txt"
        let result = try await tool.execute(params: [
            "file_path": AnyCodable(tmpFile),
            "content": AnyCodable("hello world"),
        ])
        #expect(result.data?.contains("successfully") == true)

        let content = try String(contentsOfFile: tmpFile, encoding: .utf8)
        #expect(content == "hello world")

        try? FileManager.default.removeItem(atPath: tmpFile)
    }

    @Test func editFileTool() async throws {
        let tool = EditFileTool()
        #expect(tool.name == "edit_file")

        let tmpFile = "/tmp/agent_sdk_test_edit.txt"
        try "hello world".write(toFile: tmpFile, atomically: true, encoding: .utf8)

        let result = try await tool.execute(params: [
            "file_path": AnyCodable(tmpFile),
            "old_string": AnyCodable("hello"),
            "new_string": AnyCodable("goodbye"),
        ])
        #expect(result.data?.contains("successfully") == true)

        let content = try String(contentsOfFile: tmpFile, encoding: .utf8)
        #expect(content == "goodbye world")

        try? FileManager.default.removeItem(atPath: tmpFile)
    }

    @Test func editFileToolOldStringNotFound() async throws {
        let tool = EditFileTool()
        let tmpFile = "/tmp/agent_sdk_test_edit2.txt"
        try "hello world".write(toFile: tmpFile, atomically: true, encoding: .utf8)

        let result = try await tool.execute(params: [
            "file_path": AnyCodable(tmpFile),
            "old_string": AnyCodable("nonexistent"),
            "new_string": AnyCodable("replacement"),
        ])
        #expect(result.error?.contains("not found") == true)

        try? FileManager.default.removeItem(atPath: tmpFile)
    }

    @Test func bashTool() async throws {
        let tool = BashTool()
        #expect(tool.name == "bash")

        let result = try await tool.execute(params: ["command": AnyCodable("echo hello")])
        #expect(result.data?.contains("hello") == true)
    }

    @Test func bashToolFailure() async throws {
        let tool = BashTool()
        let result = try await tool.execute(params: ["command": AnyCodable("exit 1")])
        #expect(result.error != nil)
    }

    @Test func toolRegistryRegisterAndExecute() async throws {
        let registry = ToolRegistry()
        registry.register(ReadFileTool())

        let tmpFile = "/tmp/agent_sdk_test_registry.txt"
        try "registry test".write(toFile: tmpFile, atomically: true, encoding: .utf8)

        let toolCall = ToolCall(
            id: "call_1",
            name: .readFile,
            arguments: #"{"file_path":"\#(tmpFile)"}"#
        )

        let result = try await registry.execute(toolCall: toolCall)
        #expect(result.data == "registry test")

        try? FileManager.default.removeItem(atPath: tmpFile)
    }

    @Test func toolRegistryUnknownTool() async throws {
        let registry = ToolRegistry()
        let toolCall = ToolCall(id: "call_1", name: .readFile, arguments: "{}")
        let result = try await registry.execute(toolCall: toolCall)
        #expect(result.error?.contains("not found") == true)
    }

    @Test func defaultToolRegistryHasAllTools() {
        let registry = DefaultToolRegistry()
        let tools = registry.getAllTools()
        #expect(tools.count >= 14)
    }

    @Test func defaultToolRegistryAllToolNames() {
        let names = DefaultToolRegistry.allToolNames()
        #expect(names.contains(.readFile))
        #expect(names.contains(.writeFile))
        #expect(names.contains(.bash))
        #expect(names.contains(.gitStatus))
    }

    @Test func webSearchTool() async throws {
        let tool = WebSearchTool()
        #expect(tool.name == "web_search")
        #expect(tool.annotations.openWorldHint == true)

        let result = try await tool.execute(params: ["query": AnyCodable("Swift programming")])
        #expect(result.data != nil || result.error != nil)
    }

    @Test func gitStatusTool() async throws {
        let tool = GitStatusTool()
        #expect(tool.name == "git_status")
        #expect(tool.annotations.readOnlyHint == true)
    }
}
