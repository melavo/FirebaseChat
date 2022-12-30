//
//  ForgotPasswordViewController.swift
import UIKit

class ForgotPasswordViewController: UIViewController {
    @IBOutlet weak var viewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var viewTxtField:UIView!
    private let userManager = UserManager()
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        addKeyboardObservers()
        emailTextField.delegate = self
    }
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
        if  (notification.name == UIResponder.keyboardWillHideNotification){
            viewTopConstraint.constant = -50
        }else{
            viewTopConstraint.constant = -50 - keyboardFrame.height
        }
        
        UIView.animate(withDuration: 0.3) {
          self.view.layoutIfNeeded()
        }
    }
    @IBAction func cancelled(_ sender: Any){
        dismiss(animated: true, completion: nil)
    }
    @IBAction func submitted(_ sender: Any){
        guard let email = emailTextField.text else {
            return
        }
        guard email.isValidEmail() else {
            viewTxtField.backgroundColor = .red
            return
        }
        
        userManager.forgotPassword(email: email, completion: {
            [weak self] response in
            switch response {
            case .failure:
                self?.showAlert(title: "Error", message: "Your email does not exist.", completion: {
                    print("Error")
                })
                case .success:
                self?.showAlert(title: "Alert", message: "We sent you an email with instructions on how to reset your password.", completion: {
                    self?.dismiss(animated: true, completion: nil)
                })
            }
        })
    }
}
//MARK: UITextField Delegate
extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        viewTxtField.backgroundColor = .darkGray
    }
}
