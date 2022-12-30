//  ContactCell.swift

import UIKit

class ContactCell: UICollectionViewCell {
    
    private var nameLabel: UILabel!
    private var profilePic: UIImageView!
    
    let userID = UserManager().currentUserID() ?? ""
    private var conversation:ObjectConversation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        profilePic = UIImageView(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
        profilePic.contentMode = .scaleAspectFill
        profilePic.clipsToBounds = true
        profilePic.cornerRadius = 25
        profilePic.borderColor = UIColor(red: 0.55, green: 0.56, blue: 0.85, alpha: 1.00)
        addSubview(profilePic)
        
        nameLabel = UILabel(frame: CGRect(x: 70, y: 10, width: self.frame.size.width - 70, height: 50))
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.numberOfLines = 2
        addSubview(nameLabel)
        
    }
    
    func setConversation (_ conversation: ObjectConversation) {
        self.conversation = conversation;
    }
    
    func setContact(_ user: ObjectUser){
        nameLabel.text = user.name
        
        if (conversation != nil ){
            guard (conversation?.userIDs.filter({$0 != userID}).first) != nil else { return }
            let isRead = conversation?.isRead[userID] ?? true
            if !isRead {
                profilePic.borderWidth = 5
                nameLabel.font = nameLabel.font.bold
            }else{
                profilePic.borderWidth = 0
                nameLabel.font = nameLabel.font.regular
            }
        }else{
            profilePic.borderWidth = 0
            nameLabel.font = nameLabel.font.regular
        }
        guard let urlString = user.profilePicLink else {
            profilePic.image = UIImage(named: "profile pic")
            return
        }
        profilePic.setImage(url: URL(string: urlString))
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
