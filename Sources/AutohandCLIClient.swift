import Foundation

#if os(macOS)
  import Darwin
#endif

public struct AutohandFeatureFlagSettings: Codable, Sendable {
  public var environment: String?
  public var remoteOverrides: [String: String]?
  public var usageV2: Bool?
  public var awsBedrockProvider: Bool?
  public var slashGoal: Bool?
  public var tokenUsageStatus: Bool?
  public var experimentalFork: Bool?
  public var experimentalClone: Bool?
  public var experimentalHandoff: Bool?

  public init(
    environment: String? = nil,
    remoteOverrides: [String: String]? = nil,
    usageV2: Bool? = nil,
    awsBedrockProvider: Bool? = nil,
    slashGoal: Bool? = nil,
    tokenUsageStatus: Bool? = nil,
    experimentalFork: Bool? = nil,
    experimentalClone: Bool? = nil,
    experimentalHandoff: Bool? = nil
  ) {
    self.environment = environment
    self.remoteOverrides = remoteOverrides
    self.usageV2 = usageV2
    self.awsBedrockProvider = awsBedrockProvider
    self.slashGoal = slashGoal
    self.tokenUsageStatus = tokenUsageStatus
    self.experimentalFork = experimentalFork
    self.experimentalClone = experimentalClone
    self.experimentalHandoff = experimentalHandoff
  }
}

public struct AutohandCLIConfiguration: Sendable {
  public var cwd: String
  public var cliPath: String?
  public var debug: Bool
  public var timeout: TimeInterval
  public var model: String?
  public var bare: Bool?
  public var idleLogout: Bool?
  public var unrestricted: Bool?
  public var autoMode: Bool?
  public var autoSkill: Bool?
  public var autoCommit: Bool?
  public var contextCompact: Bool?
  public var fork: String?
  public var persistSession: Bool?
  public var sessionId: String?
  public var resume: Bool?
  public var continueSession: Bool?
  public var sessionPath: String?
  public var autoSaveInterval: Int?
  public var agentsMdEnabled: Bool?
  public var agentsMdCreate: Bool?
  public var agentsMdPath: String?
  public var agentsMdAutoUpdate: Bool?
  public var maxTokens: Int?
  public var compressionThreshold: Double?
  public var summarizationThreshold: Double?
  public var skills: [String]
  public var skillSources: [String]
  public var installMissingSkills: Bool?
  public var maxIterations: Int?
  public var maxRuntime: Int?
  public var maxCost: Double?
  public var displayLanguage: String?
  public var systemPrompt: String?
  public var systemPromptFile: String?
  public var appendSystemPrompt: String?
  public var appendSystemPromptFile: String?
  public var mcpConfig: String?
  public var agents: String?
  public var pluginDirectory: String?
  public var temperature: Double?
  public var yolo: String?
  public var yoloTimeout: Int?
  public var features: AutohandFeatureFlagSettings?
  public var autohandAIAPIKey: String?
  public var autohandAIBaseURL: String?
  public var autohandAIPlan: String?
  public var extraArguments: [String]
  public var environment: [String: String]

  public init(
    cwd: String = FileManager.default.currentDirectoryPath,
    cliPath: String? = nil,
    debug: Bool = false,
    timeout: TimeInterval = 300,
    model: String? = nil,
    bare: Bool? = nil,
    idleLogout: Bool? = nil,
    unrestricted: Bool? = nil,
    autoMode: Bool? = nil,
    autoSkill: Bool? = nil,
    autoCommit: Bool? = nil,
    contextCompact: Bool? = nil,
    fork: String? = nil,
    persistSession: Bool? = nil,
    sessionId: String? = nil,
    resume: Bool? = nil,
    continueSession: Bool? = nil,
    sessionPath: String? = nil,
    autoSaveInterval: Int? = nil,
    agentsMdEnabled: Bool? = nil,
    agentsMdCreate: Bool? = nil,
    agentsMdPath: String? = nil,
    agentsMdAutoUpdate: Bool? = nil,
    maxTokens: Int? = nil,
    compressionThreshold: Double? = nil,
    summarizationThreshold: Double? = nil,
    skills: [String] = [],
    skillSources: [String] = [],
    installMissingSkills: Bool? = nil,
    maxIterations: Int? = nil,
    maxRuntime: Int? = nil,
    maxCost: Double? = nil,
    displayLanguage: String? = nil,
    systemPrompt: String? = nil,
    systemPromptFile: String? = nil,
    appendSystemPrompt: String? = nil,
    appendSystemPromptFile: String? = nil,
    mcpConfig: String? = nil,
    agents: String? = nil,
    pluginDirectory: String? = nil,
    temperature: Double? = nil,
    yolo: String? = nil,
    yoloTimeout: Int? = nil,
    features: AutohandFeatureFlagSettings? = nil,
    autohandAIAPIKey: String? = nil,
    autohandAIBaseURL: String? = nil,
    autohandAIPlan: String? = nil,
    extraArguments: [String] = [],
    environment: [String: String] = [:]
  ) {
    self.cwd = cwd
    self.cliPath = cliPath
    self.debug = debug
    self.timeout = timeout
    self.model = model
    self.bare = bare
    self.idleLogout = idleLogout
    self.unrestricted = unrestricted
    self.autoMode = autoMode
    self.autoSkill = autoSkill
    self.autoCommit = autoCommit
    self.contextCompact = contextCompact
    self.fork = fork
    self.persistSession = persistSession
    self.sessionId = sessionId
    self.resume = resume
    self.continueSession = continueSession
    self.sessionPath = sessionPath
    self.autoSaveInterval = autoSaveInterval
    self.agentsMdEnabled = agentsMdEnabled
    self.agentsMdCreate = agentsMdCreate
    self.agentsMdPath = agentsMdPath
    self.agentsMdAutoUpdate = agentsMdAutoUpdate
    self.maxTokens = maxTokens
    self.compressionThreshold = compressionThreshold
    self.summarizationThreshold = summarizationThreshold
    self.skills = skills
    self.skillSources = skillSources
    self.installMissingSkills = installMissingSkills
    self.maxIterations = maxIterations
    self.maxRuntime = maxRuntime
    self.maxCost = maxCost
    self.displayLanguage = displayLanguage
    self.systemPrompt = systemPrompt
    self.systemPromptFile = systemPromptFile
    self.appendSystemPrompt = appendSystemPrompt
    self.appendSystemPromptFile = appendSystemPromptFile
    self.mcpConfig = mcpConfig
    self.agents = agents
    self.pluginDirectory = pluginDirectory
    self.temperature = temperature
    self.yolo = yolo
    self.yoloTimeout = yoloTimeout
    self.features = features
    self.autohandAIAPIKey = autohandAIAPIKey
    self.autohandAIBaseURL = autohandAIBaseURL
    self.autohandAIPlan = autohandAIPlan
    self.extraArguments = extraArguments
    self.environment = environment
  }

  public var cliArguments: [String] {
    var arguments = ["--mode", "rpc"]
    if bare == true { arguments.append("--bare") }
    if unrestricted == true { arguments.append("--unrestricted") }
    if autoMode == true { arguments.append("--auto-mode") }
    if autoSkill == true { arguments.append("--auto-skill") }
    if autoCommit == true { arguments.append("-c") }
    if idleLogout == false { arguments.append("--no-idle-logout") }
    if contextCompact == false { arguments.append("--no-context-compact") }
    if contextCompact == true { arguments.append("--context-compact") }
    if persistSession == true { arguments.append("--persist-session") }
    append(&arguments, flag: "--session-id", value: sessionId)
    if resume == true { arguments.append("--resume") }
    if continueSession == true { arguments.append("--continue") }
    append(&arguments, flag: "--fork", value: fork)
    append(&arguments, flag: "--session-path", value: sessionPath)
    append(&arguments, flag: "--auto-save-interval", value: autoSaveInterval)
    if agentsMdEnabled == false { arguments.append("--no-agents-md") }
    if agentsMdEnabled == true { arguments.append("--agents-md") }
    if agentsMdCreate == true { arguments.append("--agents-md-create") }
    append(&arguments, flag: "--agents-md-path", value: agentsMdPath)
    if agentsMdAutoUpdate == true { arguments.append("--agents-md-auto-update") }
    append(&arguments, flag: "--max-tokens", value: maxTokens)
    append(&arguments, flag: "--compression-threshold", value: compressionThreshold)
    append(&arguments, flag: "--summarization-threshold", value: summarizationThreshold)
    if !skills.isEmpty {
      arguments.append(contentsOf: ["--skills", skills.joined(separator: ",")])
    }
    if !skillSources.isEmpty {
      arguments.append(contentsOf: ["--skill-sources", skillSources.joined(separator: ",")])
    }
    if installMissingSkills == true { arguments.append("--install-missing-skills") }
    append(&arguments, flag: "--max-iterations", value: maxIterations)
    append(&arguments, flag: "--max-runtime", value: maxRuntime)
    append(&arguments, flag: "--max-cost", value: maxCost)
    append(&arguments, flag: "--display-language", value: displayLanguage)
    append(&arguments, flag: "--model", value: model)
    append(&arguments, flag: "--sys-prompt", value: systemPrompt)
    append(&arguments, flag: "--system-prompt-file", value: systemPromptFile)
    append(&arguments, flag: "--append-sys-prompt", value: appendSystemPrompt)
    append(&arguments, flag: "--append-system-prompt-file", value: appendSystemPromptFile)
    append(&arguments, flag: "--mcp-config", value: mcpConfig)
    append(&arguments, flag: "--agents", value: agents)
    append(&arguments, flag: "--plugin-dir", value: pluginDirectory)
    append(&arguments, flag: "--temperature", value: temperature)
    append(&arguments, flag: "--yolo", value: yolo)
    append(&arguments, flag: "--yolo-timeout", value: yoloTimeout)
    arguments.append(contentsOf: extraArguments)
    return arguments
  }

  private func append(_ arguments: inout [String], flag: String, value: String?) {
    guard let value, !value.isEmpty else { return }
    arguments.append(contentsOf: [flag, value])
  }

  private func append<T>(_ arguments: inout [String], flag: String, value: T?) {
    guard let value else { return }
    arguments.append(contentsOf: [flag, String(describing: value)])
  }

  var cliEnvironment: [String: String] {
    var values = environment
    if let autohandAIAPIKey { values["AUTOHAND_AI_API_KEY"] = autohandAIAPIKey }
    if let autohandAIBaseURL { values["AUTOHAND_AI_BASE_URL"] = autohandAIBaseURL }
    if let autohandAIPlan { values["AUTOHAND_AI_PLAN"] = autohandAIPlan }
    return values
  }
}

public enum AutohandCLIClientError: Error, Sendable, LocalizedError {
  case alreadyRunning
  case notRunning
  case launchFailed(String)
  case transport(String)
  case timeout(method: String, seconds: TimeInterval)
  case invalidResponse(String)
  case rpc(method: String, code: Int, message: String)

  public var errorDescription: String? {
    switch self {
    case .alreadyRunning: return "The Autohand CLI process is already running."
    case .notRunning: return "The Autohand CLI process is not running."
    case .launchFailed(let message): return "Unable to launch the Autohand CLI: \(message)"
    case .transport(let message): return "Autohand CLI transport failed: \(message)"
    case .timeout(let method, let seconds):
      return "RPC method \(method) timed out after \(seconds) seconds."
    case .invalidResponse(let message): return "Invalid Autohand CLI response: \(message)"
    case .rpc(let method, let code, let message):
      return "RPC method \(method) failed (\(code)): \(message)"
    }
  }
}

private struct EmptyParameters: Codable, Sendable {}

private struct PromptParameters: Codable, Sendable {
  let message: String
}

public struct AutohandPromptResult: Codable, Sendable {
  public let success: Bool
}

public struct AutohandApplyFlagSettingsResult: Codable, Sendable {
  public let success: Bool?
  public let ok: Bool?
}

private struct SupportedCommandsResult: Codable, Sendable {
  let commands: [String]
}

private struct FeatureSettingsContainer: Codable, Sendable {
  let features: AutohandFeatureFlagSettings
}

private struct ApplyFlagSettingsParameters: Codable, Sendable {
  let settings: FeatureSettingsContainer
}

private struct AutoresearchLifecyclePayload: Codable, Sendable {
  let active: Bool
  let goal: String?
  let iteration: Int?
  let maxIterations: Int?
  let runsLogged: Int
  let statusText: String
  let subcommand: String
  let message: String?
  let timestamp: String
}

/// macOS JSON-RPC client for the Autohand CLI subprocess.
///
/// Existing provider-backed `Agent` and `Runner` APIs remain cross-platform;
/// this client is the opt-in CLI surface for command and autoresearch parity.
@available(
  iOS, unavailable, message: "The Autohand CLI subprocess is available on macOS hosts only."
)
public final class AutohandCLIClient: @unchecked Sendable {
  public typealias EventHandler = @Sendable (AutohandCLIEvent) -> Void

  private let configuration: AutohandCLIConfiguration
  private let eventHandler: EventHandler?
  private let promptGate = RequestGate()
  private let lifecycleLock = NSLock()
  private let stateLock = NSLock()
  private let inputLock = NSLock()
  private var nextID = 0
  private var process: Process?
  private var input: FileHandle?
  private var output: FileHandle?
  private var responseRouter: ResponseRouter?

  public init(configuration: AutohandCLIConfiguration = .init(), onEvent: EventHandler? = nil) {
    self.configuration = configuration
    self.eventHandler = onEvent
  }

  public var isRunning: Bool {
    stateLock.withLock {
      process?.isRunning == true && responseRouter?.isFinished == false
    }
  }

  public func start() throws {
    lifecycleLock.lock()
    defer { lifecycleLock.unlock() }

    let existing = stateLock.withLock { (process, responseRouter) }
    if let existingProcess = existing.0 {
      guard !existingProcess.isRunning || existing.1?.isFinished == true else {
        throw AutohandCLIClientError.alreadyRunning
      }
      closeGeneration()
    }

    let responses = ResponseRouter()
    try stateLock.withLock {
      guard process == nil else { throw AutohandCLIClientError.alreadyRunning }

      let process = Process()
      let stdinPipe = Pipe()
      let stdoutPipe = Pipe()
      let stderrPipe = Pipe()

      if let cliPath = configuration.cliPath, !cliPath.isEmpty {
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = configuration.cliArguments
      } else {
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["autohand"] + configuration.cliArguments
      }
      process.currentDirectoryURL = URL(fileURLWithPath: configuration.cwd)
      process.standardInput = stdinPipe
      process.standardOutput = stdoutPipe
      process.standardError = stderrPipe
      process.environment = ProcessInfo.processInfo.environment.merging(
        ["AUTOHAND_STREAM_TOOL_OUTPUT": "1"], uniquingKeysWith: { _, new in new }
      ).merging(configuration.cliEnvironment, uniquingKeysWith: { _, new in new })

      stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self, responses] handle in
        let data = handle.availableData
        if data.isEmpty {
          responses.finish()
        } else {
          responses.append(data) { line in
            self?.handleNotificationLine(line)
          }
        }
      }
      let debug = configuration.debug
      stderrPipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        guard debug, !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
        FileHandle.standardError.write(Data("[autohand-cli] \(text)".utf8))
      }
      process.terminationHandler = { [responses] _ in responses.finish() }

      do {
        try process.run()
      } catch {
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        throw AutohandCLIClientError.launchFailed(error.localizedDescription)
      }

      self.process = process
      self.input = stdinPipe.fileHandleForWriting
      self.output = stdoutPipe.fileHandleForReading
      self.responseRouter = responses
    }
    do {
      if let features = configuration.features {
        let _: AutohandApplyFlagSettingsResult = try requestBlocking(
          method: "autohand.applyFlagSettings",
          parameters: ApplyFlagSettingsParameters(settings: .init(features: features)))
      }
    } catch {
      closeGeneration()
      throw error
    }
  }

  public func close() {
    lifecycleLock.withLock {
      closeGeneration()
    }
  }

  private func closeGeneration() {
    let owned: (
      process: Process?, input: FileHandle?, output: FileHandle?, responses: ResponseRouter?
    ) = inputLock.withLock {
      stateLock.withLock {
        let owned = (process, input, output, responseRouter)
        self.process = nil
        self.input = nil
        self.output = nil
        self.responseRouter = nil
        return owned
      }
    }

    owned.output?.readabilityHandler = nil
    inputLock.withLock {
      try? owned.input?.close()
    }
    owned.responses?.finish()

    if let process = owned.process, process.isRunning {
      process.terminate()
      let deadline = Date().addingTimeInterval(2)
      while process.isRunning && deadline.timeIntervalSinceNow > 0 {
        Thread.sleep(forTimeInterval: 0.01)
      }
      #if os(macOS)
        if process.isRunning {
          _ = Darwin.kill(process.processIdentifier, SIGKILL)
        }
      #endif
      process.waitUntilExit()
    }
  }

  deinit {
    close()
  }

  public func prompt(_ message: String) async throws -> AutohandPromptResult {
    try await request(method: "autohand.prompt", parameters: PromptParameters(message: message))
  }

  public func command(_ command: String, arguments: String? = nil) async throws
    -> AutohandPromptResult
  {
    let normalized = command.hasPrefix("/") ? command : "/\(command)"
    let suffix = arguments.flatMap { $0.isEmpty ? nil : " \($0)" } ?? ""
    return try await prompt(normalized + suffix)
  }

  public func deepResearch(_ topic: String) async throws -> AutohandPromptResult {
    try await command("/deep-research", arguments: topic)
  }

  public func autoresearch(_ objective: String) async throws -> AutohandPromptResult {
    try await command("/autoresearch", arguments: objective)
  }

  public func supportedCommands() async throws -> [String] {
    let result: SupportedCommandsResult = try await request(
      method: "autohand.getSupportedCommands", parameters: EmptyParameters())
    return result.commands.map { $0.hasPrefix("/") ? $0 : "/\($0)" }
  }

  public func supportsCommand(_ command: String) async throws -> Bool {
    let normalized = command.hasPrefix("/") ? command : "/\(command)"
    return try await supportedCommands().contains(normalized)
  }

  public func applyFeatureSettings(
    _ features: AutohandFeatureFlagSettings
  ) async throws -> AutohandApplyFlagSettingsResult {
    try await request(
      method: "autohand.applyFlagSettings",
      parameters: ApplyFlagSettingsParameters(settings: .init(features: features)))
  }

  public func getSkillsRegistry(
    _ parameters: GetSkillsRegistryParameters = .init()
  ) async throws -> GetSkillsRegistryResult {
    try await request(method: "autohand.getSkillsRegistry", parameters: parameters)
  }

  public func installSkill(_ parameters: InstallSkillParameters) async throws
    -> InstallSkillResult
  {
    try await request(method: "autohand.installSkill", parameters: parameters)
  }

  public func listMCPServers() async throws -> MCPListServersResult {
    try await request(method: "autohand.mcp.listServers", parameters: EmptyParameters())
  }

  public func listMCPTools(
    _ parameters: MCPListToolsParameters = .init()
  ) async throws -> MCPListToolsResult {
    try await request(method: "autohand.mcp.listTools", parameters: parameters)
  }

  public func getMCPServerConfigs() async throws -> MCPGetServerConfigsResult {
    try await request(method: "autohand.mcp.getServerConfigs", parameters: EmptyParameters())
  }

  public func reset() async throws -> ConversationResetResult {
    try await request(method: "autohand.reset", parameters: EmptyParameters())
  }

  public func createBrowserHandoff(
    _ parameters: BrowserHandoffCreateParameters = .init()
  ) async throws -> BrowserHandoffCreateResult {
    try await request(method: "autohand.browserHandoff.create", parameters: parameters)
  }

  public func attachBrowserHandoff(
    _ parameters: BrowserHandoffAttachParameters
  ) async throws -> BrowserHandoffAttachResult {
    try await request(method: "autohand.browserHandoff.attach", parameters: parameters)
  }

  public func attachLatestBrowserHandoff() async throws -> BrowserHandoffAttachResult {
    try await request(
      method: "autohand.browserHandoff.attachLatest", parameters: EmptyParameters())
  }

  public func startAutoMode(
    _ parameters: AutoModeStartParameters
  ) async throws -> AutoModeStartResult {
    try await request(method: "autohand.automode.start", parameters: parameters)
  }

  public func autoModeStatus() async throws -> AutoModeStatusResult {
    try await request(method: "autohand.automode.status", parameters: EmptyParameters())
  }

  public func pauseAutoMode() async throws -> AutoModeOperationResult {
    try await request(method: "autohand.automode.pause", parameters: EmptyParameters())
  }

  public func resumeAutoMode() async throws -> AutoModeOperationResult {
    try await request(method: "autohand.automode.resume", parameters: EmptyParameters())
  }

  public func goal() async throws -> GoalSnapshotResult {
    try await request(method: "autohand.goal.get", parameters: EmptyParameters())
  }

  public func createGoal(_ parameters: GoalCreateParameters) async throws -> GoalMutationRPCResult {
    try await request(method: "autohand.goal.create", parameters: parameters)
  }

  public func updateGoal(_ parameters: GoalUpdateParameters) async throws -> GoalMutationRPCResult {
    try await request(method: "autohand.goal.update", parameters: parameters)
  }

  public func clearGoal() async throws -> GoalMutationRPCResult {
    try await request(method: "autohand.goal.clear", parameters: EmptyParameters())
  }

  public func queueGoal(_ parameters: GoalCreateParameters) async throws -> GoalMutationRPCResult {
    try await request(method: "autohand.goal.queue", parameters: parameters)
  }

  public func startQueuedGoal() async throws -> GoalMutationRPCResult {
    try await request(method: "autohand.goal.startQueued", parameters: EmptyParameters())
  }

  public func goalTemplates() async throws -> GoalTemplatesResult {
    try await request(method: "autohand.goal.listTemplates", parameters: EmptyParameters())
  }

  public func startAutoresearch(_ parameters: AutoresearchStartParameters) async throws
    -> AutoresearchStartResult
  {
    try await request(method: "autohand.autoresearch.start", parameters: parameters)
  }

  public func autoresearchStatus() async throws -> AutoresearchStatusResult {
    try await request(method: "autohand.autoresearch.status", parameters: EmptyParameters())
  }

  public func stopAutoresearch() async throws -> AutoresearchStopResult {
    try await request(method: "autohand.autoresearch.stop", parameters: EmptyParameters())
  }

  public func autoresearchHistory() async throws -> AutoresearchHistoryResult {
    try await request(method: "autohand.autoresearch.history", parameters: EmptyParameters())
  }

  public func replayAutoresearch(_ parameters: AutoresearchReplayParameters) async throws
    -> AutoresearchReplayResult
  {
    try await request(method: "autohand.autoresearch.replay", parameters: parameters)
  }

  public func rescoreAutoresearch(_ parameters: AutoresearchRescoreParameters) async throws
    -> AutoresearchRescoreResult
  {
    try await request(method: "autohand.autoresearch.rescore", parameters: parameters)
  }

  public func compareAutoresearch(_ parameters: AutoresearchCompareParameters) async throws
    -> AutoresearchCompareResult
  {
    try await request(method: "autohand.autoresearch.compare", parameters: parameters)
  }

  public func autoresearchPareto() async throws -> AutoresearchParetoResult {
    try await request(method: "autohand.autoresearch.pareto", parameters: EmptyParameters())
  }

  public func pinAutoresearch(_ parameters: AutoresearchPinParameters) async throws
    -> AutoresearchPinResult
  {
    try await request(method: "autohand.autoresearch.pin", parameters: parameters)
  }

  public func pruneAutoresearch(
    _ parameters: AutoresearchPruneParameters = .init()
  ) async throws -> AutoresearchPruneResult {
    try await request(method: "autohand.autoresearch.prune", parameters: parameters)
  }

  private func request<Parameters: Encodable & Sendable, Result: Decodable & Sendable>(
    method: String,
    parameters: Parameters
  ) async throws -> Result {
    let cancellation = RequestCancellation()
    return try await withTaskCancellationHandler {
      try Task.checkCancellation()
      return try await Task.detached { [self, cancellation] in
        try requestBlocking(
          method: method, parameters: parameters, cancellation: cancellation)
      }.value
    } onCancel: {
      cancellation.cancel()
      promptGate.wake()
    }
  }

  private func requestBlocking<Parameters: Encodable, Result: Decodable>(
    method: String,
    parameters: Parameters,
    cancellation: RequestCancellation? = nil
  ) throws -> Result {
    let gate = method == "autohand.prompt" ? promptGate : nil
    if let gate {
      guard gate.acquire(cancellation: cancellation) else { throw CancellationError() }
    }
    defer { gate?.release() }

    if cancellation?.isCancelled == true { throw CancellationError() }
    let id = stateLock.withLock { () -> Int in
      nextID += 1
      return nextID
    }
    let parameterData = try JSONEncoder().encode(parameters)
    let parameterObject = try JSONSerialization.jsonObject(with: parameterData)
    let request: [String: Any] = [
      "jsonrpc": "2.0",
      "id": id,
      "method": method,
      "params": parameterObject,
    ]
    var encoded = try JSONSerialization.data(withJSONObject: request)
    encoded.append(0x0A)
    let connection = try inputLock.withLock {
      try stateLock.withLock { () throws -> (input: FileHandle, responses: ResponseRouter) in
        guard process?.isRunning == true, let input, let responseRouter else {
          throw AutohandCLIClientError.notRunning
        }
        return (input, responseRouter)
      }
    }
    let responses = connection.responses
    responses.register(id: id)
    defer { responses.unregister(id: id) }
    cancellation?.bind(responses: responses)
    defer { cancellation?.unbind(responses: responses) }
    if cancellation?.isCancelled == true { throw CancellationError() }
    do {
      try inputLock.withLock {
        let input = try stateLock.withLock { () throws -> FileHandle in
          guard process?.isRunning == true,
            self.input === connection.input,
            responseRouter === responses
          else {
            throw AutohandCLIClientError.notRunning
          }
          return connection.input
        }
        try input.write(contentsOf: encoded)
      }
    } catch {
      if error is AutohandCLIClientError { throw error }
      throw AutohandCLIClientError.transport(error.localizedDescription)
    }

    let deadline = Date().addingTimeInterval(max(configuration.timeout, 0.001))
    switch responses.take(id: id, until: deadline, cancellation: cancellation) {
    case .line(let line):
      guard let object = try JSONSerialization.jsonObject(with: line) as? [String: Any] else {
        throw AutohandCLIClientError.invalidResponse("Invalid JSON-RPC response for \(method)")
      }
      if let error = object["error"] as? [String: Any] {
        throw AutohandCLIClientError.rpc(
          method: method,
          code: error["code"] as? Int ?? 0,
          message: error["message"] as? String ?? "Unknown RPC error")
      }
      guard let result = object["result"] else {
        throw AutohandCLIClientError.invalidResponse("Missing result for \(method)")
      }
      let data = try JSONSerialization.data(withJSONObject: result)
      return try JSONDecoder().decode(Result.self, from: data)
    case .cancelled:
      throw CancellationError()
    case .finished:
      throw AutohandCLIClientError.transport("CLI stdout closed while waiting for \(method)")
    case .timeout:
      throw AutohandCLIClientError.timeout(method: method, seconds: configuration.timeout)
    }
  }

  private func handleNotificationLine(_ line: Data) {
    guard let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
      let method = object["method"] as? String,
      object["id"] == nil
    else { return }
    handleNotification(method: method, parameters: object["params"])
  }

  private func handleNotification(method: String, parameters: Any?) {
    guard let eventHandler,
      let parameters = parameters as? [String: Any],
      JSONSerialization.isValidJSONObject(parameters),
      let data = try? JSONSerialization.data(withJSONObject: parameters)
    else { return }

    switch method {
    case "autohand.turnEnd":
      guard let event = try? JSONDecoder().decode(AutohandTurnEndEvent.self, from: data) else {
        return
      }
      eventHandler(.turnEnd(event))
    case "autohand.autoresearch.start", "autohand.autoresearch.status",
      "autohand.autoresearch.pause":
      guard
        let payload = try? JSONDecoder().decode(AutoresearchLifecyclePayload.self, from: data)
      else {
        return
      }
      let phase = method.split(separator: ".").last.map(String.init) ?? "status"
      eventHandler(
        .autoresearchLifecycle(
          .init(
            phase: phase,
            active: payload.active,
            goal: payload.goal,
            iteration: payload.iteration,
            maxIterations: payload.maxIterations,
            runsLogged: payload.runsLogged,
            statusText: payload.statusText,
            subcommand: payload.subcommand,
            message: payload.message,
            timestamp: payload.timestamp)))
    case "autohand.autoresearch.event":
      guard let event = try? JSONDecoder().decode(AutoresearchOperationEvent.self, from: data)
      else {
        return
      }
      eventHandler(.autoresearchOperation(event))
    default:
      let payload = (try? JSONDecoder().decode([String: AnyCodable].self, from: data)) ?? [:]
      eventHandler(
        .notification(
          method: method, payload: payload, timestamp: parameters["timestamp"] as? String))
    }
  }
}

private final class RequestCancellation: @unchecked Sendable {
  private let lock = NSLock()
  private var cancelled = false
  private weak var responses: ResponseRouter?

  var isCancelled: Bool { lock.withLock { cancelled } }

  func cancel() {
    let responses = lock.withLock { () -> ResponseRouter? in
      cancelled = true
      return self.responses
    }
    responses?.wake()
  }

  func bind(responses: ResponseRouter) {
    let alreadyCancelled = lock.withLock { () -> Bool in
      self.responses = responses
      return cancelled
    }
    if alreadyCancelled { responses.wake() }
  }

  func unbind(responses: ResponseRouter) {
    lock.withLock {
      if self.responses === responses { self.responses = nil }
    }
  }
}

private final class RequestGate: @unchecked Sendable {
  private let condition = NSCondition()
  private var occupied = false

  func acquire(cancellation: RequestCancellation?) -> Bool {
    condition.lock()
    defer { condition.unlock() }
    while occupied && cancellation?.isCancelled != true {
      condition.wait()
    }
    guard cancellation?.isCancelled != true else { return false }
    occupied = true
    return true
  }

  func release() {
    condition.lock()
    occupied = false
    condition.broadcast()
    condition.unlock()
  }

  func wake() {
    condition.lock()
    condition.broadcast()
    condition.unlock()
  }
}

private enum ResponseWaitResult {
  case line(Data)
  case cancelled
  case finished
  case timeout
}

/// Frames stdout once and dispatches responses by JSON-RPC ID.
///
/// A caller may abandon its waiter without leaving a stale response for the
/// next request. Notifications are delivered independently of request waits.
private final class ResponseRouter: @unchecked Sendable {
  private let condition = NSCondition()
  private let appendLock = NSLock()
  private var buffer = Data()
  private var pending: Set<Int> = []
  private var responses: [Int: Data] = [:]
  private var finished = false

  var isFinished: Bool {
    condition.withLock { finished }
  }

  func append(_ data: Data, onNotification: (Data) -> Void) {
    appendLock.withLock {
      var framed: [Data] = []
      condition.lock()
      buffer.append(data)
      while let newline = buffer.firstIndex(of: 0x0A) {
        framed.append(buffer.prefix(upTo: newline))
        buffer.removeSubrange(...newline)
      }
      condition.unlock()

      for line in framed {
        guard let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any]
        else { continue }
        if let id = object["id"] as? Int {
          condition.lock()
          if pending.contains(id) {
            responses[id] = line
            condition.broadcast()
          }
          condition.unlock()
        } else if object["method"] is String {
          onNotification(line)
        }
      }
    }
  }

  func register(id: Int) {
    condition.lock()
    pending.insert(id)
    responses.removeValue(forKey: id)
    condition.unlock()
  }

  func unregister(id: Int) {
    condition.lock()
    pending.remove(id)
    responses.removeValue(forKey: id)
    condition.unlock()
  }

  func take(
    id: Int,
    until deadline: Date,
    cancellation: RequestCancellation?
  ) -> ResponseWaitResult {
    condition.lock()
    defer { condition.unlock() }
    while responses[id] == nil && !finished && cancellation?.isCancelled != true
      && deadline.timeIntervalSinceNow > 0
    {
      condition.wait(until: deadline)
    }
    if let line = responses.removeValue(forKey: id) { return .line(line) }
    if cancellation?.isCancelled == true { return .cancelled }
    if finished { return .finished }
    return .timeout
  }

  func wake() {
    condition.lock()
    condition.broadcast()
    condition.unlock()
  }

  func finish() {
    condition.lock()
    finished = true
    condition.broadcast()
    condition.unlock()
  }

}
