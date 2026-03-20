#if canImport(AppKit)
import AppKit

@MainActor
func makeLabel(_ text: String) -> NSView {
  let label = makeTextFieldLabel(text)
  label.translatesAutoresizingMaskIntoConstraints = false

  let container = NSView()
  container.addSubview(label)

  NSLayoutConstraint.activate([
    label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
    label.topAnchor.constraint(equalTo: container.topAnchor),
    label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
    label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
  ])
  return container
}

extension NSView {
  @MainActor
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

@MainActor
private func makeTextFieldLabel(_ text: String) -> NSTextField {
  let label = NSTextField(labelWithString: text)
  label.font = .systemFont(ofSize: 17)
  label.alignment = .center
  label.backgroundColor = .clear
  label.textColor = .labelColor
  label.isBezeled = false
  label.isBordered = false
  label.drawsBackground = false
  label.isEditable = false
  label.isSelectable = false
  label.usesSingleLineMode = false
  label.lineBreakMode = .byWordWrapping
  label.maximumNumberOfLines = 0
  label.preferredMaxLayoutWidth = 300
  label.cell?.wraps = true
  return label
}
#endif
