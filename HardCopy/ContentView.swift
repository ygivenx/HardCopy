// ContentView.swift
import SwiftUI
import AVFoundation

struct CameraOverlay: View {
    var highlightHeight: CGFloat

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let topPadding = (height - highlightHeight) / 2

            ZStack {
                // Subtle dark overlay with rounded corners
                VStack(spacing: 0) {
                    Color.black.opacity(0.15)
                        .frame(height: topPadding)

                    Spacer()
                }

                VStack(spacing: 0) {
                    Spacer()

                    Color.black.opacity(0.15)
                        .frame(height: topPadding)
                }

                // Modern corner brackets - primary blue color
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: topPadding)

                    // Corner brackets
                    VStack(spacing: 0) {
                        HStack {
                            // Top-left corner
                            VStack(alignment: .leading, spacing: 0) {
                                Rectangle()
                                    .fill(Color(red: 37/255, green: 99/255, blue: 235/255))
                                    .frame(width: 40, height: 3)
                                Rectangle()
                                    .fill(Color(red: 37/255, green: 99/255, blue: 235/255))
                                    .frame(width: 3, height: 40)
                            }

                            Spacer()

                            // Top-right corner
                            VStack(alignment: .trailing, spacing: 0) {
                                Rectangle()
                                    .fill(Color(red: 37/255, green: 99/255, blue: 235/255))
                                    .frame(width: 40, height: 3)
                                HStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(Color(red: 37/255, green: 99/255, blue: 235/255))
                                        .frame(width: 3, height: 40)
                                }
                            }
                        }

                        Spacer()
                            .frame(height: highlightHeight - 46)

                        HStack {
                            // Bottom-left corner
                            VStack(alignment: .leading, spacing: 0) {
                                Rectangle()
                                    .fill(Color(red: 37/255, green: 99/255, blue: 235/255))
                                    .frame(width: 3, height: 40)
                                Rectangle()
                                    .fill(Color(red: 37/255, green: 99/255, blue: 235/255))
                                    .frame(width: 40, height: 3)
                            }

                            Spacer()

                            // Bottom-right corner
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(Color(red: 37/255, green: 99/255, blue: 235/255))
                                        .frame(width: 3, height: 40)
                                }
                                Rectangle()
                                    .fill(Color(red: 37/255, green: 99/255, blue: 235/255))
                                    .frame(width: 40, height: 3)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct ContentView: View {
    @State private var recognizedText: String = ""
    @State private var showCopiedToast = false
    @State private var toastMessage: String = "Saved ✅"
    @State private var isCameraMinimized = false
    @State private var selectedText: String = ""
    @State private var showingSnippetViewer = false
    @State private var snippetSource: String = ""
    @State private var snippetTags: [String] = []
    @State private var tagInput: String = ""
    @State private var showSourceEditor = false

    let predefinedTags = ["book-snippet", "idea", "quote", "definition", "reference", "question", "insight", "research"]

    @StateObject private var snippetsManager = SnippetsManager()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // App Header
                HStack {
                    Text("ClikCopy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.label))
                        .padding(.leading)

                    Spacer()

                    Button(action: {
                        showingSnippetViewer = true
                    }) {
                        Image(systemName: "list.bullet")
                            .imageScale(.large)
                            .padding()
                    }
                    .accessibilityLabel("View saved snippets")
                }

                Spacer()

                if !isCameraMinimized {
                    ZStack {
                        CameraView { cgImage, previewLayer in
                            // This callback is called on videoQueue (background thread)
                            // We need to access UIKit/AVFoundation on main thread
                            DispatchQueue.main.async {
                                let cameraHeight: CGFloat = 300
                                let highlightHeight: CGFloat = 150
                                let screenWidth = UIScreen.main.bounds.width
                                let cameraWidth = screenWidth - 32

                                // Calculate overlay rectangle in preview layer coordinates
                                let topPadding = (cameraHeight - highlightHeight) / 2
                                let overlayRect = CGRect(
                                    x: 16,  // padding from CameraOverlay
                                    y: topPadding,
                                    width: cameraWidth - 32,  // subtract both sides padding
                                    height: highlightHeight
                                )

                                // Do coordinate conversion on main thread (required by AVFoundation)
                                let topLeft = previewLayer.captureDevicePointConverted(fromLayerPoint: overlayRect.origin)
                                let bottomRight = previewLayer.captureDevicePointConverted(
                                    fromLayerPoint: CGPoint(x: overlayRect.maxX, y: overlayRect.maxY)
                                )

                                // Move heavy processing to background thread
                                DispatchQueue.global(qos: .userInitiated).async {
                                    if let cropped = cropImageToNormalizedRect(from: cgImage, topLeft: topLeft, bottomRight: bottomRight) {
                                        let recognizer = TextRecognizer()
                                        recognizer.recognizeText(from: cropped) { result in
                                            DispatchQueue.main.async {
                                                recognizedText = result
                                                withAnimation {
                                                    isCameraMinimized = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 300)

                        // Overlay with highlighted region
                        CameraOverlay(highlightHeight: 150)
                    }
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 2)
                    .padding(.horizontal)
                }

                if isCameraMinimized {
                    SelectableTextView(text: cleanRecognizedText(recognizedText), selectedText: $selectedText)
                        .frame(minHeight: 150, maxHeight: .infinity)
                        .foregroundColor(Color(.label))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 2)
                        .padding()
                    
                    // SHOW SOURCE
                    if !snippetSource.isEmpty {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "book.fill")
                                    .foregroundColor(Color(red: 37/255, green: 99/255, blue: 235/255))

                                Text(snippetSource)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }

                            Spacer()

                            HStack(spacing: 16) {
                                Button(action: {
                                    showSourceEditor = true
                                }) {
                                    Image(systemName: "pencil")
                                        .imageScale(.medium)
                                        .foregroundColor(Color(red: 100/255, green: 116/255, blue: 139/255))
                                }

                                Button(action: {
                                    withAnimation {
                                        snippetSource = ""
                                        snippetTags = []
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .imageScale(.medium)
                                        .foregroundColor(Color(red: 239/255, green: 68/255, blue: 68/255))
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 2)
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        Button(action: {
                            showSourceEditor = true
                        }) {
                            Label("Add Source", systemImage: "plus")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 37/255, green: 99/255, blue: 235/255))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showSourceEditor) {
                            SourceEntryModal(source: $snippetSource, onSave: {
                                if snippetTags.isEmpty {
                                    snippetTags = ["book-snippet"]
                                }
                            })
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 100/255, green: 116/255, blue: 139/255))
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(predefinedTags, id: \.self) { tag in
                                    let isSelected = snippetTags.contains(tag)
                                    Button(action: {
                                        if isSelected {
                                            snippetTags.removeAll { $0 == tag }
                                        } else {
                                            snippetTags.append(tag)
                                        }
                                    }) {
                                        Text(tag)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(isSelected ? Color.white : Color(red: 100/255, green: 116/255, blue: 139/255))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                isSelected ?
                                                LinearGradient(
                                                    colors: [Color(red: 37/255, green: 99/255, blue: 235/255), Color(red: 29/255, green: 78/255, blue: 216/255)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ) :
                                                LinearGradient(
                                                    colors: [Color.white, Color.white],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .cornerRadius(12)
                                            .shadow(color: isSelected ? Color(red: 37/255, green: 99/255, blue: 235/255).opacity(0.25) : Color.black.opacity(0.08), radius: isSelected ? 8 : 4, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)


                    HStack(spacing: 12) {
                        // Save Button
                        Button(action: {
                            let cleanedSelected = cleanRecognizedText(selectedText)
                            let cleanedFull = cleanRecognizedText(recognizedText)
                            let textToSave = cleanedSelected.isEmpty ? cleanedFull : cleanedSelected

                            let newSnippet = Snippet(text: textToSave, source: snippetSource, tags: snippetTags)
                            snippetsManager.addSnippet(newSnippet)

                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                            toastMessage = "Saved ✅"
                            withAnimation {
                                showCopiedToast = true
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCopiedToast = false
                                    recognizedText = ""
                                    selectedText = ""
                                    isCameraMinimized = false
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .imageScale(.medium)
                                Text("Save")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 16/255, green: 185/255, blue: 129/255), Color(red: 5/255, green: 150/255, blue: 105/255)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.35), radius: 7, x: 0, y: 4)
                        }

                        // Copy Button
                        Button(action: {
                            let cleanedSelected = cleanRecognizedText(selectedText)
                            let cleanedFull = cleanRecognizedText(recognizedText)
                            let textToCopy = cleanedSelected.isEmpty ? cleanedFull : cleanedSelected

                            UIPasteboard.general.string = textToCopy
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()

                            toastMessage = "Copied ✅"
                            withAnimation {
                                showCopiedToast = true
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showCopiedToast = false
                                }
                            }
                        }) {
                            Image(systemName: "doc.on.doc.fill")
                                .imageScale(.large)
                                .foregroundColor(.white)
                                .frame(width: 60)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 37/255, green: 99/255, blue: 235/255), Color(red: 29/255, green: 78/255, blue: 216/255)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color(red: 37/255, green: 99/255, blue: 235/255).opacity(0.35), radius: 7, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()

                Button(action: {
                    NotificationCenter.default.post(name: .triggerScan, object: nil)
                }) {
                    Text("Scan")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 37/255, green: 99/255, blue: 235/255), Color(red: 29/255, green: 78/255, blue: 216/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color(red: 37/255, green: 99/255, blue: 235/255).opacity(0.35), radius: 7, x: 0, y: 4)
                }
                .padding(.horizontal)

                Spacer()

                Text("Highlight your favorite lines \u{1F4DA}")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
                    .padding(.bottom, 50)
            }
            .background(Color(red: 248/255, green: 250/255, blue: 252/255))
            .sheet(isPresented: $showingSnippetViewer) {
                SnippetListView(manager: snippetsManager)
            }

            if showCopiedToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .font(.system(size: 15, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 30)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerScan)) { _ in
            withAnimation {
                isCameraMinimized = false
                recognizedText = ""
                selectedText = ""
                
                // Load last-used source if it's recent
                print("Finding recent sources...")
                if let recent = SourceHistoryManager.load() {
                    snippetSource = recent
                    if snippetTags.isEmpty {
                        snippetTags = ["book-snippet"]
                    }
                } else {
                    snippetSource = ""
                    snippetTags = []
                }
            }
        }
    }
}

extension Notification.Name {
    static let triggerScan = Notification.Name("triggerScan")
}

func cleanRecognizedText(_ text: String) -> String {
    return text
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .reduce(into: [String]()) { result, line in
            if line.isEmpty {
                if result.last != "" {
                    result.append("")
                }
            } else {
                result.append(line)
            }
        }
        .joined(separator: "\n")
}

func cropToCameraPreview(from image: CGImage, previewHeightInPoints: CGFloat) -> CGImage? {
    let imageWidth = image.width
    let imageHeight = image.height
    let screenScale = UIScreen.main.scale
    let previewHeightInPixels = Int(previewHeightInPoints * screenScale)
    let cropY = (imageHeight - previewHeightInPixels) / 2
    let cropRect = CGRect(x: 0, y: cropY, width: imageWidth, height: previewHeightInPixels)
    return image.cropping(to: cropRect)
}

func cropToHighlightRegion(from image: CGImage, previewLayer: AVCaptureVideoPreviewLayer, overlayRect: CGRect) -> CGImage? {
    // Convert overlay corners from preview layer coordinates to device coordinates (0.0-1.0)
    let topLeft = previewLayer.captureDevicePointConverted(fromLayerPoint: overlayRect.origin)
    let bottomRight = previewLayer.captureDevicePointConverted(
        fromLayerPoint: CGPoint(x: overlayRect.maxX, y: overlayRect.maxY)
    )

    return cropImageToNormalizedRect(from: image, topLeft: topLeft, bottomRight: bottomRight)
}

func cropImageToNormalizedRect(from image: CGImage, topLeft: CGPoint, bottomRight: CGPoint) -> CGImage? {
    // Calculate crop rectangle in image pixel coordinates from normalized device coordinates
    let imageWidth = CGFloat(image.width)
    let imageHeight = CGFloat(image.height)

    let cropRect = CGRect(
        x: topLeft.x * imageWidth,
        y: topLeft.y * imageHeight,
        width: (bottomRight.x - topLeft.x) * imageWidth,
        height: (bottomRight.y - topLeft.y) * imageHeight
    )

    return image.cropping(to: cropRect)
}
