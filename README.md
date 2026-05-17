# FindingPlanesAR

Sample iOS app for **FindingPlanesSDK** — ARKit plane and LiDAR mesh detection with live diagnostics.

## Architecture

| Repo / path | Role |
|-------------|------|
| [`../FindingPlanesSDK`](../FindingPlanesSDK) | Swift package: AR session, UI, mesh semantics, performance metrics |
| `FindingPlanesAR/` | Thin app shell: `@main`, app icon, camera permission |
| `FindingPlanesAR/FindingPlanesARApp.swift` | Launches `FindingPlanesRootView()` from the SDK |

All feature code lives in **FindingPlanesSDK**. Edit the package, not duplicated sources in this app.

## Requirements

- **Xcode** with the iOS SDK your project targets (see `IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project).
- A physical **iPhone or iPad** with **ARKit** support. The Simulator is not suitable for full camera-based AR.
- **Camera** permission (configured via `INFOPLIST_KEY_NSCameraUsageDescription` in the app target).
- **LiDAR** (Pro models) is optional: scene mesh and mesh classification are most useful there.

## Run on device

1. Open `FindingPlanesAR.xcodeproj` in Xcode (or `FindingPlanesAR.code-workspace` to include the SDK folder).
2. Resolve the local Swift package: **File → Packages → Resolve Package Versions** if needed.
3. Select your **development team** under Signing & Capabilities for the `FindingPlanesAR` target.
4. Connect your device and run.

## Embed in another app

```swift
import SwiftUI
import FindingPlanesSDK

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            FindingPlanesRootView()
        }
    }
}
```

Add a local or remote package dependency on `FindingPlanesSDK` and set `NSCameraUsageDescription` in the host app Info.plist.

## Tips

- Move the device slowly at first so tracking and mapping can stabilize.
- Use **Live Info** for display vs AR FPS, frame lag, feature count, mesh drift, and quality grade.

## License

No license file is included by default. Contact the author for distribution terms.
