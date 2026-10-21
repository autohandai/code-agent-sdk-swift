import Foundation

/// High-level lifecycle and discovery facade for the Autohand CLI subprocess.
///
/// Use `AutohandCLIClient` when direct access to every RPC operation is useful.
/// Use this facade when an application wants one public SDK object that owns the
/// client lifecycle.
@available(
  iOS, unavailable, message: "The Autohand CLI subprocess is available on macOS hosts only."
)
public final class AutohandSDK: @unchecked Sendable {
  public let client: AutohandCLIClient

  public init(
    configuration: AutohandCLIConfiguration = .init(),
    onEvent: AutohandCLIClient.EventHandler? = nil
  ) {
    client = AutohandCLIClient(configuration: configuration, onEvent: onEvent)
  }

  /// Observe exact CLI packets independently of typed run events.
  @discardableResult
  public func onNotification(_ callback: @escaping AutohandCLIClient.NotificationHandler) -> @Sendable () -> Void {
    client.onNotification(callback)
  }

  public var isRunning: Bool { client.isRunning }

  public func start() throws {
    try client.start()
  }

  public func close() {
    client.close()
  }

  public func send(_ message: String, options: AutohandPromptOptions = .init()) -> AutohandRun {
    client.send(message, options: options)
  }

  public func run(_ message: String, options: AutohandPromptOptions = .init()) async throws -> AutohandRunResult {
    try await client.run(message, options: options)
  }

  public func rpc(_ method: String, parameters: [String: AnyCodable] = [:]) async throws -> [String: AnyCodable] {
    try await client.rpc(method, parameters: parameters)
  }
  public func setBrowserCapabilities(protocolVersion: Int, extensionVersion: String? = nil,
    tools: [String]) async throws -> [String: AnyCodable] {
    try await client.setBrowserCapabilities(protocolVersion: protocolVersion, extensionVersion: extensionVersion, tools: tools)
  }
  public func getState() async throws -> [String: AnyCodable] { try await client.getState() }
  public func getMessages() async throws -> [String: AnyCodable] { try await client.getMessages() }
  public func getSupportedModels() async throws -> [String: AnyCodable] { try await client.getSupportedModels() }
  public func getContextUsage() async throws -> [String: AnyCodable] { try await client.getContextUsage() }
  public func reloadPlugins() async throws -> [String: AnyCodable] { try await client.reloadPlugins() }
  public func getAccountInfo() async throws -> [String: AnyCodable] { try await client.getAccountInfo() }
  public func setPermissionMode(_ value: String) async throws -> [String: AnyCodable] { try await client.setPermissionMode(value) }
  public func setMaxThinkingTokens(_ value: Int?) async throws -> [String: AnyCodable] { try await client.setMaxThinkingTokens(value) }
  public func setModel(_ value: String) async throws -> [String: AnyCodable] { try await client.setModel(value) }
  public func reconnectMCPServer(_ value: String) async throws -> [String: AnyCodable] { try await client.reconnectMCPServer(value) }
  public func setPlanMode(_ value: Bool) async throws -> [String: AnyCodable] { try await client.setPlanMode(value) }
  public func setMCPServers(_ value: [String: AnyCodable]) async throws -> [String: AnyCodable] { try await client.setMCPServers(value) }
  public func respondToPermission(_ value: [String: AnyCodable]) async throws -> [String: AnyCodable] { try await client.respondToPermission(value) }
  public func toggleMCPServer(_ name: String, enabled: Bool) async throws -> [String: AnyCodable] {
    try await client.toggleMCPServer(name, enabled: enabled)
  }

  public func supportedAgents() async throws -> [AgentInfo] {
    try await client.supportedAgents()
  }

  public func getSkillsRegistry(
    _ parameters: GetSkillsRegistryParameters = .init()
  ) async throws -> GetSkillsRegistryResult {
    try await client.getSkillsRegistry(parameters)
  }

  public func installSkill(_ parameters: InstallSkillParameters) async throws
    -> InstallSkillResult
  {
    try await client.installSkill(parameters)
  }

  public func listMCPServers() async throws -> MCPListServersResult {
    try await client.listMCPServers()
  }

  public func listMCPTools(
    _ parameters: MCPListToolsParameters = .init()
  ) async throws -> MCPListToolsResult {
    try await client.listMCPTools(parameters)
  }

  public func getMCPServerConfigs() async throws -> MCPGetServerConfigsResult {
    try await client.getMCPServerConfigs()
  }

  public func reset() async throws -> ConversationResetResult {
    try await client.reset()
  }

  public func acknowledgePermission(
    _ parameters: PermissionAcknowledgementParameters
  ) async throws -> PermissionAcknowledgementResult {
    try await client.acknowledgePermission(parameters)
  }

  public func respondToDirectoryAccess(
    _ parameters: DirectoryAccessResponseParameters
  ) async throws -> DirectoryAccessResponseResult {
    try await client.respondToDirectoryAccess(parameters)
  }

  public func acknowledgeDirectoryAccess(
    _ parameters: DirectoryAccessAcknowledgementParameters
  ) async throws -> DirectoryAccessAcknowledgementResult {
    try await client.acknowledgeDirectoryAccess(parameters)
  }

  public func decideChanges(
    _ parameters: ChangesDecisionParameters
  ) async throws -> ChangesDecisionResult {
    try await client.decideChanges(parameters)
  }

  public func sessionHistory(
    _ parameters: SessionHistoryParameters = .init()
  ) async throws -> SessionHistoryResult {
    try await client.sessionHistory(parameters)
  }

  public func sessionDetails(
    _ parameters: SessionDetailsParameters
  ) async throws -> SessionDetailsResult {
    try await client.sessionDetails(parameters)
  }

  public func attachSession(
    _ parameters: SessionAttachParameters
  ) async throws -> SessionAttachResult {
    try await client.attachSession(parameters)
  }

  public func setYoloMode(
    _ parameters: YoloSetParameters,
    useCompatibilityAlias: Bool = false
  ) async throws -> YoloSetResult {
    try await client.setYoloMode(parameters, useCompatibilityAlias: useCompatibilityAlias)
  }

  public func registerVscodeMCPTools(
    _ parameters: MCPSetVscodeToolsParameters
  ) async throws -> MCPSetVscodeToolsResult {
    try await client.registerVscodeMCPTools(parameters)
  }

  public func completeMCPInvocation(
    _ parameters: MCPInvokeResponseParameters
  ) async throws -> MCPInvokeResponseResult {
    try await client.completeMCPInvocation(parameters)
  }

  public func recommendProjectLearning(
    _ parameters: LearnRecommendParameters = .init()
  ) async throws -> LearnRecommendResult {
    try await client.recommendProjectLearning(parameters)
  }

  public func updateProjectLearning() async throws -> LearnUpdateResult {
    try await client.updateProjectLearning()
  }

  public func generateProjectLearning(
    _ parameters: LearnGenerateParameters
  ) async throws -> LearnGenerateResult {
    try await client.generateProjectLearning(parameters)
  }

  public func toolsRegistry() async throws -> ToolsRegistryResult {
    try await client.toolsRegistry()
  }

  public func setContextCompaction(
    _ parameters: ContextCompactionParameters
  ) async throws -> ContextCompactionResult {
    try await client.setContextCompaction(parameters)
  }

  public func createBrowserHandoff(
    _ parameters: BrowserHandoffCreateParameters = .init()
  ) async throws -> BrowserHandoffCreateResult {
    try await client.createBrowserHandoff(parameters)
  }

  public func attachBrowserHandoff(
    _ parameters: BrowserHandoffAttachParameters
  ) async throws -> BrowserHandoffAttachResult {
    try await client.attachBrowserHandoff(parameters)
  }

  public func attachLatestBrowserHandoff() async throws -> BrowserHandoffAttachResult {
    try await client.attachLatestBrowserHandoff()
  }

  public func startAutoMode(
    _ parameters: AutoModeStartParameters
  ) async throws -> AutoModeStartResult {
    try await client.startAutoMode(parameters)
  }

  public func autoModeStatus() async throws -> AutoModeStatusResult {
    try await client.autoModeStatus()
  }

  public func pauseAutoMode() async throws -> AutoModeOperationResult {
    try await client.pauseAutoMode()
  }

  public func resumeAutoMode() async throws -> AutoModeOperationResult {
    try await client.resumeAutoMode()
  }

  public func cancelAutoMode(
    _ parameters: AutoModeCancelParameters = .init()
  ) async throws -> AutoModeOperationResult {
    try await client.cancelAutoMode(parameters)
  }

  public func autoModeLog(
    _ parameters: AutoModeLogParameters = .init()
  ) async throws -> AutoModeLogResult {
    try await client.autoModeLog(parameters)
  }
}
