//  ContactsViewController.swift
import UIKit
import FirebaseMessaging
class ContactsViewController: UIViewController {
    //MARK: IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var contentTop: UIView!
    @IBOutlet weak var btLogout: UIButton!
    var collectionView: UICollectionView!
    //MARK: Private properties
    private var conversations = [ObjectConversation]()
    private let manager = ConversationManager()
    private let userManager = UserManager()
    private var users = [ObjectUser]()
    private var currentUser: ObjectUser?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .default
    }
    func updateFrame(){
        contentTop.frame = CGRect(x: 0, y: 50 , width:Int(self.view.frame.size.width) , height: 200)
        profileImageView.frame = CGRect(x: (contentTop.frame.size.width - 100)/2, y: 10 , width:100 , height: 100)
        nameLabel.frame = CGRect(x: 10, y: 130 , width:Int(contentTop.frame.size.width/2) , height: 30)
        emailLabel.frame = CGRect(x: 10, y: 160 , width:Int(contentTop.frame.size.width/2) , height: 40)
        btLogout.frame = CGRect(x: contentTop.frame.size.width - 130, y: 150 , width:120 , height: 30)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        updateFrame()
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        //layout.itemSize = CGSize(width: Int((self.view.frame.size.width-40)/2), height: 80)
                
        collectionView = UICollectionView(frame: CGRect(x: 0, y: Int(self.view.frame.size.height - 250 ), width:Int(self.view.frame.size.width), height: 190), collectionViewLayout: layout)
        collectionView?.register(ContactCell.self, forCellWithReuseIdentifier: "ContactCell")
        collectionView?.backgroundColor = UIColor.white
                
        collectionView?.dataSource = self
        collectionView?.delegate = self
         
        self.view.addSubview(collectionView ?? UICollectionView())
        
        ProgressHUD.show("Loading...")
        fetchProfile()
        fetchConversations()
        fetchUsers()
        NotificationCenter.default.addObserver(self, selector: #selector(userFcmToken), name: Notification.Name("FCMConversationId"), object: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let userInfoNotify =  appDelegate.userInfoNotify as? [AnyHashable : Any] {
            
            if let cid = userInfoNotify["conversationId"] as? String
            {
                manager.currentConversation(id: cid , completion: {
                    [weak self] conversation in
                    let vc: MessagesViewController = UIStoryboard.initial(storyboard: .messages)
                    vc.modalPresentationStyle = .fullScreen
                    vc.currentUser = self?.currentUser
                    vc.conversation = conversation ?? ObjectConversation()
                    self?.show(vc, sender: self)
                })
            }
            appDelegate.userInfoNotify = nil
        }
        
    }
    // handle notification
    @objc func userFcmToken(notification: NSNotification) {
        if let cid = notification.userInfo?["cid"] as? String
        {
            manager.currentConversation(id: cid , completion: {
                [weak self] conversation in
                let vc: MessagesViewController = UIStoryboard.initial(storyboard: .messages)
                vc.modalPresentationStyle = .fullScreen
                vc.currentUser = self?.currentUser
                vc.conversation = conversation ?? ObjectConversation()
                self?.show(vc, sender: self)
            })
        }
     }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.cornerRadius = profileImageView.bounds.width / 2
    }
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(true)
      navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(true)
      navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func logOutAction(_ sender: Any) {
        userManager.logout()
        navigationController?.dismiss(animated: true)
    }
}
//MARK: Private methods
extension ContactsViewController {
    func fetchConversations() {
      manager.currentConversations {[weak self] conversations in
        self?.conversations = conversations.sorted(by: {$0.timestamp > $1.timestamp})
        self?.playSoundIfNeeded()
        if ( self?.users.isEmpty == false){
            self?.collectionView.reloadData()
        }
      }
    }
    func fetchProfile() {
        userManager.currentUserData {[weak self] user in
            self?.currentUser = user
            self?.nameLabel.text = self?.currentUser?.name
            self?.emailLabel.text = self?.currentUser?.email
            if let urlString = user?.profilePicLink {
                self?.profileImageView.setImage(url: URL(string: urlString))
            }
            UIApplication.shared.applicationIconBadgeNumber = self?.currentUser?.badgeCount ?? 0
            if let token  = Messaging.messaging().fcmToken {
                if self?.currentUser?.deviceTokens.contains(token) == false {
                    self?.userManager.updateAPNtoken((self?.currentUser)!, apnToken: token)
                }
            }
        }
    }
    func fetchUsers() {
      guard let id = userManager.currentUserID() else { return }
      userManager.contacts {[weak self] results in
          self?.users = results.filter({$0.id != id})
          self?.collectionView.reloadData()
          self?.playSoundIfNeeded()
          ProgressHUD.dismiss()
      }
    }
    func playSoundIfNeeded() {
        guard let id = userManager.currentUserID() else { return }
        if conversations.last?.isRead[id] == false {
            AudioService().playSound()
        }
    }
}

extension ContactsViewController: UICollectionViewDataSource,UICollectionViewDelegate ,UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Int(collectionView.frame.width/2)-20, height: 80)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if users.isEmpty {
            return 0
        }
        return users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let conactCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactCell", for: indexPath) as! ContactCell
        let user = users[indexPath.row]
        if let conversation = conversations.filter({$0.userIDs.contains(user.id)}).first {
            conactCell.setConversation(conversation)
        }
        conactCell.setContact(user)
        return conactCell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if users.isEmpty {
            return
        }
        let userSelect = users[indexPath.row];
        let vc: MessagesViewController = UIStoryboard.initial(storyboard: .messages)
        guard let currentID = userManager.currentUserID() else { return }
        if let conversation = conversations.filter({$0.userIDs.contains(userSelect.id)}).first {
            vc.conversation = conversation
            vc.currentUser = self.currentUser
        }else{
            let conversation = ObjectConversation()
            conversation.userIDs.append(contentsOf: [currentID, userSelect.id])
            conversation.isRead = [currentID: true, userSelect.id: true]
            vc.isNewMessage = true
            vc.conversation = conversation
            vc.currentUser = self.currentUser
        }
        show(vc, sender: self)
    }
}

