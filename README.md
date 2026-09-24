# Stuff — capstone project

Stuff is an in-progress iPhone app for photographing purchases and organizing them as an inventory. Its visual direction is inspired by CapWords. The current project implements the capture flow and an on-device foreground segmentation preview; food recognition and inventory management are still planned work.

## What is implemented

- A SwiftUI app with **Capture** and **Storage** tabs.
- A Capture home screen with the device's current date and time-of-day greeting. The hero text pins near the top and fades as the page scrolls. Tapping the colorful circle opens the camera.
- A full-screen camera interface with a live iPhone camera preview, framing guides, shutter, close button, and photo-library picker. The app requests camera permission when needed. The photo-library picker is also available in Simulator, which has no live camera.
- Automatic segmentation after either taking a photo or choosing one from the library. Apple's Vision `VNGenerateForegroundInstanceMaskRequest` identifies foreground instances. The app creates a combined transparent cutout and a separate cutout for each detected instance.
- A segmentation review screen that animates the original photo's background fading into a solid color while the cutouts remain visible. The user can compare the original image, inspect individual cutouts, retake, or save.
- A Storage tab showing the 24 requested food-category tiles. These currently show placeholder counts and artwork.

## Capture flow

1. Tap the circle on the Capture home screen.
2. Take a photo with the shutter or choose one with the photo button.
3. Vision processes the photo on device. If it finds foreground objects, the review screen fades away the photo background and shows the segmented result. If it finds none, the screen explains the issue and allows a retake.
4. Tap the checkmark to save. Each capture is written under the app's `Documents/Captures/<unique-id>/` directory as `original.jpg`, `foreground.png`, and `item-1.png`, `item-2.png`, etc. The PNGs retain transparency.

## Source layout

```text
Stuff/
├── MyApp.swift                         App entry point
├── ContentView.swift                   Capture/Storage tab navigation
├── Shared/
│   └── AppPalette.swift                Shared colors
├── Features/
│   ├── Capture/
│   │   ├── Home/                        Greeting, hero circle, date card, wheel art
│   │   ├── Camera/                      Camera screen, native picker, framing overlay
│   │   └── Segmentation/                Vision processing, review UI, local image saving
│   └── Storage/                         Category grid and category definitions
└── Assets.xcassets/
```

The Xcode project uses a file-system-synchronized source group, so files in these folders are included without individual source-file entries in `project.pbxproj`.

## Current limits and next steps

- Vision's foreground mask separates visually prominent objects from the background. It does **not** identify food types, and nearby or overlapping products may be grouped into one instance.
- Saved cutouts are not yet linked to category tiles. The Storage screen does not yet display saved captures or real item counts.
- Item names, expiration estimates, storage recommendations, manual edits, and expiration-date sorting are not implemented yet.
- The Xcode project's current iPhone deployment target is **iOS 27.0**. A device running an older version needs a lower target and any required compatibility changes.

## Running on an iPhone

Open `Stuff.xcodeproj` in Xcode. In the **Stuff** target's **Signing & Capabilities**, enable automatic signing and select your Apple development team or Personal Team. Connect and trust your iPhone, enable **Settings → Privacy & Security → Developer Mode** if prompted, select the phone as the run destination, and press **Run**. If iOS reports an untrusted developer, open **Settings → General → VPN & Device Management** and allow the developer profile.

Builds and simulator runs are intentionally left for manual testing.
