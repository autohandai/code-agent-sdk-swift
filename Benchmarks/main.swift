import AgentSDK
import Foundation

#if os(macOS)
  private let warmupCount = 5
  private let sampleCount = 50
  private let budgetMilliseconds = 50.0

  private struct Metric: Codable {
    let samples: Int
    let medianMs: Double
    let p95Ms: Double
    let maxMs: Double
    let passed: Bool
  }

  private struct Metrics: Codable {
    let publicImportMs: Metric
    let sdkStartReturnMs: Metric
    let fixtureSpawnToFirstRpcMs: Metric
  }

  private struct Report: Codable {
    let language: String
    let budgetMs: Double
    let metrics: Metrics
    let passed: Bool
  }

  @main
  private enum StartupBenchmark {
    static func main() async throws {
      guard CommandLine.arguments.count == 2 else {
        throw BenchmarkError.usage
      }
      let fixture = CommandLine.arguments[1]
      let cwd = FileManager.default.currentDirectoryPath

      let publicImport = try await collect {
        let start = DispatchTime.now().uptimeNanoseconds
        let sdk = AutohandSDK(configuration: .init(cwd: cwd, cliPath: fixture))
        let skills = GetSkillsRegistryParameters(forceRefresh: true)
        let tools = MCPListToolsParameters(serverName: "fixture")
        blackHole(sdk)
        blackHole(skills)
        blackHole(tools)
        return milliseconds(since: start)
      }

      let startReturn = try await collect {
        let sdk = AutohandSDK(configuration: .init(cwd: cwd, cliPath: fixture, timeout: 2))
        let start = DispatchTime.now().uptimeNanoseconds
        try sdk.start()
        let elapsed = milliseconds(since: start)
        sdk.close()
        return elapsed
      }

      let firstRPC = try await collect {
        let client = AutohandCLIClient(
          configuration: .init(
            cwd: cwd,
            cliPath: fixture,
            timeout: 2
          ))
        let start = DispatchTime.now().uptimeNanoseconds
        try client.start()
        _ = try await client.listMCPServers()
        let elapsed = milliseconds(since: start)
        client.close()
        return elapsed
      }

      let metrics = Metrics(
        publicImportMs: summarize(publicImport),
        sdkStartReturnMs: summarize(startReturn),
        fixtureSpawnToFirstRpcMs: summarize(firstRPC)
      )
      let report = Report(
        language: "swift",
        budgetMs: budgetMilliseconds,
        metrics: metrics,
        passed: metrics.publicImportMs.passed
          && metrics.sdkStartReturnMs.passed
          && metrics.fixtureSpawnToFirstRpcMs.passed
      )
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      FileHandle.standardOutput.write(try encoder.encode(report))
      FileHandle.standardOutput.write(Data("\n".utf8))
      if !report.passed { Foundation.exit(1) }
    }

    @MainActor
    private static func collect(
      _ operation: () async throws -> Double
    ) async throws -> [Double] {
      for _ in 0..<warmupCount { _ = try await operation() }
      var samples: [Double] = []
      samples.reserveCapacity(sampleCount)
      for _ in 0..<sampleCount { samples.append(try await operation()) }
      return samples
    }

    private static func summarize(_ values: [Double]) -> Metric {
      let sorted = values.sorted()
      let middle = sorted.count / 2
      let median = (sorted[middle - 1] + sorted[middle]) / 2
      let p95Index = Int(ceil(Double(sorted.count) * 0.95)) - 1
      return Metric(
        samples: values.count,
        medianMs: rounded(median),
        p95Ms: rounded(sorted[p95Index]),
        maxMs: rounded(sorted.last ?? 0),
        passed: sorted[p95Index] < budgetMilliseconds
      )
    }

    private static func rounded(_ value: Double) -> Double {
      (value * 1_000_000).rounded() / 1_000_000
    }

    private static func milliseconds(since start: UInt64) -> Double {
      Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
    }
  }

  @inline(never)
  private func blackHole<T>(_ value: T) {
    withExtendedLifetime(value) {}
  }

  private enum BenchmarkError: Error, LocalizedError {
    case usage

    var errorDescription: String? {
      "Usage: agent-sdk-benchmark /absolute/path/to/native-rpc-fixture"
    }
  }
#else
  @main
  private enum UnsupportedBenchmark {
    static func main() {
      FileHandle.standardError.write(Data("The startup benchmark requires macOS.\n".utf8))
      Foundation.exit(2)
    }
  }
#endif
