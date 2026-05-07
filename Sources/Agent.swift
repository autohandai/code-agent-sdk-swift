/// Agent class — the core configuration unit.
/// Mirrors the TypeScript SDK Agent class.

import Foundation

public final class Agent: @unchecked Sendable {
    public let name: String
    public let instructions: String
    public let tools: [ToolName]
    public let maxTurns: Int
    public private(set) var model: ModelID?
    public private(set) var provider: (any Provider)?
    public let loopType: LoopType
    public let cwd: String?
    public let memories: String?
    public let customInstructions: [String]?
    public let modelSettings: [String: AnyCodable]?

    public init(
        name: String,
        instructions: String,
        tools: [ToolName] = [],
        maxTurns: Int = 10,
        model: ModelID? = nil,
        provider: (any Provider)? = nil,
        loopType: LoopType = .react,
        cwd: String? = nil,
        memories: String? = nil,
        customInstructions: [String]? = nil,
        modelSettings: [String: AnyCodable]? = nil
    ) {
        self.name = name
        self.instructions = instructions
        self.tools = tools
        self.maxTurns = maxTurns
        self.model = model
        self.provider = provider
        self.loopType = loopType
        self.cwd = cwd
        self.memories = memories
        self.customInstructions = customInstructions
        self.modelSettings = modelSettings
    }

    public func setModel(_ model: ModelID) {
        self.model = model
    }

    public func setProvider(_ provider: any Provider) {
        self.provider = provider
    }
}
