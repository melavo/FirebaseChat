import UIKit

class UILabelGradient: UILabel {
  
  @IBInspectable var leftColor: UIColor = ThemeService.purpleColor {
    didSet {
      applyGradient()
    }
  }
  
  @IBInspectable var rightColor: UIColor = ThemeService.blueColor {
    didSet {
      applyGradient()
    }
  }
  
  override var text: String? {
    didSet {
      applyGradient()
    }
  }
  
  func applyGradient() {
    let gradientLayer = CAGradientLayer()
    gradientLayer.colors = [leftColor.cgColor, rightColor.cgColor]
    gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
    gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
    let textSize = NSAttributedString(string: text ?? "", attributes: [.font: font!]).size()
    gradientLayer.bounds = CGRect(origin: .zero, size: textSize)
    UIGraphicsBeginImageContextWithOptions(gradientLayer.bounds.size, true, 0.0)
    let context = UIGraphicsGetCurrentContext()
    gradientLayer.render(in: context!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    textColor = UIColor(patternImage: image!)
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    applyGradient()
  }
}
