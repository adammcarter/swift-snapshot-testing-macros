import UIKit

@MainActor
func makeLabel(_ text: String) -> UIView {
  let label = UILabel()
  label.font = .systemFont(ofSize: UIFont.systemFontSize)
  label.text = text
  label.numberOfLines = 0
  label.sizeToFit()

  return label
}
