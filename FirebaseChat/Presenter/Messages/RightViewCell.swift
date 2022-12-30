import UIKit

class RightViewCell: UITableViewCell {

    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var textMessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageContainerView.layer.cornerRadius = 15
        messageContainerView.clipsToBounds = true
        messageContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,.layerMinXMaxYCorner]
        messageContainerView.backgroundColor = UIColor(red: 0.86, green: 0.94, blue: 1.00, alpha: 1.00)
        textMessageLabel.numberOfLines = 0
        textMessageLabel.lineBreakMode = .byWordWrapping
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }
    
    func configureCell(message: ObjectMessage) {
        textMessageLabel.text = message.message
    }
    
    func setRowHighlighted(_ highlighted: Bool) {
        if (highlighted) {
            UIView.animate(withDuration: 0.3) {
                self.messageContainerView.transform = .identity
                self.messageContainerView.alpha = 1.0
            }
        } else {
            self.messageContainerView.alpha = 0.4
            self.messageContainerView.transform = CGAffineTransform.identity.scaledBy(x: 0.9, y: 1.0)
        }
    }
}
