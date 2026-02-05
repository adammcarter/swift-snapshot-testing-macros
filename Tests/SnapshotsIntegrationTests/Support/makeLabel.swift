#if canImport(UIKit)
import UIKit

@MainActor
func makeLabel(_ text: String) -> UIView {
  let label = UILabel()
  label.font = .systemFont(ofSize: UIFont.systemFontSize)
  label.text = text
  label.numberOfLines = 0
  label.sizeToFit()
  label.backgroundColor = .clear
  label.textAlignment = .center

  return label
}

extension UIView {
  func addLabel(string: String) {
    let label = makeLabel(string)

    addSubview(label)

    label.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: leadingAnchor),
      label.topAnchor.constraint(equalTo: topAnchor),
      label.trailingAnchor.constraint(equalTo: trailingAnchor),
      label.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}
#endif
