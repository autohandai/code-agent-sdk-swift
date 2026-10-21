import Foundation
import Testing
@testable import AgentSDK

#if os(macOS)
@Suite(.serialized) struct ActualCLIParityTests {
  @Test(.enabled(if: ProcessInfo.processInfo.environment["AUTOHAND_TEST_CLI_PATH"] != nil))
  func actualCLIUsesProviderOverrideAndPersistsStoppedSteps() async throws {
    let cli = try #require(ProcessInfo.processInfo.environment["AUTOHAND_TEST_CLI_PATH"])
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("swift-actual-cli-\(UUID())")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try "swift-persisted-marker".write(to: root.appendingPathComponent("evidence.txt"), atomically: true, encoding: .utf8)
    let config = root.appendingPathComponent("config.json")
    let saved = """
      {"provider":"openai","auth":{"token":"session-token"},"openai":{"apiKey":"saved-key","model":"saved-model","baseUrl":"http://127.0.0.1:1/unused"},"agent":{"autoMemory":false},"telemetry":{"enabled":false}}
      """
    try saved.write(to: config, atomically: true, encoding: .utf8)
    let server = Process()
    let output = Pipe()
    server.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    let helper = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("fixtures/harness-provider.py")
    server.arguments = ["python3", helper.path, root.path]
    server.standardOutput = output
    try server.run()
    defer { server.terminate(); server.waitUntilExit() }
    let address = try #require(try JSONSerialization.jsonObject(with: output.fileHandleForReading.availableData) as? [String: String])
    let baseURL = try #require(address["baseUrl"])
    let sdk = AutohandSDK(configuration: .init(cwd: root.path, cliPath: cli, timeout: 30, model: "fantail",
      provider: "autohandai", apiKey: "inference-key", baseURL: baseURL + "/v1", bare: true, unrestricted: true,
      runSettings: ["features": AnyCodable(["autohand_inference": true, "automaticSpecialists": false])],
      environment: ["AUTOHAND_HOME": root.appendingPathComponent("state").path, "AUTOHAND_CONFIG": config.path,
        "AUTOHAND_AUTH_API_URL": baseURL + "/auth", "AUTOHAND_API_URL": baseURL,
        "NO_PROXY": "127.0.0.1,localhost"]))
    try sdk.start()
    defer { sdk.close() }
    #expect(try await sdk.supportedAgents().contains { $0.name == "reviewer" && $0.source == "builtin" })
    let stopped = try await sdk.run("Use read_file to read evidence.txt", options: .init(stopWhen: [try isStepCount(1)]))
    #expect(stopped.status == .stopped)
    #expect(stopped.steps.count == 1)
    #expect(stopped.steps.first?.toolResults.first?.output?.contains("swift-persisted-marker") == true)
    let completed = try await sdk.run("Continue using the persisted result")
    #expect(completed.status == .completed)
    #expect(completed.output == "continued from persisted evidence")
    let calls = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("calls.json"))) as? [[String: Any]])
    #expect(calls.count == 2)
    #expect(String(describing: calls.last?["messages"]).contains("swift-persisted-marker"))
    let status = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("fixture-status.json"))) as? [String: Any])
    #expect((status["failures"] as? [String])?.isEmpty == true)
    #expect((status["auth"] as? [String])?.first == "Bearer session-token")
    let persisted = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: config)) as? [String: Any])
    #expect(persisted["provider"] as? String == "openai")
    #expect((persisted["openai"] as? [String: Any])?["apiKey"] as? String == "saved-key")
    #expect(persisted["autohandai"] == nil)
  }
}
#endif
