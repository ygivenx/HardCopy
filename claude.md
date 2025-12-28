# ClikCopy iOS App

An iOS app for scanning and copying text from physical books, newspapers, and printed materials using OCR (Optical Character Recognition).

## Project Overview

**ClikCopy** allows users to:
- Scan text from physical materials using the device camera
- Focus on specific text regions with a visual highlight overlay
- Select and edit recognized text
- Add source information (book titles, etc.)
- Tag snippets with predefined categories
- Save and manage a history of scanned snippets
- Copy text to clipboard for use in other apps

## Architecture

### Tech Stack
- **Language**: Swift
- **Framework**: SwiftUI
- **OCR**: Vision Framework (VNRecognizeTextRequest)
- **Storage**: Local JSON files (UserDefaults for source history)
- **Camera**: AVFoundation (AVCaptureSession)

### Key Files

```
ClikCopy/
├── ClikCopyApp.swift           # App entry point
├── ContentView.swift           # Main UI with camera overlay and scan logic
├── CameraView.swift            # AVFoundation camera capture
├── TextRecognizer.swift        # Vision OCR wrapper
├── SelectableTextView.swift    # UITextView wrapper for text selection
├── Snippet.swift               # Data model for saved snippets
├── SnippetsManager.swift       # Storage manager (JSON persistence)
├── SnippetListView.swift       # History viewer UI
├── SourceEntryModal.swift      # Modal for entering source info
├── SourceHistoryManager.swift  # Source caching (1-hour memory)
└── InterceptingTextView.swift  # Custom UITextView
```

## Key Features

### 1. Focused Scan Region (Latest Feature)
- **Visual Overlay**: Green guide lines and corner brackets show the 150pt scan region
- **Darkened Areas**: Areas outside the scan box are darkened (50% opacity)
- **Precise Cropping**: Only text inside the highlighted region is processed by OCR
- **Implementation**: `CameraOverlay` component + `cropToHighlightRegion()` function

### 2. Text Recognition
- Uses Vision framework with `VNRecognizeTextRequest`
- Recognition level: Accurate
- Language: English (en-US)
- Processes cropped camera frame asynchronously

### 3. Source & Tag Management
- **Predefined Tags**: book-snippet, idea, quote, definition, reference, question, insight, research
- **Source Caching**: Last-used source remembered for 1 hour
- **Multiple Tags**: Users can select multiple tags per snippet

### 4. Snippet Storage
- Stored as JSON in app's Documents directory
- Each snippet contains:
  - `id` (UUID)
  - `text` (String)
  - `timestamp` (Date)
  - `source` (String?, optional)
  - `tags` ([String])

## User Flow

1. App launches → Camera preview with overlay
2. User positions text within green highlighted box
3. Tap "Scan" → Captures frame → OCR processes highlighted region
4. Recognized text displayed (selectable)
5. User optionally selects portion of text
6. User adds source (optional, e.g., "Sapiens by Yuval Noah Harari")
7. User selects tags from horizontal scroll list
8. Tap "Copy to Clipboard" → Text copied + Snippet saved
9. Toast notification "Copied ✅" + Haptic feedback
10. Camera resets after 2 seconds

## Building & Running

### Requirements
- macOS with Xcode 15+
- iOS 17.0+ target device or simulator
- Camera permissions (auto-requested on first launch)

### Commands

```bash
# Open in Xcode
open HardCopy.xcodeproj

# Build from command line
xcodebuild -project HardCopy.xcodeproj \
  -scheme HardCopy \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# Run tests
xcodebuild test -project HardCopy.xcodeproj \
  -scheme HardCopy \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Clean build
xcodebuild clean -project HardCopy.xcodeproj -scheme HardCopy
```

## Configuration

### Scan Region Customization

To adjust the highlight scan region size, modify `ContentView.swift`:

```swift
// Line 73: Adjust highlight height (default: 150pt)
let highlightHeight: CGFloat = 150 // Change to 100, 200, etc.

// Line 89: Update overlay to match
CameraOverlay(highlightHeight: 150) // Must match above
```

### Camera Preview Size

```swift
// Line 72: Camera preview height (default: 300pt)
let cameraHeight: CGFloat = 300
```

### Tag Customization

```swift
// Line 40: Predefined tags array
let predefinedTags = ["book-snippet", "idea", "quote", ...]
```

## Recent Changes

### Commit: 9481c32 - "Add focused scan region with visual guides"
- Enhanced `CameraOverlay` with green guide lines and corner brackets
- Added `cropToHighlightRegion()` function for precise cropping
- Camera now shows darkened areas outside scan region
- Solves issue of scanning unwanted text by providing clear visual boundaries

### Commit: 15f9a7d - "add tags and source"
- Added source tracking with modal entry
- Implemented tag system with 8 predefined tags
- Added source persistence (1-hour memory)
- Enhanced snippet metadata

### Commit: f276add - "tweak the workflow to copy highlighted text"
- Improved text selection workflow
- Enhanced snippet saving functionality

## Development Notes

### Known Patterns

1. **State Management**: Uses `@State` and `@StateObject` for local UI state
2. **Notifications**: Uses `NotificationCenter` for scan trigger (`.triggerScan`)
3. **Async Operations**: OCR runs on background queue, UI updates on main thread
4. **Storage**: JSON encoding/decoding for snippet persistence
5. **Camera Lifecycle**: Session starts in `viewDidLoad()`, permissions checked first

### Important Functions

- `cropToHighlightRegion()`: Crops camera frame to highlighted scan region
- `cleanRecognizedText()`: Removes extra whitespace/newlines from OCR results
- `saveLastSource()` / `loadRecentSource()`: Manages source caching
- `addSnippet()`: Saves snippet to persistent storage

## Common Tasks

### Add a New Tag
1. Edit `ContentView.swift` line 40
2. Add tag to `predefinedTags` array
3. Tag will appear in horizontal scroll picker

### Change Highlight Color
1. Edit `CameraOverlay` in `ContentView.swift`
2. Replace `.fill(Color.green)` with desired color

### Modify OCR Settings
1. Edit `TextRecognizer.swift`
2. Adjust `request.recognitionLanguages` for different languages
3. Change `request.recognitionLevel` (.fast vs .accurate)

### Export Snippets
Currently not implemented. To add:
1. Create export function in `SnippetsManager`
2. Add share button to `SnippetListView`
3. Use `UIActivityViewController` for sharing

## Future Enhancement Ideas

- [ ] Search/filter snippets by tag or source
- [ ] Export snippets (Markdown, CSV, JSON)
- [ ] iCloud sync across devices
- [ ] Statistics dashboard (most-used sources, tag analytics)
- [ ] Custom user-defined tags
- [ ] Save original scanned images alongside text
- [ ] Batch operations (select multiple snippets)
- [ ] Home screen widget for quick scanning
- [ ] Custom themes/color schemes
- [ ] Multi-language OCR support
- [ ] Text-to-speech for snippets
- [ ] Flashcard mode for study snippets

## Troubleshooting

### Camera Not Working
- Check Info.plist has `NSCameraUsageDescription`
- Verify camera permissions in Settings
- Test on physical device (simulators may have issues)

### OCR Not Recognizing Text
- Ensure good lighting
- Keep text within the green highlighted box
- Hold device steady during scan
- Try increasing `highlightHeight` for longer paragraphs

### Build Failures
- Clean build folder (Cmd+Shift+K in Xcode)
- Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Verify deployment target matches device/simulator iOS version

## Git Branch

Current development branch: `claude/ios-text-copy-app-DKV3m`

```bash
# Pull latest changes
git pull origin claude/ios-text-copy-app-DKV3m

# Create feature branch
git checkout -b feature/my-feature

# Push changes
git push -u origin feature/my-feature
```

## Contact & Contributing

This is a personal project by Rohan Singh (@ygivenx).

Repository: https://github.com/ygivenx/ClikCopy

## License

See LICENSE file in repository root.
