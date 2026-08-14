//#if canImport(UIKit)
//import SnapshotTestingMacros
//import SwiftUI
//import Testing
//
//@Suite
//enum LegacySnapshotSuiteMigration {
//  @Suite
//  @SnapshotSuite(
//    .theme(.light),
//    .strategy(.recursiveDescription)
//  )
//  struct SingleTest {
//    @SnapshotTest
//    func singleTest() -> some View {
//      Text("legacy snapshot suite migration")
//    }
//  }
//}
//#endif
