import FirebaseAuth

class UserManager {
  
  private let service = FirestoreService()
  
  func currentUserID() -> String? {
    return Auth.auth().currentUser?.uid
  }
  func forgotPassword(email:String, completion: @escaping CompletionObject<FirestoreResponse>) {
      if (!email.isValidEmail()){
          return
      }
      
      Auth.auth().sendPasswordReset(withEmail: email, completion: {
          error in
            if error.isNone {
              completion(.success)
              return
            } else {
                print (error?.localizedDescription as Any)
            }
            completion(.failure)
      })
  }
  func currentUserData(_ completion: @escaping CompletionObject<ObjectUser?>) {
    guard let id = Auth.auth().currentUser?.uid else { completion(nil); return }
    let query = FirestoreService.DataQuery(key: "id", value: id, mode: .equal)
    service.objectWithListener(ObjectUser.self, parameter: query, reference: .init(location: .users), completion: { users in
      completion(users.first)
    })
  }
  
  func login(user: ObjectUser, completion: @escaping CompletionObject<FirestoreResponse>) {
    guard let email = user.email, let password = user.password else { completion(.failure); return }
    Auth.auth().signIn(withEmail: email, password: password) { (_, error) in
      if error.isNone {
        completion(.success)
        return
      }
      completion(.failure)
    }
  }
  
  func register(user: ObjectUser, completion: @escaping CompletionObject<FirestoreResponse>) {
    guard let email = user.email, let password = user.password else { completion(.failure); return }
    Auth.auth().createUser(withEmail: email, password: password) {[weak self] (reponse, error) in
      guard error.isNone else { completion(.failure); return }
      user.id = reponse?.user.uid ?? UUID().uuidString
      self?.update(user: user, completion: { result in
        completion(result)
      })
    }
  }
  func updateAPNtoken(_ user: ObjectUser,apnToken:String, _ completion: CompletionObject<FirestoreResponse>? = nil) {
      guard user.deviceTokens.contains(apnToken) == false else { return }
      user.deviceTokens.append(apnToken)
      
      FirestoreService().update(user, reference: .init(location: .users)) { completion?($0) }
  }
  func updateBadgeCount(_ user: ObjectUser,bagdeCount:Int, _ completion: CompletionObject<FirestoreResponse>? = nil) {
        user.badgeCount = bagdeCount
        FirestoreService().update(user, reference: .init(location: .users)) { completion?($0) }
  }
  func update(user: ObjectUser, completion: @escaping CompletionObject<FirestoreResponse>) {
    FirestorageService().update(user, reference: .users) { response in
      switch response {
      case .failure: completion(.failure)
      case .success:
        FirestoreService().update(user, reference: .init(location: .users), completion: { result in
          completion(result)
        })
      }
    }
  }
  
  func contacts(_ completion: @escaping CompletionObject<[ObjectUser]>) {
    FirestoreService().objects(ObjectUser.self, reference: .init(location: .users)) { results in
      completion(results)
    }
  }
  
  func userData(for id: String, _ completion: @escaping CompletionObject<ObjectUser?>) {
    let query = FirestoreService.DataQuery(key: "id", value: id, mode: .equal)
    FirestoreService().objects(ObjectUser.self, reference: .init(location: .users), parameter: query) { users in
      completion(users.first)
    }
  }
    
    func userDataService(for id: String, _ completion: @escaping CompletionObject<ObjectUser?>) {
      let query = FirestoreService.DataQuery(key: "id", value: id, mode: .equal)
      service.objectWithListener(ObjectUser.self, parameter: query, reference: .init(location: .users), completion: { users in
          completion(users.first)
      })
    }
  
  @discardableResult func logout() -> Bool {
    do {
      try Auth.auth().signOut()
      return true
    } catch {
      return false
    }
  }
}
