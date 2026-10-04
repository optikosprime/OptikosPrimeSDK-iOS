# Optikos Prime SDK for iOS

Embed a guided vision check in your iOS app using SwiftUI, UIKit, or Objective-C. The SDK provides instructions, camera capture, analysis, results, and an optional questionnaire. Your app controls presentation, dismissal, and what to do with the result.

## Installation

- iOS 16.6 or later.
- A physical iPhone for camera measurements; use the simulator for integration and presentation checks.
- An Optikos Prime license issued for your host app’s exact bundle identifier and environment.
- Network access for camera settings and cloud analysis.

In Xcode, choose **File → Add Package Dependencies**, enter:

```text
https://github.com/optikosprime/OptikosPrimeSDK-iOS
```

Select the `OptikosPrimeSDK` library for your application target and use the SDK release associated with this README.

The package includes the `MediaPipeRuntime` dependency. Ensure `MediaPipeCommonGraphLibraries.framework` is embedded and signed in the host app. The SDK bundles its face-landmark model; your app does not need to supply one.

## Host app permissions

Add the camera usage description to the **host app’s** `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera to capture your eyes for a vision check.</string>
```

The SDK requests camera access when opening its camera. It uses video capture without a microphone input and does not save test captures to the system photo library. Its current measurement flow does not require microphone or photo-library access.

The camera also uses live `CMMotionManager` accelerometer and device-motion updates for orientation guidance. Whether these specific APIs require `NSMotionUsageDescription` remains unconfirmed in this integration; the existing VisionCheck app does not declare it. A fresh-install device check should include motion guidance as well as camera access and denial.

Production uses the HTTPS service at `cloud.optikosprime.com`. The development environment has separate server configuration; the TestApp’s ATS settings are not a user permission and should not be copied blindly into a production app.

## Main entry point

After initialization, start the **complete test flow** using:

| Host | Entry point |
| --- | --- |
| UIKit / Swift | `OptikosPrimeSDKBridge.visionCheckViewController(...)` |
| Objective-C | `[OptikosPrimeSDK visionCheckViewControllerWithIsOlderThan43:error:completion:]` |
| SwiftUI | `OptikosPrimeVisionCheck` |

The default flow is:

**Camera-support check → instructions → capture and analysis → results → optional questionnaire.**

Calling `getCameraInfo` beforehand is optional. The complete flow checks support automatically before instructions or capture and reuses valid cached information. Unsupported devices produce a failed outcome with the `deviceNotSupported` error code.

The host must supply the actual `isOlderThan43` value. The SDK does not ask for age; it uses this flag when interpreting questionnaire answers.

## Initialization

Initialize once during integration setup, before calling SDK operations:

```swift
import OptikosPrimeSDK

try OptikosPrimeSDK.initialize(
    licenseKey: licenseKey,
    environment: .production
)
```

Initialization can throw, so handle it in a `do`/`catch` block or a throwing function. The license must match the host’s bundle identifier. Use `.development` only with the corresponding development license and server.

`isInitialized` reports whether the SDK has a valid session. `reset()` disables it. Reinitialization invalidates previously created SDK views and operations.

In Objective-C, import the generated header and handle `NSError`:

```objc
#import <OptikosPrimeSDK/OptikosPrimeSDK-Swift.h>

NSError *error = nil;
BOOL initialized = [OptikosPrimeSDK initializeWithLicenseKey:licenseKey
                                               environment:OptikosPrimeEnvironmentProduction
                                                     error:&error];
if (!initialized) {
    // Report error; do not present the test.
    return;
}
```

## UIKit

After initialization, run this from your view controller on the main thread. `isOlderThan43` is the age-group answer collected by your app.

```swift
do {
    let controller = try OptikosPrimeSDKBridge.visionCheckViewController(
        isOlderThan43: isOlderThan43
    ) { [weak self] outcome in
        self?.dismiss(animated: true)

        switch outcome.status {
        case .completed:
            if let result = outcome.result {
                print(result.measurementID, result.conclusion.stringValue)
            }
        case .cancelled:
            break
        case .failed:
            if let error = outcome.error {
                print(error.domain, error.code, error.localizedDescription)
            }
        @unknown default:
            break
        }
    }
    controller.modalPresentationStyle = .fullScreen
    present(controller, animated: true)
} catch {
    // Controller creation failed; completion will not be called.
    print(error.localizedDescription)
}
```

For custom styling and flow options, use `visionCheckViewController(configuration:completion:)` with `OptikosPrimeConfiguration`. `OptikosPrimeStyle` controls colors, fonts, and layout; `OptikosPrimeText` controls configurable text. These Swift configuration structs are not exposed to Objective-C.

## Objective-C

After initialization, present the complete flow from your host view controller:

```objc
NSError *error = nil;
__weak UIViewController *weakPresenter = self;
UIViewController *controller = [OptikosPrimeSDK
    visionCheckViewControllerWithIsOlderThan43:isOlderThan43
    error:&error
    completion:^(OptikosPrimeOutcome *outcome) {
        [weakPresenter dismissViewControllerAnimated:YES completion:nil];
        switch (outcome.status) {
            case OptikosPrimeStatusCompleted:
                NSLog(@"Measurement: %@", outcome.result.measurementID);
                break;
            case OptikosPrimeStatusCancelled:
                break;
            case OptikosPrimeStatusFailed:
                if ([outcome.error.domain isEqualToString:[OptikosPrimeSDK errorDomain]] &&
                    outcome.error.code == OptikosPrimeErrorCodeDeviceNotSupported) {
                    // Explain that this device is not supported.
                } else {
                    NSLog(@"%@", outcome.error.localizedDescription);
                }
                break;
        }
    }];

if (controller == nil) {
    // Controller creation failed; completion will not be called.
    NSLog(@"%@", error.localizedDescription);
    return;
}
controller.modalPresentationStyle = UIModalPresentationFullScreen;
[self presentViewController:controller animated:YES completion:nil];
```

## SwiftUI

Construct `OptikosPrimeVisionCheck` with `try` after initialization, then present it using your host’s full-screen presentation. For example, inside a throwing view factory:

```swift
let view = try OptikosPrimeVisionCheck(
    configuration: .init(isOlderThan43: isOlderThan43)
) { outcome in
    // Handle outcome.status and its result or error.
    // Clear the host's presentation state to dismiss the flow.
}
```

## Outcomes and errors

Completion delivers one immutable `OptikosPrimeOutcome` on the main thread when the presented flow completes, is cancelled, or fails. Your app is responsible for dismissal. Immediate controller-construction errors use `throws` in Swift and `NSError **` in Objective-C; they do not also invoke completion.

| Status | `result` | `error` |
| --- | --- | --- |
| `completed` | `OptikosPrimeResult` | nil |
| `cancelled` | nil | nil |
| `failed` | nil | `NSError` |

`OptikosPrimeResult` exposes `measurementID`, `leftEye`, `rightEye`, `conclusion`, and `questionnaire`. Each eye result exposes myopia, hyperopia, astigmatism, inconclusive, and normal values, plus optional unmeasurable-range bounds. Result objects are read-only and accessible from Objective-C.

`conclusion` uses `OptikosPrimeConclusion` (`finding`, `normal`, `inconclusive`). `questionnaire` uses `OptikosPrimeQuestionResult` (`notAnswered`, `normal`, `myopia`, `hyperopia`, `astigmatism`, `presbyopia`). Optional numeric eye ranges are nullable `NSNumber` in Objective-C.

JSON export is optional: call `try result.jsonData()` in Swift or `[result jsonDataAndReturnError:&error]` in Objective-C. Serialized enum values remain strings.

SDK errors use domain `com.optikosprime.sdk`, available as `OptikosPrimeSDKBridge.errorDomain` in Swift and `[OptikosPrimeSDK errorDomain]` in Objective-C. Inspect the domain and code, rather than comparing error messages.

| Code | `OptikosPrimeErrorCode` case |
| --- | --- |
| 1001 | `notInitialized` |
| 1002 | `invalidLicense` |
| 1003 | `deviceNotSupported` |
| 1004 | `cameraUnavailable` |
| 1005 | `networkFailure` |
| 1006 | `invalidResult` |
| 1007 | `sessionChanged` |
| 1008 | `testFailed` |

## Optional camera-info check

Use this after initialization if your app wants to hide or disable its test button before presenting the SDK.

Swift, from an asynchronous context:

```swift
let info = try await OptikosPrimeSDK.getCameraInfo()
// Use info.supported to decide whether to offer the test.
```

Objective-C, with completion on the main thread:

```objc
[OptikosPrimeSDK getCameraInfoWithCompletion:^(OptikosPrimeCameraInfo *info, NSError *error) {
    if (error != nil) {
        // Support could not be determined. Allow the user to retry.
        return;
    }
    // Use info.supported to decide whether to offer the test.
}];
```

`OptikosPrimeCameraInfo` contains `supported`, `isTelephotoUsable`, `cameraSubjectDistance` in meters, `torchStrength`, `irisRadiusMin`, and `irisRadiusMax`. Numeric properties are nullable `NSNumber` values.

The SDK stores the response and download timestamp in `UserDefaults.standard` under **`optikosPrimeCameraInfo`**, scoped to the device model and environment:

- Supported and unsupported responses are cached for **one hour**.
- At one hour, the next request downloads fresh data.
- Concurrent requests share an in-flight download.
- Failed downloads are not cached; expired data is not used as a fallback.
- Both explicit checks and automatic test startup use this cache.

An unsupported device is a successful camera-info response with `supported == false`. Attempting a test on that device produces a failed outcome with `deviceNotSupported`. Failure to fetch required camera info also stops the flow with an error.

Downloaded settings configure the camera; missing numeric fields fall back to `configuration.camera`.

## Flow options and individual screens

Swift integrators can configure `OptikosPrimeFlowOptions` to control instructions, result presentation, questionnaire availability, and retry. Advanced tests can request a landscape capture after a qualifying portrait result; choose `.simple` for portrait-only testing.

Standalone instruction, questionnaire, and result controllers show individual screens. They do not start the complete test or perform the camera-support check. The camera-validation controller starts the capture/analysis flow, including the automatic support check.

Prefer the complete-flow entry point for a guided test with a terminal outcome. Saving results and appointment booking belong to the host application. SDK analytics are disabled unless the host installs an analytics provider.

## Migrating from the previous interface

- Replace the Objective-C `(NSData *, NSString *)` completion and Swift completion enum with `OptikosPrimeOutcome`.
- Switch on `outcome.status` and read `outcome.result` or `outcome.error`.
- Replace status-string comparisons with the documented error domain and enum codes.
- Results become immutable `NSObject` classes. Enum raw values become integers; use `stringValue` when text is needed.
- Use `.notAnswered` instead of a nil questionnaire.
- Rebuild native adapters against the updated generated header.

## Example app and React Native

See [TestApp](TestApp/README.md) for the sample application with Swift and Objective-C integrations. Its package dependency and examples will be updated after this SDK release is published.

This repository does not provide a React Native package or complete bridge. A native adapter should translate the typed outcome into JavaScript values, using optional JSON export if convenient. The [React Native integration guide](TestApp/REACT_NATIVE.md) currently describes the previous callback interface and will be updated alongside TestApp; use the typed contract above for this SDK version.
