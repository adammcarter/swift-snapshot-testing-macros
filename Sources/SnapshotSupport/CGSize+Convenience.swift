import CoreGraphics

public func * (lhs: CGSize, rhs: Int) -> CGSize {
  .init(
    width: lhs.width * CGFloat(rhs),
    height: lhs.height * CGFloat(rhs)
  )
}

public func * (lhs: CGSize, rhs: Double) -> CGSize {
  .init(
    width: lhs.width * rhs,
    height: lhs.height * rhs
  )
}
