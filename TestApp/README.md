# Binary SDK test app

For React Native host applications, see the [React Native integration guide](REACT_NATIVE.md). It covers the native adapter contract and setup; this repository contains a native test app, not a React Native bridge.

Open `TestApp.xcodeproj`, select your signing team if needed, and run on an iPhone with iOS 16.6 or later. Tap **Start full vision check** to open the internal UIKit example's complete customized flow: instructions, camera and validation, results, and optional questionnaire. The example uses `isOlderThan43: true`.

The app uses `com.optikosprime.SDKUIKitExample` and the supplied production `SDKLicenseKey` in `TestApp/Info.plist`. Installing it replaces the internal example if that app is already installed with the same identifier.

The Xcode project references the published **OptikosPrimeSDK package 0.0.2** from GitHub. Its manifest downloads the **0.0.1 XCFramework** and verifies its checksum; the package update fixes dependency wiring and reuses the existing SDK binary. No local SDK package or SDK source project is used. iOS 16.6 is required by the MediaPipe runtime framework.

The package depends on the `MediaPipeRuntime` product from MediaPipe 1.0.1 or later. This includes only `MediaPipeCommonGraphLibraries`; the SDK binary already contains the measurement code. The existing `SwiftTasksVision` product keeps its required unsafe linker flags, but those targets are outside the runtime product's dependency graph.

MediaPipe `1.0.1` and SDK package `0.0.2` are published. `Package.resolved` records the exact revisions used by TestApp. The recreated 0.0.2 tag points to commit `55f9bdca8d698ff7fcc1b1c4b17efc42aa1a240a`. Machines that resolved the superseded tag may report a revision/fingerprint mismatch. After verifying that replacement commit, refresh only the stored fingerprint for this package/version and resolve again; clearing build artifacts alone does not address the mismatch.

The simulator smoke test checks launch, production license initialization, presentation of instructions, and cancellation. Camera measurement and server results must be tested on a physical iPhone.

## Objective-C integration

Select **Objective-C**, then tap the same start button. `TestApp/ObjCSDKExample.m` imports `<OptikosPrimeSDK/OptikosPrimeSDK-Swift.h>` from the published binary and performs initialization, full-flow presentation, NSError handling, JSON result handling, and cancellation entirely in Objective-C. The bridging header only lets the Swift host screen call this example; a pure Objective-C app does not need that bridging header.

The SDK class is named `OptikosPrimeSDK` in Objective-C (`OptikosPrimeSDKBridge` in Swift). The Objective-C full-flow method uses the default SDK styling and flow options, including the questionnaire. Custom Swift configuration and style structs are not exposed to Objective-C in 0.0.1. The Swift selection retains the customized example.

Both integration paths have simulator smoke tests that open the instructions and cancel back to the host.
