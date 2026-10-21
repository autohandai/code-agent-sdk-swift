import Foundation

/// Original CLI method and JSON parameters, including future payload shapes.
public struct WireNotification: Codable, Sendable {
  public let method: String
  public let params: AnyCodable

  private enum CodingKeys: String, CodingKey { case method, params }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    method = try container.decode(String.self, forKey: .method)
    params = try container.decodeIfPresent(AnyCodable.self, forKey: .params) ?? AnyCodable(NSNull())
  }

  public init(method: String, params: AnyCodable) {
    self.method = method
    self.params = params
  }
}
