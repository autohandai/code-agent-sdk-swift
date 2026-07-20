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

  public var isRunning: Bool { client.isRunning }

  public func start() throws {
    try client.start()
  }

  public func close() {
    client.close()
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
}
