// #if canImport(UIKit)
// import SnapshotTestingMacros
// import SwiftUI
// import Testing
///// Compile-only regression fixtures for async legacy codegen.
/////
///// The legacy macros expand async test functions (and suites whose init is async) to
///// `makeValue: { await ... }`. When the assertion pipeline went synchronous, the async
///// `SnapshotViewGenerator` initialisers were removed and every async legacy test generated
///// non-compiling code. These fixtures fail the build if those initialisers regress again.
/////
///// Their generated tests are disabled: they exist to be compiled, not to record or compare
///// reference artifacts.
// @Suite
// enum LegacyAsyncSnapshotCompileFixture {
//   @Suite
//   @SnapshotSuite(.disabled("Compile-only fixture for async legacy codegen"))
//   struct AsyncFunctions {
//     @SnapshotTest
//     func makeAsyncView() async -> some View {
//       Text("async")
//     }
//     @SnapshotTest
//     func makeAsyncThrowingView() async throws -> some View {
//       Text("async throws")
//     }
//   }
//   /// A non-async instance function on an async-init suite is diagnosed as an error (the peer
//   /// macro cannot see the initialiser to emit `await`); the supported shape is an async
//   /// function, whose `await` covers the initialiser call too.
//   @Suite
//   @SnapshotSuite(.disabled("Compile-only fixture for async legacy suite inits"))
//   struct AsyncInit {
//     init() async {}
//     @SnapshotTest
//     func makeMyView() async -> some View {
//       Text("async init")
//     }
//   }
// }
// #endif
