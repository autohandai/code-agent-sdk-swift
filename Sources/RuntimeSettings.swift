import Foundation

extension AutohandCLIConfiguration {
  var needsRuntimeSettings: Bool {
    features != nil || runSettings != nil || (provider != nil && provider != "autohandai"
      && (apiKey != nil || baseURL != nil || port != nil))
  }

  /// Build the CLI's run-only overlay before launching its runtime.
  func runtimeSettings() throws -> [String: Any] {
    var settings = try copySettingsJSON(runSettings?.mapValues(\.value) ?? [:]) as? [String: Any] ?? [:]
    if let features {
      let value = try JSONSerialization.jsonObject(with: JSONEncoder().encode(features))
      mergeSettings(&settings, ["features": value])
    }
    guard let provider else {
      if apiKey != nil || baseURL != nil || port != nil {
        throw AgentSDKError.agentConfig(message: "A provider is required for provider credentials and settings")
      }
      return settings
    }
    let key = apiKey ?? (provider == "autohandai" ? autohandAIAPIKey : nil)
    let url = baseURL ?? (provider == "autohandai" ? autohandAIBaseURL : nil)
    var section: [String: Any] = [:]
    if let model { section["model"] = model }
    if let key {
      section[provider == "vertexai" ? "authToken" : "apiKey"] = key
      if ["autohandai", "openai", "xai"].contains(provider) { section["authMode"] = "api-key" }
      if provider == "azure" { section["authMethod"] = "api-key" }
      if provider == "bedrock" { section["authMode"] = "bedrock-api-key" }
    }
    if let url {
      section[["vertexai", "bedrock"].contains(provider) ? "endpoint" : "baseUrl"] = provider == "vertexai" ? try vertexEndpoint(url) : url
    } else if let port, ["ollama", "llamacpp", "mlx"].contains(provider) {
      section["baseUrl"] = "http://localhost:\(port)"
    }
    if provider == "autohandai" {
      if let autohandAIPlan { section["plan"] = autohandAIPlan }
      else if (key != nil || url != nil) && (settings[provider] as? [String: Any])?["plan"] == nil { section["plan"] = "cloud" }
    }
    if !section.isEmpty {
      let overlay: [String: Any]
      if provider.hasPrefix("custom:") { overlay = ["customProviders": [String(provider.dropFirst(7)): section]] }
      else if provider.hasPrefix("extension:") { overlay = ["extensionProviders": [provider: section]] }
      else { overlay = [provider: section] }
      mergeSettings(&settings, overlay)
    }
    return settings
  }
}

private func copySettingsJSON(_ value: Any, depth: Int = 0) throws -> Any {
  guard depth <= 256 else { throw AgentSDKError.agentConfig(message: "Run settings exceed maximum nesting depth") }
  if let wrapped = value as? AnyCodable { return try copySettingsJSON(wrapped.value, depth: depth) }
  if let object = value as? [String: Any] {
    var copy: [String: Any] = [:]
    for (key, item) in object {
      guard !["__proto__", "prototype", "constructor"].contains(key) else {
        throw AgentSDKError.agentConfig(message: "Run settings contain an unsafe setting path")
      }
      copy[key] = try copySettingsJSON(item, depth: depth + 1)
    }
    return copy
  }
  if let array = value as? [Any] { return try array.map { try copySettingsJSON($0, depth: depth + 1) } }
  if value is NSNull || value is String { return value }
  if let number = value as? NSNumber, number.doubleValue.isFinite { return number }
  throw AgentSDKError.agentConfig(message: "Run settings must contain plain JSON values")
}

private func mergeSettings(_ target: inout [String: Any], _ source: [String: Any]) {
  for (key, value) in source {
    if let child = value as? [String: Any], var existing = target[key] as? [String: Any] {
      mergeSettings(&existing, child)
      target[key] = existing
    } else { target[key] = value }
  }
}

private func vertexEndpoint(_ value: String) throws -> String {
  if let url = URLComponents(string: value.contains("://") ? value : "https://" + value),
    url.scheme == "https", let host = url.host, !host.isEmpty,
    url.user == nil, url.password == nil, url.port == nil,
    ["", "/"].contains(url.path), url.query == nil, url.fragment == nil { return host }
  throw AgentSDKError.agentConfig(message: "Vertex endpoint must be an HTTPS origin or hostname")
}
