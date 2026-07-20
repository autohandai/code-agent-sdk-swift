import Foundation

// MARK: - Skills registry

/// Community skill metadata returned by `autohand.getSkillsRegistry`.
public struct CommunitySkill: Codable, Sendable, Equatable {
  public let id: String
  public let name: String
  public let description: String
  public let category: String
  public let tags: [String]?
  public let rating: Double?
  public let downloadCount: Int?
  public let isFeatured: Bool?
  public let isCurated: Bool?

  public init(
    id: String,
    name: String,
    description: String,
    category: String,
    tags: [String]? = nil,
    rating: Double? = nil,
    downloadCount: Int? = nil,
    isFeatured: Bool? = nil,
    isCurated: Bool? = nil
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.category = category
    self.tags = tags
    self.rating = rating
    self.downloadCount = downloadCount
    self.isFeatured = isFeatured
    self.isCurated = isCurated
  }
}

public struct SkillsRegistryCategory: Codable, Sendable, Equatable {
  public let name: String
  public let count: Int

  public init(name: String, count: Int) {
    self.name = name
    self.count = count
  }
}

public struct GetSkillsRegistryParameters: Codable, Sendable, Equatable {
  public let forceRefresh: Bool?

  public init(forceRefresh: Bool? = nil) {
    self.forceRefresh = forceRefresh
  }
}

public struct GetSkillsRegistryResult: Codable, Sendable, Equatable {
  public let success: Bool
  public let skills: [CommunitySkill]
  public let categories: [SkillsRegistryCategory]
  public let error: String?

  public init(
    success: Bool,
    skills: [CommunitySkill],
    categories: [SkillsRegistryCategory],
    error: String? = nil
  ) {
    self.success = success
    self.skills = skills
    self.categories = categories
    self.error = error
  }
}

public enum SkillInstallScope: String, Codable, Sendable, CaseIterable {
  case user
  case project
}

public struct InstallSkillParameters: Codable, Sendable, Equatable {
  public let skillName: String
  public let scope: SkillInstallScope
  public let force: Bool?

  public init(skillName: String, scope: SkillInstallScope, force: Bool? = nil) {
    self.skillName = skillName
    self.scope = scope
    self.force = force
  }
}

public struct InstallSkillResult: Codable, Sendable, Equatable {
  public let success: Bool
  public let skillName: String?
  public let path: String?
  public let error: String?

  public init(
    success: Bool,
    skillName: String? = nil,
    path: String? = nil,
    error: String? = nil
  ) {
    self.success = success
    self.skillName = skillName
    self.path = path
    self.error = error
  }
}

// MARK: - MCP discovery

public struct MCPServerSummary: Codable, Sendable, Equatable {
  public let name: String
  public let status: String
  public let toolCount: Int

  public init(name: String, status: String, toolCount: Int) {
    self.name = name
    self.status = status
    self.toolCount = toolCount
  }
}

public struct MCPListServersResult: Codable, Sendable, Equatable {
  public let servers: [MCPServerSummary]

  public init(servers: [MCPServerSummary]) {
    self.servers = servers
  }
}

public struct MCPListToolsParameters: Codable, Sendable, Equatable {
  public let serverName: String?

  public init(serverName: String? = nil) {
    self.serverName = serverName
  }
}

public struct MCPToolSummary: Codable, Sendable, Equatable {
  public let name: String
  public let description: String
  public let serverName: String

  public init(name: String, description: String, serverName: String) {
    self.name = name
    self.description = description
    self.serverName = serverName
  }
}

public struct MCPListToolsResult: Codable, Sendable, Equatable {
  public let tools: [MCPToolSummary]

  public init(tools: [MCPToolSummary]) {
    self.tools = tools
  }
}

public enum MCPTransport: String, Codable, Sendable, CaseIterable {
  case stdio
  case sse
  case http
}

public struct MCPServerConfigEntry: Codable, Sendable, Equatable {
  public let name: String
  public let transport: MCPTransport
  public let command: String?
  public let args: [String]?
  public let url: String?
  public let env: [String: String]?
  public let headers: [String: String]?
  public let autoConnect: Bool?

  public init(
    name: String,
    transport: MCPTransport,
    command: String? = nil,
    args: [String]? = nil,
    url: String? = nil,
    env: [String: String]? = nil,
    headers: [String: String]? = nil,
    autoConnect: Bool? = nil
  ) {
    self.name = name
    self.transport = transport
    self.command = command
    self.args = args
    self.url = url
    self.env = env
    self.headers = headers
    self.autoConnect = autoConnect
  }
}

public struct MCPGetServerConfigsResult: Codable, Sendable, Equatable {
  public let configs: [MCPServerConfigEntry]

  public init(configs: [MCPServerConfigEntry]) {
    self.configs = configs
  }
}
