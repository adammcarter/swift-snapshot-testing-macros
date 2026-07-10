import Foundation

extension SizesSnapshotTrait {
  /// Represents the size (width and height) of a snapshot.
  public struct Size: Sendable, CustomDebugStringConvertible {
    let width: SizesSnapshotTrait.Length
    let height: SizesSnapshotTrait.Length

    /**
     When `nil`, inherit the scale from the device on which the tests are being run. On macOS
     there is no deterministic device scale to inherit, so `nil` renders at one pixel per point,
     keeping committed references independent of the recording machine's screen.

     This allows for backwards compatability to avoid breaking changes while allowing for a custom override when wanting to use a specific setup.
     */
    let scale: Double?

    public let displayName: String
    public let debugDescription: String
    public let testNameDescription: String

    /// Creates a new size configuration.
    ///
    /// - Parameters:
    ///   - width: The width of the snapshot.
    ///   - height: The height of the snapshot.
    ///   - scale: The scale factor (e.g., 2.0 or 3.0). If `nil`, inherits from the device
    ///     (on macOS, `nil` renders at one pixel per point).
    public init(
      width: SizesSnapshotTrait.Length,
      height: SizesSnapshotTrait.Length,
      scale: Double? = nil
    ) {
      self.width = width
      self.height = height
      self.scale = scale
      self.displayName = "size"
      self.debugDescription = "width: \(width), height: \(height), scale: \(String(describing: scale))"

      /*
       Embed the concrete dimensions for any explicitly fixed length so multiple fixed sizes in
       one test produce value-stable, order-independent reference names — without them the only
       disambiguator is the positional `.N` counter, and editing the sizes array silently
       re-maps every subsequent reference to a different geometry. The fully-minimum default
       keeps its historical `min-size` name (when `scale` is `nil`) so committed references
       recorded under it stay valid.
       */
      let description =
        switch (width, height) {
          case (.fixed(let width), .fixed(let height)):
            "fixed-\(Self.lengthValueDescription(width))x\(Self.lengthValueDescription(height))"
          case (.fixed(let width), .minimum):
            "min-height-w\(Self.lengthValueDescription(width))"
          case (.minimum, .fixed(let height)):
            "min-width-h\(Self.lengthValueDescription(height))"
          case (.minimum, .minimum):
            "min-size"
        }

      let scaleSuffix = scale.map { "-\(Self.lengthValueDescription($0))x" } ?? ""

      self.testNameDescription = description + scaleSuffix
    }

    /// Formats a dimension or scale value for use inside a reference file name.
    ///
    /// Integral values drop their fraction (`100.0` → `100`). A fractional value must encode its
    /// decimal point as a *word* character (`100.5` → `100p5`) rather than folding it to `-`:
    /// the `-` characters that delimit the width/height/scale fields (`fixed-{w}x{h}` and
    /// `-{scale}x`) must never be producible by a value, or two distinct geometries collide
    /// across a field boundary (e.g. `fixed(100)×fixed(2)@5.5` and `fixed(100)×fixed(2.5)@5`
    /// both folding to `fixed-100x2-5-5x`). Any other non-word character a `Double` description
    /// can emit (the `+`/`-` of scientific notation for extreme magnitudes) is likewise recoded
    /// to a word character so a value can never emit a `-`. The result stays file-name safe:
    /// every character is a word character or `p`/`n`.
    private static func lengthValueDescription(_ value: Double) -> String {
      if value.isFinite,
        value == value.rounded(),
        value.magnitude < 1_000_000_000_000
      {
        return String(Int(value))
      }

      return String(describing: value)
        .replacingOccurrences(of: "+", with: "")
        .replacingOccurrences(of: "-", with: "n")
        .replacingOccurrences(of: ".", with: "p")
    }

    init(
      width: SizesSnapshotTrait.Length,
      height: SizesSnapshotTrait.Length,
      scale: Double? = nil,
      displayName: String,
      debugDescription: String,
      testNameDescription: String
    ) {
      self.width = width
      self.height = height
      self.scale = scale
      self.displayName = displayName
      self.debugDescription = debugDescription
      self.testNameDescription = testNameDescription
    }

    init(
      device: SizesSnapshotTrait.Device,
      sizingOption: SizesSnapshotTrait.DeviceSizingOption
    ) {
      let (width, height): (SizesSnapshotTrait.Length, SizesSnapshotTrait.Length) =
        switch sizingOption {
          case .widthAndHeight:
            (
              .fixed(device.width),
              .fixed(device.height)
            )

          case .widthButMinimumHeight:
            (
              .fixed(device.width),
              .minimum
            )

          case .heightButMinimumWidth:
            (
              .minimum,
              .fixed(device.height)
            )
        }

      let testNameDescription = [
        device.debugDescription,
        sizingOption.testNameDescription,
      ]
      .compactMap { $0 }
      .joined(separator: "-")

      self = Self(
        width: width,
        height: height,
        scale: device.scale,
        displayName: "device",
        debugDescription: device.debugDescription,
        testNameDescription: testNameDescription
      )
    }
  }
}
