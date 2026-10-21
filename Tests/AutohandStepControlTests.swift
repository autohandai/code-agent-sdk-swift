import Foundation
import Testing

@testable import AgentSDK

#if os(macOS)
@Suite(.serialized) struct AutohandStepControlTests {
  @Test func promptWaitsForTerminalCompletion() async throws {
    let fixture = try StepFixture()
    defer { fixture.remove() }
    let client = AutohandCLIClient(configuration: fixture.configuration)
    try client.start()
    defer { client.close() }
    _ = try await client.prompt("Read evidence")
    #expect(FileManager.default.fileExists(atPath: fixture.completed.path))
  }

  @Test func persistsStepsAndContinuesAfterStop() async throws {
    let fixture = try StepFixture()
    defer { fixture.remove() }
    let sdk = AutohandSDK(configuration: fixture.configuration)
    try sdk.start()
    defer { sdk.close() }
    let run = sdk.send("Read evidence", options: .init(stopWhen: [try isStepCount(2)]))
    let result = try await run.wait()
    #expect(result.status == .stopped)
    #expect(result.steps.count == 2)
    #expect(result.steps[0].toolCalls[0].args["path"]?.value as? String == "evidence.txt")
    #expect(result.steps[1].toolResults[0].output == "evidence-2")
    #expect(try await run.wait().steps.count == 2)
    run.abort()
    #expect(try await sdk.run("Continue").output == "continued")
    let requests = try fixture.requests()
    #expect(requests.filter { $0["method"] as? String == "autohand.abort" }.isEmpty)
    let prompt = try #require(requests.first?["params"] as? [String: Any])
    #expect((prompt["stopWhen"] as? [String: String]) == ["mode": "host"])
  }

  @Test func asynchronousConditionsUseOrSemantics() async throws {
    let fixture = try StepFixture()
    defer { fixture.remove() }
    let sdk = AutohandSDK(configuration: fixture.configuration)
    try sdk.start()
    defer { sdk.close() }
    let result = try await sdk.run("Read evidence", options: .init(stopWhen: [
      { _ in try await Task.sleep(for: .milliseconds(15)); return false },
      try hasToolCall(" read_file "),
    ]))
    #expect(result.status == .stopped)
    #expect(result.steps.count == 1)
  }

  @Test func queuedAndActiveCancellationAreScoped() async throws {
    let fixture = try StepFixture()
    defer { fixture.remove() }
    let sdk = AutohandSDK(configuration: fixture.configuration)
    try sdk.start()
    defer { sdk.close() }
    let latch = ConditionLatch()
    let active = sdk.send("Read evidence", options: .init(stopWhen: [{ _ in await latch.wait() }]))
    let activeTask = Task { try await active.wait() }
    try await fixture.waitForRequest("autohand.prompt")
    let queued = sdk.send("Must not send")
    let queuedTask = Task { try await queued.wait() }
    try await Task.sleep(for: .milliseconds(30))
    queued.abort()
    await #expect(throws: CancellationError.self) { try await queuedTask.value }
    #expect(try fixture.requests().filter { $0["method"] as? String == "autohand.abort" }.isEmpty)
    active.abort()
    await #expect(throws: CancellationError.self) { try await activeTask.value }
    #expect(try await sdk.run("Continue").status == .completed)
    latch.resolve(false)
    #expect(try fixture.requests().filter { $0["method"] as? String == "autohand.prompt" }.count == 2)
  }

  @Test func conditionFailureDoesNotWaitForAnotherCondition() async throws {
    let fixture = try StepFixture()
    defer { fixture.remove() }
    let sdk = AutohandSDK(configuration: fixture.configuration)
    try sdk.start()
    defer { sdk.close() }
    let latch = ConditionLatch()
    defer { latch.resolve(false) }
    let run = sdk.send("Read evidence", options: .init(stopWhen: [
      { _ in await latch.wait() }, { _ in throw StepTestError.condition },
    ]))
    await #expect(throws: StepTestError.self) { try await run.wait() }
    await #expect(throws: StepTestError.self) { try await run.wait() }
    #expect(try await sdk.run("Continue").output == "continued")
  }

  @Test func abortBeforeStartSendsNothing() async throws {
    let fixture = try StepFixture()
    defer { fixture.remove() }
    let sdk = AutohandSDK(configuration: fixture.configuration)
    try sdk.start()
    defer { sdk.close() }
    let run = sdk.send("Must not send")
    run.abort()
    await #expect(throws: CancellationError.self) { try await run.wait() }
    #expect(try fixture.requests().isEmpty)
  }

  @Test(arguments: ["null", "{}", "{\"stepId\":\"s\",\"timestamp\":\"now\",\"step\":{\"stepNumber\":0,\"toolCalls\":[],\"toolResults\":[]}}"])
  func malformedStepsFailAndDrain(_ payload: String) async throws {
    let fixture = try StepFixture(environment: ["AUTOHAND_SWIFT_BAD_STEP": payload])
    defer { fixture.remove() }
    let sdk = AutohandSDK(configuration: fixture.configuration)
    try sdk.start()
    defer { sdk.close() }
    await #expect(throws: (any Error).self) {
      try await sdk.run("Read evidence", options: .init(stopWhen: [try isStepCount(1)]))
    }
    #expect(try await sdk.run("Continue").status == .completed)
  }

  @Test(arguments: ["{}", "{\"success\":false}", "{\"success\":\"true\"}"])
  func rejectedDecisionsFailAndDrain(_ payload: String) async throws {
    let fixture = try StepFixture(environment: ["AUTOHAND_SWIFT_BAD_DECISION": payload])
    defer { fixture.remove() }
    let sdk = AutohandSDK(configuration: fixture.configuration)
    try sdk.start()
    defer { sdk.close() }
    await #expect(throws: (any Error).self) {
      try await sdk.run("Read evidence", options: .init(stopWhen: [try isStepCount(1)]))
    }
    #expect(try await sdk.run("Continue").status == .completed)
  }

  @Test func terminalBeforeRejectionStillFails() async throws {
    let fixture = try StepFixture(environment: ["AUTOHAND_SWIFT_LATE_REJECTION": "1"])
    defer { fixture.remove() }
    let sdk = AutohandSDK(configuration: fixture.configuration)
    try sdk.start()
    defer { sdk.close() }
    await #expect(throws: (any Error).self) { try await sdk.run("Read evidence") }
  }

  @Test func validatesHelpers() throws {
    #expect(throws: (any Error).self) { try isStepCount(0) }
    #expect(throws: (any Error).self) { try hasToolCall("  ") }
  }

}

private struct StepFixture {
  let directory: URL
  let executable: URL
  let completed: URL

  let environment: [String: String]

  init(environment: [String: String] = [:]) throws {
    self.environment = environment
    directory = FileManager.default.temporaryDirectory.appendingPathComponent("autohand-swift-steps-\(UUID().uuidString)")
    executable = directory.appendingPathComponent("step-cli")
    completed = directory.appendingPathComponent("completed")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try """
      #!/usr/bin/env python3
      import json, os, sys, time
      count = 0
      step_number = 0
      def send(value): print(json.dumps(value), flush=True)
      def event(method, params): send({"jsonrpc": "2.0", "method": method, "params": params})
      def end(reason): event("autohand.turnEnd", {"reason": reason, "timestamp": "now"})
      def step():
          global step_number
          step_number += 1
          payload = {"stepId": "step-" + str(step_number), "timestamp": "now", "step": {
              "stepNumber": step_number, "toolCalls": [{"tool": "read_file", "args": {"path": "evidence.txt"}}],
              "toolResults": [{"tool": "read_file", "success": True, "output": "evidence-" + str(step_number)}]}}
          event("autohand.stepEnd", json.loads(os.environ["AUTOHAND_SWIFT_BAD_STEP"]) if "AUTOHAND_SWIFT_BAD_STEP" in os.environ else payload)
      for line in sys.stdin:
          with open(os.environ["AUTOHAND_SWIFT_REQUESTS"], "a") as log: log.write(line)
          request = json.loads(line)
          method = request["method"]
          if method == "autohand.prompt" and "AUTOHAND_SWIFT_LATE_REJECTION" in os.environ:
              end("completed")
              time.sleep(0.04)
              send({"jsonrpc": "2.0", "id": request["id"], "error": {"code": -32000, "message": "rejected"}})
              continue
          result = json.loads(os.environ["AUTOHAND_SWIFT_BAD_DECISION"]) if method == "autohand.stepDecision" and "AUTOHAND_SWIFT_BAD_DECISION" in os.environ else {"success": True}
          send({"jsonrpc": "2.0", "id": request["id"], "result": result})
          if method == "autohand.prompt":
              count += 1
              if count == 1 and "stopWhen" in request["params"]:
                  step()
                  continue
              time.sleep(0.08)
              open(os.environ["AUTOHAND_SWIFT_COMPLETED"], "w").close()
              event("autohand.messageEnd", {"content": "continued"})
              end("completed")
          elif method == "autohand.stepDecision" and "AUTOHAND_SWIFT_BAD_DECISION" not in os.environ:
              if request["params"]["stop"]: end("stop_condition")
              else: step()
          elif method == "autohand.abort": end("aborted")
      """.write(to: executable, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
  }

  var configuration: AutohandCLIConfiguration {
    .init(cwd: directory.path, cliPath: executable.path, timeout: 10,
      environment: environment.merging(["AUTOHAND_SWIFT_COMPLETED": completed.path,
        "AUTOHAND_SWIFT_REQUESTS": directory.appendingPathComponent("requests.jsonl").path]) { _, value in value })
  }

  func requests() throws -> [[String: Any]] {
    let path = directory.appendingPathComponent("requests.jsonl")
    guard FileManager.default.fileExists(atPath: path.path) else { return [] }
    return try String(contentsOf: path, encoding: .utf8).split(separator: "\n").map {
      try JSONSerialization.jsonObject(with: Data($0.utf8)) as! [String: Any]
    }
  }

  func waitForRequest(_ method: String) async throws {
    for _ in 0..<200 {
      if try requests().contains(where: { $0["method"] as? String == method }) { return }
      try await Task.sleep(for: .milliseconds(10))
    }
    throw StepTestError.timeout
  }

  func remove() { try? FileManager.default.removeItem(at: directory) }
}
private enum StepTestError: Error { case condition, timeout }

private final class ConditionLatch: @unchecked Sendable {
  private let lock = NSLock()
  private var result: Bool?
  private var continuation: CheckedContinuation<Bool, Never>?
  func wait() async -> Bool {
    await withCheckedContinuation { continuation in
      lock.withLock {
        if let result { continuation.resume(returning: result) }
        else { self.continuation = continuation }
      }
    }
  }
  func resolve(_ value: Bool) {
    lock.withLock {
      result = value
      continuation?.resume(returning: value)
      continuation = nil
    }
  }
}
#endif
