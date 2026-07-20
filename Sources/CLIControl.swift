import Foundation

/// Result returned after replacing the active CLI conversation.
public struct ConversationResetResult: Codable, Sendable, Equatable {
  public let sessionId: String

  public init(sessionId: String) {
    self.sessionId = sessionId
  }
}
