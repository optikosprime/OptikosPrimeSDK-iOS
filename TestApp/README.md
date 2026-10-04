# Binary SDK test app

For React Native host applications, see the [React Native integration guide](REACT_NATIVE.md). It covers the native adapter contract and setup; this repository contains a native test app, not a React Native bridge.

Open `TestApp.xcodeproj`, select your signing team if needed, and run on an iPhone with iOS 16.6 or later. Tap **Start full vision check** to open the internal UIKit example's complete customized flow: instructions, camera and validation, results, and optional questionnaire. The example uses `isOlderThan43: true`.

The app uses `com.optikosprime.SDKUIKitExample` and the supplied production `SDKLicenseKey` in `TestApp/Info.plist`. Installing it replaces the internal example if that app is already installed with the same identifier.

The Xcode project references published **OptikosPrimeSDK package 0.0.3**, which downloads the **0.0.3 XCFramework** and verifies its checksum. It does not use a local SDK source project. `Package.resolved` records the release revision `05fa8fdb2830f5426173b45bed81258597ad15ef`.

The package depends on `MediaPipeRuntime` 1.0.1 or later, providing `MediaPipeCommonGraphLibraries`. iOS 16.6 or later is required. Do not add the full `SwiftTasksVision` product; the SDK binary already contains the measurement code.

Tap **Check camera support** to demonstrate the optional public camera-info API in the selected language. Tap **Start full vision check** to demonstrate the automatic check. Both share the SDK's one-hour cache. An unsupported device returns a typed failure, which the host displays after dismissing the SDK.

Both language paths use `OptikosPrimeOutcome`: completed outcomes contain a typed result, cancellation has no payload, and failures contain an `NSError` with stable domain and code. See the [SDK README](../README.md) for the full contract.

The simulator UI tests use a Debug-only URLProtocol fixture for the camera-info endpoint. They verify both languages' initialization, instructions and cancellation, optional prefetch/cache reuse, and unsupported-device failure. Duplicate camera-info requests deliberately fail in the fixture, so the prefetch tests check that the flow reuses cached data. Normal launches use the real service. Debug simulator launches rewrite only the camera-info request’s `model` parameter to `iPhone17,2`, because the simulator otherwise reports `arm64` and the service returns “Device model not found”. Physical devices and Release builds report their actual identifier. The override does not enable camera measurements in the simulator. The optional live UI test checks the production camera-info service using `iPhone17,2`; run it with `TEST_RUNNER_OPTIKOS_RUN_LIVE_CAMERA_TEST=1` in the xcodebuild environment. Complete measurements, permissions, and sensor guidance still require physical-device testing.

## Objective-C integration

Select **Objective-C**, then tap the same start button. `TestApp/ObjCSDKExample.m` imports `<OptikosPrimeSDK/OptikosPrimeSDK-Swift.h>` from the published binary and performs initialization, full-flow presentation, NSError handling, typed result handling, camera-info lookup, and cancellation entirely in Objective-C. The bridging header only lets the Swift host screen call this example; a pure Objective-C app does not need that bridging header.

The SDK class is named `OptikosPrimeSDK` in Objective-C (`OptikosPrimeSDKBridge` in Swift). The Objective-C full-flow method uses the default SDK styling and flow options, including the questionnaire. Custom Swift configuration and style structs are not exposed to Objective-C. The Swift selection retains the customized example.

Both integration paths have simulator tests for successful presentation, cache reuse, and unsupported-device handling.
