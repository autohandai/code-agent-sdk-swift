import Foundation
import Testing
@testable import AgentSDK
#if os(macOS)
@Suite struct CurrentCLIParityTests {
 @Test func runtimeControlsUseExactWireContracts() async throws {
  let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  let source=URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/fixtures/current-cli-controls.py")
  let cli=directory.appendingPathComponent("autohand")
  try FileManager.default.copyItem(at: source, to: cli)
  try FileManager.default.setAttributes([.posixPermissions:0o700], ofItemAtPath:cli.path)
  let sdk=AutohandSDK(configuration:.init(cwd:directory.path,cliPath:cli.path))
  try sdk.start();defer { sdk.close() }
  let result=try await sdk.setBrowserCapabilities(protocolVersion:2,extensionVersion:"1.0.0",tools:["browser_navigate"])
  #expect(result["method"]?.value as? String == "autohand.browserCapabilities.set")
  let thinking=try await sdk.setMaxThinkingTokens(nil)
  #expect(thinking["method"]?.value as? String == "autohand.maxThinkingTokensSet")
  let context=try await sdk.getContextUsage()
  #expect(context["method"]?.value as? String == "autohand.getContextUsage")
  let toggle=try await sdk.toggleMCPServer("files",enabled:false)
  #expect(toggle["method"]?.value as? String == "autohand.mcp.toggleServer")
 }
}
#endif
