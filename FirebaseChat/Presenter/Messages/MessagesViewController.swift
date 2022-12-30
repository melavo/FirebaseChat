import UIKit

class MessagesViewController: UIViewController, KeyboardHandler{
    //MARK: IBOutlets
    @IBOutlet weak var viewSendMess:UIView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var chatsView: UITableView!
    private var scrollViewBottom: UIScrollView!
    private var keyboardButton: UIButton!
    private var homeButton: UIButton!
    private var imageViewArrowUp:UIImageView!
    @IBOutlet weak var barBottomConstraint: NSLayoutConstraint!
    
    //MARK: Private properties
    private let managerConversation = ConversationManager()
    private let managerUser = UserManager()
    private let manager = MessageManager()
    private var messages = [ObjectMessage]()
    private var messageNews = [ObjectMessage]()
    private var seenByUsers = [String:Bool]()
    private var seenByUsersFirst = [String:Bool]()
    private var currentIndexRow = -1
    private var isShowKeyboard = false
    private var messageNotReadRow = -1
    private var messageCurrentCount = 0
    
    private var bagdeCount = 0
    
    private var hasTouchTable:Bool = false
    private var hasTouchScroll:Bool = false
    
    private var contentOffsetY:CGFloat = 0
    private var userDeviceToken = [String]()
    private var pushNotification = PushNotificationSender()
    //MARK: Public properties
    var conversation = ObjectConversation()
    var currentUser: ObjectUser?
    var toUser:ObjectUser?
    var isNewMessage = false
    var bottomInset: CGFloat {
        return view.safeAreaInsets.bottom + 510
    }
    fileprivate var rowTotalHeight: CGFloat {
        get {
            return CGFloat(65 * messages.count)
        }
    }
    private var mHeight:CGFloat!
    
    fileprivate func initUI(){
        let mainRect = self.view.frame
        mHeight = (mainRect.size.height - 80) / 2
        
        chatsView.frame = CGRect(x: 0, y: 80, width: mainRect.size.width, height: mHeight)
        chatsView.isScrollEnabled = true
        chatsView.alwaysBounceVertical = true
        chatsView.tag = 2
        chatsView.separatorStyle = .none
        chatsView.rowHeight = UITableView.automaticDimension
        chatsView.dataSource = self
        chatsView.delegate = self
        chatsView.scrollsToTop = false
        chatsView.isPagingEnabled = false
        chatsView.translatesAutoresizingMaskIntoConstraints = false
        chatsView.contentInset.top = mHeight / 2
        chatsView.contentInset.bottom =  mHeight / 2
        chatsView.showsVerticalScrollIndicator = false
        chatsView.estimatedSectionHeaderHeight = 0
        chatsView.estimatedSectionFooterHeight = 0
        //chatsView.register(UINib(nibName: "MessageChatCell", bundle: nil), forCellReuseIdentifier: "MessageChatCell")
        chatsView.register(UINib(nibName: "RightViewCell", bundle: nil), forCellReuseIdentifier: "RightViewCell")
        chatsView.register(UINib(nibName: "LeftViewCell", bundle: nil), forCellReuseIdentifier: "LeftViewCell")
        
        scrollViewBottom = UIScrollView(frame: CGRect(x: 0, y: chatsView.frame.origin.y + mHeight, width: mainRect.size.width, height: mHeight))
        scrollViewBottom.isScrollEnabled = true
        scrollViewBottom.delegate = self
        scrollViewBottom.backgroundColor = .clear
        scrollViewBottom.alwaysBounceVertical = true
        scrollViewBottom.showsVerticalScrollIndicator = false
        scrollViewBottom.tag = 1
        scrollViewBottom.contentInset.top = chatsView.contentInset.top
        scrollViewBottom.contentInset.bottom = chatsView.contentInset.bottom
        scrollViewBottom.sendSubviewToBack(viewSendMess)
        self.view.addSubview(scrollViewBottom)
        
        let height =  self.view.frame.size.height - 240
        keyboardButton = UIButton(frame: CGRect(x: 10, y: height, width: 52, height: 52))
        keyboardButton.setBackgroundImage(UIImage(named: "keyboard"), for: .normal)
        self.view.addSubview(keyboardButton)
        keyboardButton.addTarget(self, action: #selector(showKeyboardChatAction(_:)), for: .touchUpInside)
        
        homeButton = UIButton(frame: CGRect(x: 10, y: height + 65, width: 52, height: 52))
        homeButton.setBackgroundImage(UIImage(named: "home"), for: .normal)
        self.view.addSubview(homeButton)
        homeButton.addTarget(self, action: #selector(goHomeScreenAction(_:)), for: .touchUpInside)
        
        imageViewArrowUp = UIImageView(frame: CGRect(x: (self.view.frame.size.width - 80) / 2, y: height + 160, width: 80, height: 58))
        imageViewArrowUp.image = UIImage(named: "arrow_up")
        imageViewArrowUp.isHidden = true
        self.view.addSubview(imageViewArrowUp)
        
    }
    fileprivate func setShowHideControlUI(_ state:Bool){
        homeButton.isHidden = state
        keyboardButton.isHidden = state
        scrollViewBottom.isHidden = state
    }
    //MARK: Lifecycle
    override  func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.chatsView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)

    }
    override func viewWillDisappear(_ animated: Bool) {
        self.chatsView.removeObserver(self, forKeyPath: "contentSize")
        super.viewWillDisappear(true)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?){
        if(keyPath == "contentSize"){
            if let newValue = change?[.newKey]{
                var newSize  = newValue as! CGSize
                //scrollViewBottom.contentSize = newSize
               // let currentSize = scrollViewBottom.contentSize
                if newSize.height < rowTotalHeight {
                    newSize.height = rowTotalHeight
                }
                scrollViewBottom.contentSize = newSize
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        navigationItem.hidesBackButton = true
        
        addKeyboardObservers() {[weak self] state in
            guard state else {
                self?.isShowKeyboard = false
                return
            }
            self?.isShowKeyboard = true
            if self?.messages.count ?? 0 > 0 {
                self?.chatsView.scroll(to:.bottom, animated: true)
            }
        }
        let swipeToDownGesture = UISwipeGestureRecognizer(target: self, action:#selector(swipeDown(_:)))
        swipeToDownGesture.direction = .down
        swipeToDownGesture.delegate = self
        view.addGestureRecognizer(swipeToDownGesture)
        
        let swipeToUpGesture = UISwipeGestureRecognizer(target: self, action:#selector(swipeUp(_:)))
        swipeToUpGesture.direction = .up
        swipeToUpGesture.delegate = self
        view.addGestureRecognizer(swipeToUpGesture)
        
        let swipeLeftToRightGesture = UISwipeGestureRecognizer(target: self, action:#selector(swipeLeftToRight(_:)))
        swipeLeftToRightGesture.direction = .right
        swipeLeftToRightGesture.delegate = self
        view.addGestureRecognizer(swipeLeftToRightGesture)
        fetchMessages()
        fetchUserName()
        fetchNewMessages()
        for userId in conversation.userIDs {
            if (userId == UserManager().currentUserID()){
                seenByUsers[userId] = true
            }else{
                seenByUsers[userId] = false
                
            }
            seenByUsersFirst[userId] = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (self.isNewMessage){
            inputTextField.setNeedsFocusUpdate()
            inputTextField.becomeFirstResponder()
            viewSendMess.isHidden = false
            setShowHideControlUI(true)
        }
        
    }
    
    @objc private func swipeLeftToRight(_ gesture: UISwipeGestureRecognizer) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    @objc private func swipeDown(_ gesture: UISwipeGestureRecognizer) {
        if self.isShowKeyboard {
            inputTextField.resignFirstResponder()
            self.viewSendMess.isHidden = true
            setShowHideControlUI(false)
            if (messages.count == 0){
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    @objc private func swipeUp(_ gesture: UISwipeGestureRecognizer) {
        if self.messageNotReadRow > 0 && currentIndexRow >= (messageCurrentCount - 3) {
            let messSeen = messageNews[0]
            manager.markAsSeen(messSeen,conversation:conversation)
            let currentBadgeNumber = UIApplication.shared.applicationIconBadgeNumber
            if (currentBadgeNumber>0){
                UIApplication.shared.applicationIconBadgeNumber = currentBadgeNumber - 1
                managerUser.updateBadgeCount(self.currentUser!, bagdeCount: UIApplication.shared.applicationIconBadgeNumber)
            }
        }
    }

}

//MARK: Private methods
extension MessagesViewController {
  private func fetchNewMessages(){
      manager.messagesNew(for: conversation, for:UserManager().currentUserID()!) {[weak self] messageNews in
          guard let weakSelf = self else { return }
          weakSelf.messageNotReadRow = messageNews.count
          weakSelf.messageNews = messageNews.sorted(by: {$0.timestamp < $1.timestamp})
          if (weakSelf.messageNotReadRow > 0){
              weakSelf.imageViewArrowUp.isHidden = false
          }else{
              weakSelf.imageViewArrowUp.isHidden = true // this true
              weakSelf.managerConversation.markAsRead(weakSelf.conversation)
          }
      }
  }
  private func fetchMessages() {
      manager.messagesSeen(for: conversation, for:UserManager().currentUserID()!) {[weak self] messages in
        guard let weakSelf = self else { return }
        let messageCount = messages.count
        if (weakSelf.messageCurrentCount > 0 && weakSelf.messageCurrentCount == messageCount){
            return
        }else{
            weakSelf.messageCurrentCount = messageCount
        }
        weakSelf.messages = messages.sorted(by: {$0.timestamp < $1.timestamp})
        weakSelf.chatsView.reloadData()
        
        if weakSelf.messageCurrentCount > 0 {
            weakSelf.chatsView.scroll(to: .bottom, animated: true)
            weakSelf.scrollViewBottom.scrollToBottom(animated: false)
        }
    }
  }
  
  private func send(_ message: ObjectMessage) {
        manager.create(message, conversation: conversation) {[weak self] response in
            guard let weakSelf = self else { return }
            if response == .failure {
                weakSelf.showAlert()
                return
            }
            weakSelf.conversation.timestamp = Int(Date().timeIntervalSince1970)
            switch message.contentType {
              case .none: weakSelf.conversation.lastMessage = message.message
              default: break
              }
              if let currentUserID = UserManager().currentUserID() {
                weakSelf.conversation.isRead[currentUserID] = true
            }
            ConversationManager().create(weakSelf.conversation)
            weakSelf.bagdeCount = weakSelf.bagdeCount + 1
            if weakSelf.userDeviceToken.count > 0 {
                weakSelf.pushNotification.sendPushNotification([
                    "conversationId":weakSelf.conversation.id,
                    "title":self?.currentUser?.name! ?? "",
                    "body":message.message ?? "",
                    "badgeCount":weakSelf.bagdeCount
                ], registrationIds: weakSelf.userDeviceToken)
                
                if (weakSelf.toUser != nil){
                    weakSelf.managerUser.updateBadgeCount(weakSelf.toUser!, bagdeCount: weakSelf.bagdeCount)
                }
            }
            
        }
  }
  
    private func fetchUserName() {
      guard let currentUserID = UserManager().currentUserID() else { return }
      guard let userID = conversation.userIDs.filter({$0 != currentUserID}).first else { return }
      managerUser.userDataService(for: userID) {[weak self] user in
          guard let name = user?.name else { return }
          self?.bagdeCount = user?.badgeCount ?? 0
          if (self?.toUser == nil){
              self?.toUser = user
              self?.navigationItem.title = name
              self?.userDeviceToken = user?.deviceTokens ?? [String]()
          }
      }
    }    
}

//MARK: IBActions
extension MessagesViewController {
  @IBAction func sendMessagePressed(_ sender: Any) {
      guard let text = inputTextField.text, !text.isEmpty else { return }
      let message = ObjectMessage()
      message.message = text
      message.ownerID = UserManager().currentUserID()
      if (messages.count>0){
          message.seenBy = seenByUsers
      }else{
          message.seenBy = seenByUsersFirst
      }
      inputTextField.text = nil
      send(message)
  }
  
  @IBAction func goHomeScreenAction(_ sender: UIButton) {
      self.navigationController?.popToRootViewController(animated: true)
  }
  @IBAction func showKeyboardChatAction(_ sender: UIButton) {
      self.viewSendMess.isHidden = false
      setShowHideControlUI(true)
      inputTextField.becomeFirstResponder()
  }
  
  @IBAction func expandItemsPressed(_ sender: UIButton) {
      inputTextField.resignFirstResponder()
      self.viewSendMess.isHidden = true
      setShowHideControlUI(false)
  }
}

//MARK: UITableView Delegate & DataSource
extension MessagesViewController: UITableViewDelegate, UITableViewDataSource  {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        if message.ownerID == UserManager().currentUserID() {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RightViewCell") as! RightViewCell
            cell.configureCell(message: message)
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeftViewCell") as! LeftViewCell
            cell.configureCell(message: message)
            return cell
        }
    }
}

//MARK: UIScrollViewDelegate
extension MessagesViewController: UIScrollViewDelegate  {
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        if ( scrollView.tag == 1 && hasTouchScroll == true){
            let customOffset = CGPoint(x: 0, y: scrollView.contentOffset.y)
            chatsView.setContentOffset(customOffset, animated: false)
        } else if (scrollView.tag == 2){
            let visibleRect = CGRect(origin: chatsView.contentOffset, size: chatsView.bounds.size)
            let visiblePoint = CGPoint(x: 0, y: visibleRect.midY)
            let visibleIndexPath = chatsView.indexPathForRow(at: visiblePoint)
            currentIndexRow = visibleIndexPath?.row ?? -1
            //print(scrollView.contentOffset.y) //scrollView.contentOffset.y >= 0 &&
            if  visibleRect.midY >= (scrollView.contentSize.height - scrollView.frame.size.height) {
                if currentIndexRow == -1 {
                    currentIndexRow = messages.count - 1
                }
                
            } else if currentIndexRow == -1 {
                currentIndexRow = 0
            }
            if let visibleRows = chatsView.indexPathsForVisibleRows {
                for indexPath in visibleRows {
                    if let cellToUnhighlight = chatsView.cellForRow(at: indexPath) , (indexPath as NSIndexPath).row != currentIndexRow {
                        if cellToUnhighlight is LeftViewCell {
                            (cellToUnhighlight as? LeftViewCell)?.setRowHighlighted(false)
                        } else if cellToUnhighlight is RightViewCell {
                            (cellToUnhighlight as? RightViewCell)?.setRowHighlighted(false)
                        }
                    }
                }
            }
            
            if let cellToHighlight = chatsView.cellForRow(at: IndexPath(row: currentIndexRow, section: 0)) {
                if cellToHighlight is LeftViewCell {
                        (cellToHighlight as? LeftViewCell)?.setRowHighlighted(true)
                } else if cellToHighlight is RightViewCell {
                        (cellToHighlight as? RightViewCell)?.setRowHighlighted(true)
                }
            }
        }
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView){
        if scrollView.tag == 2 {
            hasTouchTable = true
        } else if (scrollView.tag == 1){
            hasTouchScroll = true
            scrollViewBottom.contentSize = chatsView.contentSize
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView){
        if (scrollView.tag == 2){
            if (hasTouchTable){
                scrollViewBottom.setContentOffset(scrollView.contentOffset, animated: false)
            }
            hasTouchTable = false
        } else if (scrollView.tag == 1) {
            hasTouchScroll = false
        }
    }
}

//MARK: UItextField Delegate
extension MessagesViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      self.viewSendMess.isHidden = true
      setShowHideControlUI(false)
      return textField.resignFirstResponder()
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    return true
  }
}

extension MessagesViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
