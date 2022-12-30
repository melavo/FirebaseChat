import UIKit

class ObjectMessage: FireStorageCodable {
  
  var id = UUID().uuidString
  var message: String?
  var content: String?
  var contentType = ContentType.none
  var timestamp = Int(Date().timeIntervalSince1970)
  var ownerID: String?
  var profilePicLink: String?
  var profilePic: UIImage?
  var seenBy = [String: Bool]()
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encodeIfPresent(message, forKey: .message)
    try container.encodeIfPresent(timestamp, forKey: .timestamp)
    try container.encodeIfPresent(ownerID, forKey: .ownerID)
    try container.encodeIfPresent(profilePicLink, forKey: .profilePicLink)
    try container.encodeIfPresent(contentType.rawValue, forKey: .contentType)
    try container.encodeIfPresent(content, forKey: .content)
    try container.encode(seenBy, forKey: .seenBy)
  }
  
  init() {}
  
  public required convenience init(from decoder: Decoder) throws {
    self.init()
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    message = try container.decodeIfPresent(String.self, forKey: .message)
    timestamp = try container.decodeIfPresent(Int.self, forKey: .timestamp) ?? Int(Date().timeIntervalSince1970)
    ownerID = try container.decodeIfPresent(String.self, forKey: .ownerID)
    profilePicLink = try container.decodeIfPresent(String.self, forKey: .profilePicLink)
    content = try container.decodeIfPresent(String.self, forKey: .content)
    seenBy = try container.decode([String: Bool].self, forKey: .seenBy)
    if let contentTypeValue = try container.decodeIfPresent(Int.self, forKey: .contentType) {
      contentType = ContentType(rawValue: contentTypeValue) ?? ContentType.unknown
    }
  }
}

extension ObjectMessage {
  private enum CodingKeys: String, CodingKey {
    case id
    case message
    case timestamp
    case ownerID
    case profilePicLink
    case contentType
    case content
    case seenBy
  }
  
  enum ContentType: Int {
    case none
    case photo
    case location
    case unknown
  }
}
