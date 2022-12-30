import Foundation
public enum FirestoreCollectionReference: String {
  case users = "Users"
  case conversations = "Conversations"
  case messages = "Messages"
}

public enum FirestoreResponse {
  case success
  case failure
}
