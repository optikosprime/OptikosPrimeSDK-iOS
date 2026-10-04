# React Native integration — iOS

This guide describes how to wrap the Optikos Prime binary SDK in your application's native module. **This repository does not provide a React Native package or a tested React Native bridge.** The snippets below illustrate the integration contract; module registration and lifecycle handling belong in your app.

The native SDK calls are demonstrated in [ObjCSDKExample.m](TestApp/ObjCSDKExample.m). Swift and Objective-C simulator tests verify initialization, instructions, cancellation, cached camera-info reuse, and unsupported-device handling using controlled camera-info responses. Complete camera measurement requires a physical iPhone.

## 1. Add the SDK to your iOS app

1. Open your React Native app's iOS `.xcworkspace` in Xcode.
2. Add `https://github.com/optikosprime/OptikosPrimeSDK-iOS` under **File → Add Package Dependencies** and select the `OptikosPrimeSDK` library for your application target.
3. Select SDK package **0.0.3**, the version verified by TestApp. It uses **MediaPipeRuntime from MediaPipe 1.0.1 or later** and includes the 0.0.3 SDK binary. Do not select SDK package tag `0.0.1`, which lacks the required dependency wiring.
4. Set the app's deployment target to **iOS 16.6 or later**, or your React Native version's minimum if higher. Reconcile this with your Podfile's deployment target.
5. Compile your app-owned native adapter in the application target that links the SDK. A separately packaged native module needs its own dependency integration; adding a package to the app does not automatically expose its headers to every CocoaPods target.

SwiftPM supplies `MediaPipeCommonGraphLibraries.framework`. Do not also add the full `SwiftTasksVision` product: the Optikos SDK binary already contains the measurement code and its resources.

For Expo, use a development build containing your native module. Expo Go cannot load arbitrary custom native code. If using prebuild, preserve native configuration through the project's configuration/plugin workflow. See [Expo: adding custom native code](https://docs.expo.dev/workflow/customizing/).

## 2. Configure permissions and licensing

Add these entries to your app's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>The camera is used to perform your vision check.</string>
<key>SDKLicenseKey</key>
<string>YOUR_APP_LICENSE</string>
```

Obtain a license for **your app's bundle identifier**. The license included in TestApp is issued for `com.optikosprime.SDKUIKitExample`; keep your application's own identifier and use its corresponding license. Initialize with `OptikosPrimeEnvironmentProduction` for a production license, or `OptikosPrimeEnvironmentDevelopment` for a development license.

`SDKLicenseKey` is an example host-app setting. Your native module reads it and passes it to the SDK; the SDK does not read this key automatically. Keep initialization in the native layer so JavaScript only needs to request a check. The default flow uses a network service, so test with network access.

## 3. Expose a native module

For the New Architecture, follow React Native's [Turbo Native Module guide](https://reactnative.dev/docs/turbo-native-modules-introduction): define the typed specification, configure Codegen, and implement/register the generated iOS interface. Use the documentation version matching your application. Existing legacy integrations can refer to [iOS Native Modules](https://reactnative.dev/docs/legacy/native-modules-ios); legacy registration snippets are not a complete TurboModule implementation.

The SDK presents its own full-screen UIKit controller, so your module can expose a method rather than a React Native view component. The proposed app-owned interface is:

```typescript
// Illustrative app interface, not an exported SDK JavaScript API or Codegen spec.
export interface VisionCheckResult {
  measurementID: string;
  conclusion: 'finding' | 'normal' | 'inconclusive';
  leftEye: Record<string, unknown>;
  rightEye: Record<string, unknown>;
  questionnaire?: string;
}

export type VisionCheckOutcome =
  | {status: 'completed'; result: VisionCheckResult}
  | {status: 'cancelled'};

export interface OptikosNativeAdapter {
  startVisionCheck(isOlderThan43: boolean): Promise<VisionCheckOutcome>;
}
```

Adapt this contract to the types supported by your React Native Codegen version. Pass the actual age-group answer; TestApp hardcodes `true` only for demonstration.

## 4. Call the native SDK

Use the exported Objective-C header in your native implementation (`.m` or `.mm`, as required by your React Native module):

```objc
#import <OptikosPrimeSDK/OptikosPrimeSDK-Swift.h>
```

The following is a **partial native method body**, not a complete bridge. `licenseKey`, `isOlderThan43`, and the completion handler are supplied by your implementation:

```objc
NSError *error = nil;
BOOL initialized = [OptikosPrimeSDK
    initializeWithLicenseKey:licenseKey
    environment:OptikosPrimeEnvironmentProduction
    error:&error];
if (!initialized) {
    // Reject the pending JavaScript promise with error, then return.
    return;
}

UIViewController *controller = [OptikosPrimeSDK
    visionCheckViewControllerWithIsOlderThan43:isOlderThan43
    error:&error
    completion:^(OptikosPrimeOutcome *outcome) {
        // Dismiss the SDK, then settle the promise using the mapping below.
    }];
if (controller == nil) {
    // Reject the pending JavaScript promise with error, then return.
    return;
}
controller.modalPresentationStyle = UIModalPresentationFullScreen;
// Present controller from your app's active, visible UIViewController.
```

Implement these lifecycle rules in the adapter:

- Dispatch SDK initialization, controller creation, presentation, and dismissal to the main queue.
- Locate the visible presenter in the active app scene. Reject if it is unavailable or transitioning; do not assume the root controller is always the presenter.
- Track an active flow. Reject overlapping calls instead of leaving a promise pending. Avoid reinitializing the SDK during an active flow.
- Keep the promise callbacks alive until completion, dismiss the SDK controller, and settle the promise once after dismissal finishes. Clear the active-flow state on every failure and completion path.
- Handle native-module invalidation/React Native reload by cleaning up any presented flow and pending callbacks according to your module's lifecycle.

### Completion mapping

| SDK outcome | Adapter behavior |
|---|---|
| `OptikosPrimeStatusCancelled` | Resolve `{status: 'cancelled'}`. |
| `OptikosPrimeStatusFailed` | Reject with the SDK NSError domain, numeric code, and message. |
| `OptikosPrimeStatusCompleted` | Read the typed `outcome.result` and resolve `{status: 'completed', result: ...}`. |
| Initialization/controller creation returns an error | Reject immediately; no flow was presented. |

The SDK error domain is `[OptikosPrimeSDK errorDomain]` (`com.optikosprime.sdk`). Unsupported devices return `OptikosPrimeErrorCodeDeviceNotSupported` (1003). Preserve the domain and code so JavaScript can distinguish failures without parsing messages. Adapter-only errors such as `E_BUSY` remain your own conventions.

You can map the result properties directly, or call `[outcome.result jsonDataAndReturnError:&error]` and decode that data with `NSJSONSerialization`. Handle export/decoding errors before settling the promise. Do not parse the display strings returned by TestApp's `ObjCSDKExample` helper. An `inconclusive` measurement is still a completed SDK operation.

### Optional camera-support check

After initialization, `[OptikosPrimeSDK getCameraInfoWithCompletion:]` returns `OptikosPrimeCameraInfo` or `NSError`. Use `info.supported` to control whether JavaScript offers a test. This call is optional: the full flow checks automatically before instructions or capture. Both use a one-hour cache under `optikosPrimeCameraInfo`; expired data requires a successful download. Unsupported camera info is a valid response with `supported == NO`, whereas starting a test on that device produces a failed outcome.

## 5. Call your adapter from JavaScript

After implementing and registering your module, a caller could look like this:

```typescript
// `adapter` implements the illustrative OptikosNativeAdapter interface above.
async function runVisionCheck(
  adapter: OptikosNativeAdapter,
  isOlderThan43: boolean,
) {
  try {
    const outcome = await adapter.startVisionCheck(isOlderThan43);
    if (outcome.status === 'cancelled') return;
    // Update your screen using outcome.result.
  } catch (error) {
    // Show a suitable error and allow another attempt.
  }
}
```

Disable the start action while its promise is pending. For a shared Android/iOS screen, guard this iOS-only adapter by platform; this repository supplies no Android implementation.

## 6. Verify in your application

Check successful initialization, invalid licensing, cancellation, repeated taps, and reopening after dismissal. On an iPhone, also verify camera permission granted/denied, measurement and network failures, result delivery, and the questionnaire. Simulator smoke tests do not validate the camera or a complete server-backed measurement.

The Objective-C API in SDK binary `0.0.3` uses default styling and flow options. Custom Swift configuration/style structs are not exposed through that Objective-C API; use an app-owned Swift adapter if you need those options.
