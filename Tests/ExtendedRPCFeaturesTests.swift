import Foundation
import Testing

@testable import AgentSDK

#if os(macOS)
  @Suite struct ExtendedRPCFeaturesTests {
    @Test func permissionAcknowledgementUsesExactWireContract() async throws {
      let fixture = try FakeCLIFixture()
      defer { fixture.remove() }
      let sdk = AutohandSDK(configuration: configuration(for: fixture))
      try sdk.start()
      defer { sdk.close() }

      let result = try await sdk.acknowledgePermission(.init(requestId: "permission-1"))

      #expect(result.success)
      let request = try #require(requests(in: fixture).last)
      #expect(request["method"] as? String == "autohand.permissionAcknowledged")
      let parameters = try #require(request["params"] as? [String: Any])
      #expect(parameters.count == 1)
      #expect(parameters["requestId"] as? String == "permission-1")
    }

    private func configuration(for fixture: FakeCLIFixture) -> AutohandCLIConfiguration {
      .init(
        cwd: fixture.directory.path,
        cliPath: fixture.executable.path,
        timeout: 5,
        environment: ["AUTOHAND_TEST_REQUEST_LOG": fixture.requestLog.path]
      )
    }

    private func requests(in fixture: FakeCLIFixture) throws -> [[String: Any]] {
      let contents = try String(contentsOf: fixture.requestLog, encoding: .utf8)
      return try contents.split(separator: "\n").map { line in
        try #require(JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])
      }
    }
  }
#endif
