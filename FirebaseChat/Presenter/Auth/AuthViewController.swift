import UIKit
import FirebaseMessaging
class AuthViewController: UIViewController {
  //MARK: IBOutlets
  @IBOutlet weak var registerImageView: UIImageView!
  @IBOutlet weak var registerNameTextField: UITextField!
  @IBOutlet weak var registerEmailTextField: UITextField!
  @IBOutlet weak var registerPasswordTextField: UITextField!
  @IBOutlet weak var loginEmailTextField: UITextField!
  @IBOutlet weak var loginPasswordTextField: UITextField!
    
  @IBOutlet weak var switchLogin: UIButton!
  @IBOutlet weak var switchCreate: UIButton!
    
  @IBOutlet var separatorViews: [UIView]!
  @IBOutlet weak var loginViewTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var registerViewTopConstraint: NSLayoutConstraint!
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  //MARK: Private properties
  private var currentScreeen:String?
  private var selectedImage: UIImage?
  private let manager = UserManager()
  private let imageService = ImagePickerService()
  override func viewDidLoad() {
      super.viewDidLoad()
      addKeyboardObservers()

  }
  //MARK: Lifecycle
    
  func addKeyboardObservers() {
      NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) {[weak self] (notification) in
        self?.handleKeyboard(notification: notification)
      }
      NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) {[weak self] (notification) in
        self?.handleKeyboard(notification: notification)
      }
  }
    
  private func handleKeyboard(notification: Notification) {
      guard let userInfo = notification.userInfo else { return }
      guard let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
      if (currentScreeen == "login" ){
          if  (notification.name == UIResponder.keyboardWillHideNotification){
              loginViewTopConstraint.constant = self.view.frame.size.height - 255 - 50 //120
          }else{
              loginViewTopConstraint.constant = self.view.frame.size.height - 255 - keyboardFrame.height
          }
      }else{
          if  (notification.name == UIResponder.keyboardWillHideNotification){
              registerViewTopConstraint.constant = self.view.frame.size.height - 370 - 50
          }else{
              registerViewTopConstraint.constant = self.view.frame.size.height - 370 - keyboardFrame.height
          }
      }
      
      UIView.animate(withDuration: 0.3) {
        self.view.layoutIfNeeded()
      }
  }
}

//MARK: IBActions
extension AuthViewController {
  
  @IBAction func register(_ sender: Any) {
    guard let name = registerNameTextField.text, let email = registerEmailTextField.text, let password = registerPasswordTextField.text else {
      return
    }
    guard !name.isEmpty else {
      separatorViews.filter({$0.tag == 2}).first?.backgroundColor = .red
      return
    }
    guard email.isValidEmail() else {
      separatorViews.filter({$0.tag == 3}).first?.backgroundColor = .red
      return
    }
    guard password.count > 5 else {
      separatorViews.filter({$0.tag == 4}).first?.backgroundColor = .red
      return
    }
    view.endEditing(true)
    let user = ObjectUser()
    user.name = name
    user.email = email
    user.password = password
    user.profilePic = selectedImage
      
    if let tokenFCM = Messaging.messaging().fcmToken {
        user.deviceTokens.append(tokenFCM)
    }
            
    ThemeService.showLoading(true)
    manager.register(user: user) {[weak self] response in
      ThemeService.showLoading(false)
      switch response {
        case .failure: self?.showAlert()
        case .success: self?.dismiss(animated: true, completion: nil)
      }
    }
  }
  @IBAction func forgotPassword(_ sender: Any){
      let vc = UIStoryboard.initial(storyboard: .forgotPassword)
      vc.modalPresentationStyle = .fullScreen
      present(vc, animated: true)
  }
  @IBAction func login(_ sender: Any) {
        guard let email = loginEmailTextField.text, let password = loginPasswordTextField.text else {
          return
        }
        guard email.isValidEmail() else {
          separatorViews.filter({$0.tag == 0}).first?.backgroundColor = .red
          return
        }
        guard password.count > 5 else {
          separatorViews.filter({$0.tag == 1}).first?.backgroundColor = .red
          return
        }
        view.endEditing(true)
        let user = ObjectUser()
        user.email = email
        user.password = password
        ThemeService.showLoading(true)
        manager.login(user: user) {[weak self] response in
          ThemeService.showLoading(false)
          switch response {
          case .failure: self?.showAlert()
          case .success: self?.dismiss(animated: true, completion: nil)
          }
        }
  }
  
  @IBAction func switchToViewLogin(_ sender: UIButton) {
    currentScreeen = "login"
    loginViewTopConstraint.constant = self.view.frame.size.height - 255 - 80
    registerViewTopConstraint.constant = -800
    switchLogin.isHidden = true
    switchCreate.isHidden = true
    UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
      self.view.layoutIfNeeded()
    })
  }
  @IBAction func switchToViewCreateNew(_ sender: UIButton) {
      currentScreeen = "createNew"
      switchLogin.isHidden = true
      switchCreate.isHidden = true
      loginViewTopConstraint.constant = -800
      registerViewTopConstraint.constant = self.view.frame.size.height - 370 - 80
      UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
        self.view.layoutIfNeeded()
      })
  }
  
  @IBAction func profileImage(_ sender: Any) {
    imageService.pickImage(from: self) {[weak self] image in
      self?.registerImageView.image = image
      self?.selectedImage = image
    }
  }
}
//MARK: UITextField Delegate
extension AuthViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    return textField.resignFirstResponder()
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    separatorViews.forEach({$0.backgroundColor = .darkGray})
  }
}
