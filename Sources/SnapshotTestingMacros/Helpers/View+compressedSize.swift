#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension SnapshotView {
  func compressedSizeWhenConstrained(
    toWidth width: Double = 0,
    toHeight height: Double = 0
  ) -> CGSize {
    let containerView = SnapshotView(frame: .init(x: 0, y: 0, width: width, height: height))

    translatesAutoresizingMaskIntoConstraints = false

    containerView.addSubview(self)

    if width > 0 {
      widthAnchor.constraint(equalToConstant: width).isActive = true
    }

    if height > 0 {
      heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    NSLayoutConstraint.activate([
      topAnchor.constraint(equalTo: containerView.topAnchor),
      bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
      leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
    ])

    let targetSize: CGSize

    #if canImport(AppKit)
    containerView.layoutSubtreeIfNeeded()

    targetSize = fittingSize
    #elseif canImport(UIKit)
    containerView.setNeedsLayout()
    containerView.layoutIfNeeded()

    targetSize = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    #endif

    return with(targetSize) {
      $0.width = $0.width.rounded(.up)
      $0.height = $0.height.rounded(.up)
    }
  }
}
