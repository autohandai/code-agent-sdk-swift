import Foundation
import Testing
@testable import AgentSDK

@Suite struct RuntimeSettingsTests {
  @Test func nativeProviderFields() throws {
    for provider in ["anthropic", "openai", "xai", "azure", "bedrock", "vertexai", "custom:My.Provider", "extension:team.provider:model"] {
      let config = AutohandCLIConfiguration(provider: provider, apiKey: "secret", baseURL: "https://fixture.test")
      let settings = try config.runtimeSettings()
      let section = provider.hasPrefix("custom:") ? (settings["customProviders"] as? [String: Any])?["My.Provider"] as? [String: Any]
        : provider.hasPrefix("extension:") ? (settings["extensionProviders"] as? [String: Any])?[provider] as? [String: Any]
        : settings[provider] as? [String: Any]
      #expect(section?[provider == "vertexai" ? "authToken" : "apiKey"] as? String == "secret")
      #expect(section?[provider == "bedrock" || provider == "vertexai" ? "endpoint" : "baseUrl"] as? String == (provider == "vertexai" ? "fixture.test" : "https://fixture.test"))
      if ["openai", "xai"].contains(provider) { #expect(section?["authMode"] as? String == "api-key") }
      if provider == "azure" { #expect(section?["authMethod"] as? String == "api-key") }
      if provider == "bedrock" { #expect(section?["authMode"] as? String == "bedrock-api-key") }
    }
  }
  @Test func preservesDefaultsAndJSON() throws {
    let config = AutohandCLIConfiguration(provider: "autohandai", features: .init(slashGoal: false),
      runSettings: ["customProviders": AnyCodable(["My.Provider": ["models": [NSNull(), "one"]]])])
    let settings = try config.runtimeSettings()
    #expect(settings["autohandai"] == nil)
    #expect((settings["features"] as? [String: Any])?["slashGoal"] as? Bool == false)
    #expect((settings["customProviders"] as? [String: Any])?["My.Provider"] != nil)
    #expect(config.cliEnvironment["AUTOHAND_AI_PLAN"] == nil)
  }
  @Test func rejectsUnsafeOrAmbiguousConfiguration() {
    #expect(throws: (any Error).self) { try AutohandCLIConfiguration(apiKey: "secret").runtimeSettings() }
    #expect(throws: (any Error).self) { try AutohandCLIConfiguration(provider: "vertexai", baseURL: "https://user:secret@fixture.test/v1").runtimeSettings() }
    #expect(throws: (any Error).self) { try AutohandCLIConfiguration(runSettings: ["features": AnyCodable(["constructor": true])]).runtimeSettings() }
  }
  @Test func translatesCurrentSessionArguments() {
    #expect(AutohandCLIConfiguration(persistSession: true, sessionId: "saved").cliArguments == ["--mode","rpc","--sdk-session-reference","saved"])
    #expect(AutohandCLIConfiguration(resume: true).cliArguments == ["--mode","rpc","--sdk-resume-last"])
    #expect(AutohandCLIConfiguration(fork: "saved", sessionId: "saved").cliArguments == ["--mode","rpc","--fork","saved"])
  }

}
