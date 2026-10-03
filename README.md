# Stuff — capstone project

Stuff is an in-progress iPhone app for photographing purchases and organizing them as an inventory. Its visual direction is inspired by CapWords. Capture, on-device item suggestions, and local inventory storage are implemented.

## What is implemented

- A SwiftUI app with **Capture**, **Storage**, and **Inspiration** tabs.
- A Capture home screen with the device's current date and time-of-day greeting. The hero text pins near the top and fades as the page scrolls. Tapping the colorful circle opens the camera. The date cards now show saved items grouped by capture day; tapping a filled card opens that day's item gallery.
- A full-screen camera interface using an AVFoundation preview layer, framing guides, shutter, close button, and photo-library picker. The preview fills the camera screen and uses continuous focus and exposure where supported. The app requests camera permission when needed. The photo-library picker is also available in Simulator, which has no live camera.
- Camera capture prioritizes quick delivery over maximum photo quality. Camera and library photos are decoded to a 2048-pixel review image off the screen thread before Vision analyzes them. The live camera pauses while a captured image is being reviewed.
- Automatic segmentation after either taking a photo or choosing one from the library. Apple's Vision `VNGenerateForegroundInstanceMaskRequest` identifies foreground instances. The app creates a combined transparent cutout and a separate cutout for each detected instance.
- A full-screen segmentation review that animates the original photo's background fading into a solid color while the cutouts remain visible. The user can compare the original image, inspect individual cutouts, retake, or save.
- Apple Foundation Models analyzes each cutout on the iPhone and suggests a food name, one of the 24 categories, a typical expiry date, and a storage assumption. The review sheet allows manual correction before saving. If Apple Intelligence is unavailable or analysis fails, the item remains editable with an unknown name and no expiry date.
- SwiftData stores one `StoredCapture` per photo and one `StoredItem` per cutout. The Storage tab shows real category counts. Each category opens an image-and-name gallery with white sticker outlines; tapping an item opens its detail page. Long-press an image to delete it, or use Delete on its detail page; the detail page confirms deletion beside the top-right trash button. Deleting the last item from a capture removes that capture's saved images.
- Inspiration shows the saved cutouts as gently floating stickers. Drag them to rearrange them, tap to select them, then tap **Generate Recipe**. Apple Foundation Models creates a meal idea on the iPhone using all selected items. The result lists the selected ingredients, any additional ingredients, and preparation steps. If the model is unavailable or the selection cannot reasonably make a meal, the app explains that instead.

## Capture flow

1. Tap the circle on the Capture home screen.
2. Take a photo with the shutter or choose one with the photo button.
3. Vision processes the photo on device. If it finds foreground objects, the review screen fades away the photo background and shows the segmented result. If it finds none, the screen explains the issue and allows a retake.
4. Review the suggested name, category, and expiry date for each cutout, then save. Each capture is written under the app's `Documents/Captures/<unique-id>/` directory as `original.jpg`, `foreground.png`, and `item-1.png`, `item-2.png`, etc. The PNGs retain transparency. SwiftData records hold the capture ID and item number so they can find the matching images.

Expiry dates are estimates based on what the model sees and its stated storage assumption. A photo alone cannot establish a product's actual use-by date or storage history. Check the package and edit the date when known. No photo or prompt is sent to a server by this implementation.

## Source layout

```text
Stuff/
├── MyApp.swift                         App entry point
├── ContentView.swift                   Capture/Storage/Inspiration tab navigation
├── Shared/
│   └── AppPalette.swift                Shared colors
├── Features/
│   ├── Capture/
│   │   ├── Home/                        Greeting, hero circle, date card, wheel art
│   │   ├── Camera/                      Camera screen, native picker, framing overlay
│   │   └── Segmentation/                Vision processing, review UI, local image saving
│   ├── Storage/                         Category grid and category definitions
│   └── Inspiration/                     Floating selection and on-device recipes
└── Assets.xcassets/
```

The Xcode project uses a file-system-synchronized source group, so files in these folders are included without individual source-file entries in `project.pbxproj`.

## Current limits and next steps

- Vision's foreground mask separates visually prominent objects from the background. It does **not** identify food types, and nearby or overlapping products may be grouped into one instance.
- Items from captures saved by older versions have image files but no SwiftData records, so they do not appear in Storage.
- The Xcode project's current iPhone deployment target is **iOS 27.0**. Image input to Foundation Models requires iOS 27 and a device with Apple Intelligence enabled. Other devices can still save items after entering details manually.
- The expiry estimate is not a food-safety guarantee. Printed dates, purchase date, package opening, temperature, and storage history are not automatically verified.
- Recipe ideas are model suggestions. Check that all selected ingredients are suitable and fresh before preparing a meal.

## Running on an iPhone

Open `Stuff.xcodeproj` in Xcode. In the **Stuff** target's **Signing & Capabilities**, enable automatic signing and select your Apple development team or Personal Team. Connect and trust your iPhone, enable **Settings → Privacy & Security → Developer Mode** if prompted, select the phone as the run destination, and press **Run**. If iOS reports an untrusted developer, open **Settings → General → VPN & Device Management** and allow the developer profile.

The project can be built in Xcode for an iPhone. Recipe generation itself requires an Apple Intelligence-capable iPhone with Apple Intelligence enabled.
