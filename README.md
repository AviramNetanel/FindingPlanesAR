# FindingPlanesAR

An iOS app built with **SwiftUI**, **ARKit**, and **RealityKit** that detects horizontal and vertical planes, optionally shows **LiDAR scene mesh** visualization, and surfaces live **tracking diagnostics** in a small overlay.

## Requirements

- **Xcode** with the iOS SDK your project targets (see `IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project).
- A physical **iPhone or iPad** with **ARKit** support. The Simulator is not suitable for full camera-based AR.
- **Camera** permission (the app requests access for AR).
- **LiDAR** (Pro models) is optional: **scene mesh** and **mesh classification** features are most useful there. On other devices, plane detection still works; mesh-related toggles may be limited or unavailable.

## Run on device

1. Open `FindingPlanesAR.xcodeproj` in Xcode.
2. Select your **development team** under Signing & Capabilities for the `FindingPlanesAR` target.
3. Connect your device and choose it as the run destination.
4. Build and run (Product > Run, or Command-R).

Grant camera access when prompted.

## What you see

- **AR view**: world tracking with colored plane overlays (by plane classification when available).
- **Tap**: places a small probe marker where a raycast hits a plane (existing vs estimated, depending on settings).
- **Status banner** (top):
  - Mesh anchor count and plane count.
  - Mesh capability / mode text.
  - Green/red indicators for map quality, tracking, and VIO-style readiness (derived from tracking state).
- **Configuration panel**: show/hide via **Hide Panel** / **Show Panel**.

## Configuration options

| Control | Effect |
|--------|--------|
| **Plane Mode** | **Existing** vs **Estimated** plane geometry for raycasts (and session messaging). |
| **Detect Horizontal / Vertical** | Which plane orientations ARKit searches for. |
| **Show Colored Planes** | Toggles the semi-transparent plane overlays. |
| **Show Plane Labels** | Short classification labels (e.g. wall, floor) on planes when ARKit provides them. |
| **Show Mesh Overlay** | RealityKit debug scene-understanding visualization (where supported). |
| **Classify Mesh** | Prefers mesh reconstruction with classification when the device supports it. |
| **People Occlusion** | Enables person segmentation depth semantics when supported. |
| **Reset Session** | Clears tracking and anchors and restarts with current settings. |

**Note:** The default **mesh overlay** uses system debug coloring; it is not a custom semantic color map from this app’s code.

## Project layout

| Path | Role |
|------|------|
| `FindingPlanesAR/FindingPlanesARApp.swift` | App entry. |
| `FindingPlanesAR/ContentView.swift` | SwiftUI shell, banner, and settings panel. |
| `FindingPlanesAR/ARViewContainer.swift` | `UIViewRepresentable` bridge to `ARView`. |
| `FindingPlanesAR/ARSessionController.swift` | Session configuration, plane/mesh entities, diagnostics. |
| `FindingPlanesAR/ARSettings.swift` | User-tunable flags and plane detection mode. |

## Tips

- Move the device slowly at first so tracking and mapping can stabilize.


## License

No license file is included in this repository by default. 
Please contact me if you wish to use this code for distribution.
