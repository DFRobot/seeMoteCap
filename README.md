# seeMoteViewer

An example project for the seeMote general-purpose spatial accessory viewer.

This project demonstrates how to build a visionOS 27.0+ app that:
- Discovers and connects to `GCSpatialAccessory` spatial accessories
- Retrieves accessory anchors through `AccessoryTrackingProvider`
- Displays the accessory position, reference model, and digital replicas in a mixed immersive space
- Previews either a USDZ reference model supplied by the accessory or a bundled model

## Requirements

- Xcode 27.0 beta or later
- visionOS 27.0 SDK
- Apple Vision Pro or the visionOS simulator

## Opening the Project for the First Time

For detailed instructions, see: https://wiki.dfrobot.com/dfr1285

1. Open `seeMoteViewer.xcodeproj` in Xcode.
2. Select the `seeMoteViewer` target and open **Signing & Capabilities**:
   - Set **Team** to your Apple Developer Team (or Personal Team).
   - Change **Bundle Identifier** to a unique identifier that belongs to you, such as `com.yourcompany.seeMoteViewer`.
3. Select a visionOS simulator or connect an Apple Vision Pro device, then press `Cmd+R` to run the app.

## Project Structure

```
seeMoteViewer/
├── Core/
│   ├── AppState.swift                  # Container for global app state
│   ├── AppConfiguration.swift          # Static app configuration
│   ├── LocaleManager.swift             # In-app language switching
│   ├── AccessoryConnectionManager.swift# Accessory connection and disconnection monitoring
│   ├── TrackingSessionManager.swift    # ARKit authorization, session, and tracking provider lifecycle
│   ├── AccessoryTracker.swift          # Unified state and operations interface for the view layer
│   ├── PreviewLoader.swift             # Preview model loading
│   ├── ReplicaPlacementController.swift# Digital replica placement/removal signals
│   ├── HapticController.swift          # Haptic engine control
│   ├── HapticCoordinator.swift         # Haptic controller lifecycle coordination
│   └── SceneState.swift                # Immersive space state
├── Reality/
│   ├── EntityFactory.swift             # Entity factory and visualization placeholders
│   ├── AnchorManager.swift             # Anchor entity creation and management
│   └── TrackingMode+Localization.swift # Localization for tracking modes and accessory positions
├── Utilities/
│   ├── Logger+seeMote.swift            # Logging extensions
│   └── CancellableTask.swift           # Cancellable task wrapper
├── Views/
│   ├── ControlPanelView.swift          # Main control panel
│   ├── WorldOverlayView.swift          # Mixed immersive space view
│   └── ToggleImmersiveSpaceButton.swift# Button for opening/closing the immersive space
├── Resources/
│   ├── model1.usdz                     # Bundled preview model
│   ├── logo.png                        # App icon/logo
│   └── cap-202607152.referenceaccessory# Reference accessory file
├── Localizable.xcstrings               # Chinese and English localization
├── Info.plist                          # Scene configuration and reference accessory type declarations
└── seeMoteViewer.entitlements          # Sandbox and networking capabilities
```

## Core Modules

- **AccessoryConnectionManager**: Observes `GCSpatialAccessory.spatialAccessories`, manages connection state, and invokes callbacks when connected devices change.
- **TrackingSessionManager**: Runs an `ARKitSession`, manages the `AccessoryTrackingProvider`, and exposes authorization status, tracking status, and the latest anchor.
- **AccessoryTracker**: Combines connection, tracking, preview loading, and replica control behind a single interface for the view layer.
- **PreviewLoader**: Loads the USDZ embedded in a `referenceaccessory` supplied by an accessory, or falls back to the bundled `model1.usdz`.
- **ReplicaPlacementController**: Uses `AsyncStream` to send digital replica placement and removal signals to the immersive space.
- **HapticController / HapticCoordinator**: Creates and restores a `CHHapticEngine` for the connected accessory, supporting both single-pulse and multi-pulse patterns.
- **WorldOverlayView**: Uses `RealityView` to render anchor markers, the reference model, and digital replicas in a mixed immersive space.

## Custom Accessory Support

If your seeMote accessory supplies its own USDZ preview model, add a new enum case to `PreviewLoader.PreviewModel` and load the corresponding resource.

## License

This project is provided by seeMote as a reference implementation for developers.
