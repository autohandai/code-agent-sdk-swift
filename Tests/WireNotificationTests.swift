import Foundation
import Testing
@testable import AgentSDK

#if os(macOS)
private final class WirePackets: @unchecked Sendable {
  private let lock = NSLock()
  private var packets: [WireNotification] = []
  func append(_ packet: WireNotification) { lock.withLock { packets.append(packet) } }
  var values: [WireNotification] { lock.withLock { packets } }
}

@Suite struct WireNotificationTests {
  @Test func ephemeralModeIsExplicit() {
    #expect(!AutohandCLIConfiguration().cliArguments.contains("--ephemeral"))
    #expect(AutohandCLIConfiguration(ephemeral:true).cliArguments.contains("--ephemeral"))
  }

  @Test func rejectsObsoleteOptionsBeforeLaunching() throws {
    let client=AutohandCLIClient(configuration:.init(cliPath:"/does-not-exist",autoSaveInterval:30))
    do {try client.start(); Issue.record("obsolete option accepted")} catch {
      #expect(String(describing:error).contains("unsupported by the current CLI"))
    }
  }

  @Test func preservesPacketsAlongsideTypedEvents() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("fixtures/wire-notifications.py")
    let cli = directory.appendingPathComponent("autohand")
    try FileManager.default.copyItem(at: source, to: cli)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: cli.path)
    let sdk = AutohandSDK(configuration: .init(cwd: directory.path, cliPath: cli.path))
    let packets = WirePackets()
    let removeFailure = sdk.onNotification { _ in throw CocoaError(.fileReadUnknown) }
    let remove = sdk.onNotification { packets.append($0) }
    try sdk.start()
    defer { sdk.close(); removeFailure() }
    _ = try await sdk.getState()
    #expect(packets.values.map { $0.method } == ["autohand.pipe.output", "autohand.future", "autohand.future"])
    let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(packets.values[0].params)) as? [String: Any]
    #expect(object?["type"] as? String == "progress")
    #expect(object?["future"] as? Bool == false)
    #expect(String(data: try JSONEncoder().encode(packets.values[1].params), encoding: .utf8) == "[1,null,false]")
    #expect(packets.values[2].params.value is NSNull)
    remove()
    _ = try await sdk.getState()
    #expect(packets.values.count == 3)
  }
}
#endif
