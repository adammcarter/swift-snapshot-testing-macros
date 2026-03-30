import SwiftUI

func snapshotText(_ content: String) -> some View {
  Text(verbatim: content)
    .font(.system(size: 17, weight: .regular, design: .monospaced))
}
