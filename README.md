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

Select the `OptikosPrimeSDK` library for your application target. The SDK output contract and integration examples are documented below.

The package includes the `MediaPipeRuntime` dependency. Ensure `MediaPipeCommonGraphLibraries.framework` is embedded and signed in the host app. The SDK bundles its face-landmark model; your app does not need to supply one.

## Host app permissions

Add the camera usage description to the **host app’s** `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera to capture your eyes for a vision check.</string>
```

The SDK requests camera access when opening its camera. It uses video capture without a microphone input and does not save test captures to the system photo library. Its current measurement flow does not require microphone or photo-library access.

The camera also uses live `CMMotionManager` accelerometer and device-motion updates for orientation guidance. Whether these specific APIs require `NSMotionUsageDescription` remains unconfirmed in this integration; the existing VisionCheck app does not declare it. A fresh-install device check should include motion guidance as well as camera access and denial.

Production uses the HTTPS service at `cloud.optikosprime.com`. The public TestApp defaults to development; select its environment in `TestApp/TestApp/Info.plist`. It has no ATS exceptions. Development uses `https://dev.cloud.optikosprime.com/` and requires a development license. Both environments use normal TLS certificate and hostname validation.

## Localization

Built-in SDK screens support English, Danish, Italian, Dutch, and Swedish, matching VisionCheck. English is the default fallback. Assessment `title` and `subtitle` are localized; assessment types and JSON values remain stable across languages.

The SDK follows the app’s effective language. If your host app does not declare those languages, allow the SDK and its camera bundle to use their own translations by adding this to the host’s `Info.plist` (already enabled in TestApp):

```xml
<key>CFBundleAllowMixedLocalizations</key>
<true/>
```

Localize the host’s camera permission description separately. Custom strings supplied through `OptikosPrimeText` are displayed unchanged and should be translated by the host. Integration diagnostics and server error details retain their original text.

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
                print(result.measurementID, result.results.map { $0.type.stringValue })
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

For custom styling and flow options, use `visionCheckViewController(configuration:completion:)` with `OptikosPrimeConfiguration`. `OptikosPrimeStyle` controls colors, fonts, and layout; `OptikosPrimeText` controls configurable text. See [Themes and custom fonts](#themes-and-custom-fonts) for predefined styles and font overrides. These Swift configuration structs are not exposed to Objective-C.

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

## Themes and custom fonts

Choose a predefined `OptikosPrimeStyle`, then customize a local copy if needed. Pass the resulting style through `OptikosPrimeConfiguration` before constructing the SDK flow. This works with both SwiftUI and the Swift UIKit bridge; the Objective-C entry point uses the default style.

### Predefined themes

| Style | Appearance | Colors and typography |
| --- | --- | --- |
| `.default` | Follows the host's light/dark appearance | White pages and burgundy primary buttons in light mode; dark surfaces and muted red primary buttons in dark mode. Uses system typography. |
| `.red` | Fixed light appearance, including in a dark host | White pages, dark rounded text, red primary buttons with white labels, and pale pink secondary buttons with red labels. |

The red theme is opt-in. `OptikosPrimeStyle.default` and the default configuration remain unchanged.

The red palette uses these sRGB colors:

| Color role | Value |
| --- | --- |
| Page and card background | `#FFFFFF` |
| Primary and secondary text | `#1A1A1A` |
| Primary button background | `#BF2B34` |
| Primary button text | `#FFFFFF` |
| Secondary button and assessment tile background | `#FAEEEF` |
| Secondary button text | `#BF2B34` |

At the standard Dynamic Type size, `.red` uses 24-point bold titles, 18-point body text, and 20-point semibold button labels in the rounded system font. It supplies 32-point page padding, 12-point corners, and a 56-point minimum button height. Buttons can grow to fit larger or multiline text. The theme applies to the SDK's existing screens and artwork.

```swift
import OptikosPrimeSDK

let configuration = OptikosPrimeConfiguration(
    style: .red,
    isOlderThan43: isOlderThan43 // Use the age-group answer collected by your app.
)
```

After initialization, use this configuration with `OptikosPrimeVisionCheck(configuration:onCompletion:)` or `OptikosPrimeSDKBridge.visionCheckViewController(configuration:completion:)`. For standalone screens, pass the style to their `style:` parameter.

### Register a custom font in the host app

Add your `.ttf` or `.otf` files to the app target and ensure they appear in **Copy Bundle Resources**. Register each file in the **host app's** `Info.plist` under `UIAppFonts` (Fonts provided by application). These example filenames are placeholders; replace them with your own files:

```xml
<key>UIAppFonts</key>
<array>
    <string>BrandSans-Regular.ttf</string>
    <string>BrandSans-Semibold.ttf</string>
    <string>BrandSans-Bold.ttf</string>
</array>
```

The SDK does not bundle or register your custom font. See Apple's [custom font setup guide](https://developer.apple.com/documentation/uikit/adding-a-custom-font-to-your-app) for host-app registration details.

### Apply custom fonts to a predefined theme

Copy `.red` or `.default` and set the `familyName` on the typography roles you want to replace. Despite the property name, supply the registered font face's PostScript name, such as `BrandSans-Bold`, rather than its filename or a generic family name. Replace the placeholder names below with those from your font files:

```swift
import OptikosPrimeSDK

var style = OptikosPrimeStyle.red // Or OptikosPrimeStyle.default.
style.typography.display.familyName = "BrandSans-Regular"
style.typography.title.familyName = "BrandSans-Bold"
style.typography.body.familyName = "BrandSans-Regular"
style.typography.button.familyName = "BrandSans-Semibold"
style.typography.caption.familyName = "BrandSans-Regular"

let configuration = OptikosPrimeConfiguration(
    style: style,
    isOlderThan43: isOlderThan43
)
```

Setting only `familyName` preserves the chosen theme's colors, layout, font sizes, and Dynamic Type text styles. Set just one role to replace only that font. The predefined theme itself is a value and is not modified when you edit this copy.

For a custom font, select the regular, semibold, or bold face explicitly through `familyName`. The SDK's font renderer uses `weight` and `design` for system fonts; setting `familyName` selects the custom face instead of the red theme's rounded system design. Leave `familyName` as `nil` to use the theme's system font.

Custom fonts still scale with Dynamic Type using each role's `size` and `textStyle`. To adjust a base size while retaining its scaling behavior, change that role's `size`, for example `style.typography.body.size = 19`.

If the font does not appear, verify target membership, the exact `UIAppFonts` filenames, and the registered face name. Inspect the font's PostScript name in Font Book, or query the fonts available at runtime:

```swift
import UIKit

print(UIFont.fontNames(forFamilyName: "Brand Sans")) // Use your font's actual family name.
assert(UIFont(name: "BrandSans-Regular", size: 18) != nil)
```

Camera guidance and Help use their built-in fonts and colors; SDK font overrides do not replace them. Camera's rectangular guidance buttons do use the configured button radius. The bundled “Powered by OptikosPrime” artwork also keeps its own lettering.

## Outcomes and errors

Completion delivers one immutable `OptikosPrimeOutcome` on the main thread when the presented flow completes, is cancelled, or fails. Your app is responsible for dismissal. Immediate controller-construction errors use `throws` in Swift and `NSError **` in Objective-C; they do not also invoke completion.

| Status | `result` | `error` |
| --- | --- | --- |
| `completed` | `OptikosPrimeResult` | nil |
| `cancelled` | nil | nil |
| `failed` | nil | `NSError` |

`OptikosPrimeOutcome` reports exactly one terminal status. Only `completed` contains a result; `cancelled` has no result or error; `failed` contains an `NSError` with domain `com.optikosprime.sdk`, a stable error code, and a description. A completed test may still have an inconclusive assessment.

`OptikosPrimeResult` contains:

| Field | Type | Meaning |
| --- | --- | --- |
| `measurementID` | `String` | Server measurement/session identifier |
| `left` | `[OptikosPrimeAssessment]` | Final assessments for the left eye |
| `right` | `[OptikosPrimeAssessment]` | Final assessments for the right eye |
| `results` | `[OptikosPrimeAssessment]` | Aggregated assessments from both eyes |
| `leftEye`, `rightEye` | `OptikosPrimeEyeResult` | Original camera probabilities and optional measurement ranges |
| `questionnaire` | `OptikosPrimeQuestionResult` | Evaluated questionnaire assessment, or `.notAnswered` |
| `isNormal` | `Bool` | The aggregate contains only normal |
| `isInconclusive` | `Bool` | The aggregate is empty or contains only inconclusive |

Each `OptikosPrimeAssessment` exposes `type`, `title`, and `subtitle`. Use `type` for application logic; the display strings describe that assessment. Assessment types are `myopia`, `hyperopia`, `astigmatism`, `normal`, `presbyopia`, and `inconclusive`. VisionCheck’s `readingGlasses` assessment is named `presbyopia` in the SDK. These objects and arrays are available in both Swift and Objective-C.

Each original eye measurement exposes `myopia`, `hyperopia`, `astigmatism`, `inconclusive`, and `normal` as `Double` probability values, plus optional `unmeasurableRangeMinimum` and `unmeasurableRangeMaximum`. Objective-C receives nullable `NSNumber` for the optional bounds. Questionnaire evaluation does not overwrite these measurements.

### Per-eye and aggregated assessments

Without completed questions, each eye is classified using VisionCheck’s camera classifier: the highest probability across hyperopia, inconclusive, myopia, normal, and astigmatism determines its assessment. Ties use that order, so an all-zero result selects hyperopia. After successful questionnaire submission, the four answers and `isOlderThan43` determine one assessment applied to both eyes.

`results` is the deduplicated union of `left` and `right`. If another assessment exists, inconclusive is removed. If a specific assessment remains, normal is removed. Per-eye arrays keep their own assessments. Aggregate ordering is stable: myopia, hyperopia, astigmatism, normal, presbyopia, inconclusive.

| Left | Right | Aggregate |
| --- | --- | --- |
| myopia | hyperopia | myopia, hyperopia |
| normal | myopia | myopia |
| inconclusive | normal | normal |
| inconclusive | inconclusive | inconclusive |
| presbyopia | presbyopia | presbyopia |

### Read the result

```swift
if let result = outcome.result {
    for assessment in result.results {
        print(assessment.type.stringValue, assessment.title, assessment.subtitle)
    }
    let leftTypes = result.left.map { $0.type }
    let rightTypes = result.right.map { $0.type }
    let json = try result.jsonData()
}
```

```objc
OptikosPrimeResult *result = outcome.result;
for (OptikosPrimeAssessment *assessment in result.results) {
    if (assessment.type == OptikosPrimeAssessmentTypePresbyopia) {
        // Handle the specific assessment.
    }
    NSLog(@"%@ — %@", assessment.title, assessment.subtitle);
}
NSArray<OptikosPrimeAssessment *> *left = result.left;
NSArray<OptikosPrimeAssessment *> *right = result.right;
```

### JSON export

`try result.jsonData()` exports the result, not the outcome wrapper. Objective-C uses `jsonDataAndReturnError:`. Enum names serialize as strings. Assessment objects serialize only their `type`; display titles and subtitles are derived properties. `isNormal` and `isInconclusive` are also derived and not serialized. Unavailable range bounds are omitted. `questionnaire` is omitted when it is `.notAnswered`.

This example represents an inconclusive camera measurement followed by a presbyopia questionnaire assessment:

```json
{
  "measurementID": "7094a1a0-ee08-4b7a-b2dc-71b490f61d0d",
  "leftEye": {
    "hyperopia": 0.0,
    "myopia": 0.0,
    "astigmatism": 0.0,
    "inconclusive": 1.0,
    "normal": 0.0
  },
  "rightEye": {
    "hyperopia": 0.0,
    "myopia": 0.0,
    "astigmatism": 0.0,
    "inconclusive": 1.0,
    "normal": 0.0
  },
  "left": [{"type": "presbyopia"}],
  "right": [{"type": "presbyopia"}],
  "results": [{"type": "presbyopia"}],
  "questionnaire": "presbyopia"
}
```

The output does not include captured videos, individual questionnaire answers, or age. `questionnaire` contains the evaluated assessment, not the raw answers.

### Migrate from the coarse conclusion

Use `results` instead of switching on `conclusion == .finding`; use `left` and `right` for eye-specific assessments. `conclusion` and its initializer remain deprecated compatibility APIs. New JSON omits `conclusion`. Older result JSON can still be decoded: assessments are derived from its saved camera data and questionnaire. Rebuild native adapters against the updated SDK header and update JavaScript models to accept assessment arrays.

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
| 1009 | `questionnaireUploadCancelled` |

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

See [TestApp](TestApp/README.md) for the sample application. Select **Swift** or **Objective-C**, then use **Start full vision check** to present the complete SDK flow, with `isOlderThan43: true`. **Check camera support** demonstrates the optional camera-info API in the selected language; the full flow also checks support automatically. The SDK displays final assessments and returns the typed result to the host. The app calls the SDK directly without network fixtures or simulator device-model overrides. The Objective-C integration is implemented in `TestApp/ObjCSDKExample.m`. The app uses the binary SDK package.

This repository does not provide a React Native package or complete bridge. A native adapter should translate the typed outcome into JavaScript values, using optional JSON export if convenient. The [React Native integration guide](TestApp/REACT_NATIVE.md) describes the native adapter contract.


## Measurement sessions and questionnaire results

The SDK creates a measurement session before instructions and capture. Its UUID is reused for prediction uploads and questionnaire submission. The camera-support loading screen uses the configured SDK colors and typography.

All four questionnaire answers are required and saved before completing the questionnaire. Failed submissions can be retried; cancelling an unsaved questionnaire reports `questionnaireUploadCancelled` (error code 1009).

After successful submission, the answers and `isOlderThan43` determine the final assessment using VisionCheck’s four-question rules. The assessment is applied to both `left` and `right` and appears in aggregated `results`. `questionnaire` records that evaluation, while `leftEye` and `rightEye` retain the original camera probabilities and ranges. The SDK result screen displays the final assessment. Without completed questions, the camera-based per-eye assessments are used.

Verify the complete measurement and questionnaire flow on a supported physical iPhone; simulator tests cover app launch and public result/error contracts.
