import Foundation

class MessageManager {
  
  let service = FirestoreService()
  
    func messages(for conversation: ObjectConversation, _ completion: @escaping CompletionObject<[ObjectMessage]>) {
        let reference = FirestoreService.Reference(first: .conversations, second: .messages, id: conversation.id)
        service.objectWithListener(ObjectMessage.self, reference: reference) { results in
          completion(results)
        }
    }
    func messagesSeen(for conversation: ObjectConversation,for userId: String, _ completion: @escaping CompletionObject<[ObjectMessage]>) {
        let query = FirestoreService.DataQuery(key:"seenBy." + userId, value: true, mode: .equal)
        let reference = FirestoreService.Reference(first: .conversations, second: .messages, id: conversation.id)
        service.objectWithListener(ObjectMessage.self, parameter: query, reference: reference) { results in
          completion(results)
        }
    }
    func messagesNew(for conversation: ObjectConversation,for userId: String, _ completion: @escaping CompletionObject<[ObjectMessage]>) {
        let query = FirestoreService.DataQuery(key:"seenBy." + userId, value: false, mode: .equal)
        let reference = FirestoreService.Reference(first: .conversations, second: .messages, id: conversation.id)
        service.objectWithListener(ObjectMessage.self, parameter: query, reference: reference) { results in
          completion(results)
        }
    }
    
    func markAsSeen(_ message: ObjectMessage,conversation: ObjectConversation, _ completion: CompletionObject<FirestoreResponse>? = nil) {
        guard let userID = UserManager().currentUserID() else { return }
        guard message.seenBy[userID] == false else { return }
        message.seenBy[userID] = true
        let reference = FirestoreService.Reference(first: .conversations, second: .messages, id: conversation.id)
        FirestoreService().update(message, reference: reference) {
            completion?($0)
        }
    }
    func create(_ message: ObjectMessage, conversation: ObjectConversation, _ completion: @escaping CompletionObject<FirestoreResponse>) {
        FirestorageService().update(message, reference: .messages) { response in
          switch response {
          case .failure: completion(response)
          case .success:
            let reference = FirestoreService.Reference(first: .conversations, second: .messages, id: conversation.id)
            FirestoreService().update(message, reference: reference) { result in
              completion(result)
            }
            if let id = conversation.isRead.filter({$0.key != UserManager().currentUserID() ?? ""}).first {
              conversation.isRead[id.key] = false
            }
            ConversationManager().create(conversation)
          }
        }
    }
}
