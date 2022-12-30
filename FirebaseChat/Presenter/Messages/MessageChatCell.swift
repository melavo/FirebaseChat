//
//  MessageChatCell.swift

import UIKit
class MessageChatCell: UITableViewCell {

    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var textMessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageContainerView.layer.cornerRadius = 15
        messageContainerView.clipsToBounds = true
        textMessageLabel.numberOfLines = 0
        textMessageLabel.lineBreakMode = .byWordWrapping
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }
    /*
     
     */
    
    func configureCell(message: ObjectMessage) {
        if message.ownerID == UserManager().currentUserID() {
            messageContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,.layerMinXMaxYCorner]
            messageContainerView.backgroundColor = UIColor(red: 0.86, green: 0.94, blue: 1.00, alpha: 1.00)
        }else{
            messageContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,.layerMaxXMaxYCorner]
            messageContainerView.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.00)

        }
        //messageContainerView.backgroundColor = .white
        //messageContainerView.backgroundColor = UIColor(hexString: "E1F7CB")
        textMessageLabel.text = message.message
        textMessageLabel.sizeToFit()
    }
    func setRowHighlighted(_ highlighted: Bool) {
        if (highlighted) {
            //self.textMessageLabel.font = UIFont.systemFont(ofSize: 20)
            UIView.animate(withDuration: 0.3) {
                self.messageContainerView.transform = .identity
                self.messageContainerView.alpha = 1.0
            }
        } else {
            //self.textMessageLabel.font = UIFont.systemFont(ofSize: 16)
            self.messageContainerView.alpha = 0.4
            //self.messageContainerView.transform = CGAffineTransform.identity.translatedBy(x: 0.4, y: 0.5)
            self.messageContainerView.transform = CGAffineTransform.identity.scaledBy(x: 0.9, y: 1.0)
        }
    }
}
