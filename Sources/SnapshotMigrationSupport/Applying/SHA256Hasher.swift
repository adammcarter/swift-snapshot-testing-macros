import CryptoKit
import Foundation

public enum SHA256Hasher {
  public static func hash(_ text: String) -> String {
    hash(Data(text.utf8))
  }

  public static func hash(_ data: Data) -> String {
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
  }
}
