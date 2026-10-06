# Binary SDK test app

For React Native host applications, see the [React Native integration guide](REACT_NATIVE.md). It covers the native adapter contract and setup; this repository contains a native test app, not a React Native bridge.

Open `TestApp.xcodeproj`, select your signing team if needed, and run on an iPhone with iOS 16.6 or later. Select **Swift** or **Objective-C**, then tap **Start full vision check** to open the complete SDK flow: instructions, camera and validation, results, and optional questionnaire. The example uses `isOlderThan43: true`.

The app uses `com.optikosprime.SDKUIKitExample` and the supplied production `SDKLicenseKey` in `TestApp/Info.plist`. Installing it replaces the internal example if that app is already installed with the same identifier.

The Xcode project references published **OptikosPrimeSDK package 0.0.4**, which downloads the **0.0.4 XCFramework** and verifies its checksum. It does not use a local SDK source project.

The package depends on `MediaPipeRuntime` 1.0.1 or later, providing `MediaPipeCommonGraphLibraries`. iOS 16.6 or later is required. Do not add the full `SwiftTasksVision` product; the SDK binary already contains the measurement code.

Tap **Check camera support** to demonstrate the optional `getCameraInfo` API in the selected language. It uses the real service and the SDK’s camera-info cache. **Start full vision check** presents the complete flow. The SDK performs camera-support checking and session creation automatically, then owns instructions, capture, analysis, results, questionnaire, and retry. An unsupported device returns a typed failure, which the host displays after dismissing the SDK.

The host handles `OptikosPrimeOutcome`: completed outcomes contain a typed result, cancellation has no payload, and failures contain an `NSError` with stable domain and code. After completion, the host displays the final conclusion, questionnaire assessment (if answered), and measurement identifier. See the [SDK README](../README.md) for the full contract.

The sample calls the SDK directly, without network interception, synthetic responses, or simulator device-model overrides. The UI test checks the app’s launch screen; unit tests check the public result and error contracts. Run the full flow on a supported physical iPhone with a network connection to validate camera support, session creation, capture, and questionnaire submission.

The **Objective-C** selection calls `TestApp/ObjCSDKExample.m` to initialize and present the full flow using the generated SDK header. The **Swift** selection uses the customized example style; Objective-C uses the default SDK style. The SDK class is named `OptikosPrimeSDK` in Objective-C (`OptikosPrimeSDKBridge` in Swift); custom Swift configuration and style structs are not exposed to Objective-C.

## Questionnaire results

Successfully saved questionnaire answers and the configured age group determine the final assessment using VisionCheck’s four-question rules. A normal questionnaire sets the final conclusion to `normal`; myopia, hyperopia, astigmatism, or presbyopia sets it to `finding`, even when the camera was inconclusive. The original camera probabilities remain available in `leftEye` and `rightEye`. Without completed questions, the camera conclusion is retained.

Both API environments use normal TLS validation; the test app has no ATS exception. This public example continues to use production and its supplied production license.

On an iPhone, start the full flow: complete a measurement, answer all four questions, wait for successful submission, and check that the SDK screen and host completion summary show the same final assessment. Also verify cancelling, skipping questions, and retrying a failed questionnaire submission. Full camera measurements cannot be validated in the simulator.
