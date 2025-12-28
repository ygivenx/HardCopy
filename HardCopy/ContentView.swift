// ContentView.swift
import SwiftUI

struct CameraOverlay: View {
    var highlightHeight: CGFloat

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let maskY = (height - highlightHeight) / 2

            ZStack {
                // Dark overlay with transparent highlight region
                Color.black.opacity(0.5)
                    .mask {
                        Rectangle()
                            .overlay(
                                Rectangle()
                                    .frame(height: highlightHeight)
                                    .offset(y: maskY)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    }

                // Guide lines at top and bottom of highlight region
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: maskY)

                    // Top guide line
                    Rectangle()
                        .fill(Color.green)
                        .frame(height: 2)

                    Spacer()
                        .frame(height: highlightHeight - 4)

                    // Bottom guide line
                    Rectangle()
                        .fill(Color.green)
                        .frame(height: 2)

                    Spacer()
                }

                // Corner brackets for better visual guidance
                VStack {
                    Spacer()
                        .frame(height: maskY)

                    HStack {
                        // Top-left corner
                        VStack(alignment: .leading, spacing: 0) {
                            Rectangle().fill(Color.green).frame(width: 30, height: 3)
                            Rectangle().fill(Color.green).frame(width: 3, height: 30)
                        }

                        Spacer()

                        // Top-right corner
                        VStack(alignment: .trailing, spacing: 0) {
                            Rectangle().fill(Color.green).frame(width: 30, height: 3)
                            HStack {
                                Spacer()
                                Rectangle().fill(Color.green).frame(width: 3, height: 30)
                            }
                        }
                    }

                    Spacer()
                        .frame(height: highlightHeight - 30)

                    HStack {
                        // Bottom-left corner
                        VStack(alignment: .leading, spacing: 0) {
                            Rectangle().fill(Color.green).frame(width: 3, height: 30)
                            Rectangle().fill(Color.green).frame(width: 30, height: 3)
                        }

                        Spacer()

                        // Bottom-right corner
                        VStack(alignment: .trailing, spacing: 0) {
                            HStack {
                                Spacer()
                                Rectangle().fill(Color.green).frame(width: 3, height: 30)
                            }
                            Rectangle().fill(Color.green).frame(width: 30, height: 3)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 8)
            }
        }
        .allowsHitTesting(false)
    }
}

struct ContentView: View {
    @State private var recognizedText: String = ""
    @State private var showCopiedToast = false
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
                    Text("HardCopy")
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
                        CameraView { cgImage in
                            let cameraHeight: CGFloat = 300
                            let highlightHeight: CGFloat = 150 // Height of the focus region
                            if let cropped = cropToHighlightRegion(from: cgImage, previewHeightInPoints: cameraHeight, highlightHeight: highlightHeight) {
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
                        .frame(height: 300)

                        // Overlay with highlighted region
                        CameraOverlay(highlightHeight: 150)
                    }
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                if isCameraMinimized {
                    SelectableTextView(text: cleanRecognizedText(recognizedText), selectedText: $selectedText)
                        .frame(minHeight: 150, maxHeight: .infinity)
                        .foregroundColor(Color(.label))
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .padding()
                    
                    // SHOW SOURCE
                    if !snippetSource.isEmpty {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "book.fill")
                                    .foregroundColor(.blue)

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
                                        .foregroundColor(.gray)
                                }

                                Button(action: {
                                    withAnimation {
                                        snippetSource = ""
                                        snippetTags = []
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .imageScale(.medium)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        Button(action: {
                            showSourceEditor = true
                        }) {
                            Label("Add Source", systemImage: "plus")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
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

                    VStack(alignment: .leading) {
                        Text("Tags:")
                            .font(.caption)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
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
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(isSelected ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }


                    Button(action: {
                        let cleanedSelected = cleanRecognizedText(selectedText)
                        let cleanedFull = cleanRecognizedText(recognizedText)
                        let textToCopy = cleanedSelected.isEmpty ? cleanedFull : cleanedSelected

                        UIPasteboard.general.string = textToCopy
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()

                        let newSnippet = Snippet(text: textToCopy, source: snippetSource, tags: snippetTags)
                        snippetsManager.addSnippet(newSnippet)

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
                        Text("Copy to Clipboard")
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()

                Button(action: {
                    NotificationCenter.default.post(name: .triggerScan, object: nil)
                }) {
                    Text("Scan")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()

                Text("Highlight your favorite lines \u{1F4DA}")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
                    .padding(.bottom, 50)
            }
            .background(Color(.systemBackground))
            .sheet(isPresented: $showingSnippetViewer) {
                SnippetListView(manager: snippetsManager)
            }

            if showCopiedToast {
                VStack {
                    Spacer()
                    Text("Copied ✅")
                        .font(.caption)
                        .padding(10)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
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

func cropToHighlightRegion(from image: CGImage, previewHeightInPoints: CGFloat, highlightHeight: CGFloat) -> CGImage? {
    let imageWidth = image.width
    let imageHeight = image.height
    let screenScale = UIScreen.main.scale

    // Convert preview and highlight heights to pixels
    let previewHeightInPixels = Int(previewHeightInPoints * screenScale)
    let highlightHeightInPixels = Int(highlightHeight * screenScale)

    // First, calculate where the camera preview sits in the full image
    let previewCropY = (imageHeight - previewHeightInPixels) / 2

    // Then, calculate where the highlight region sits within that preview
    let highlightOffsetInPreview = (previewHeightInPixels - highlightHeightInPixels) / 2

    // Final crop Y position in the full image
    let finalCropY = previewCropY + highlightOffsetInPreview

    let cropRect = CGRect(x: 0, y: finalCropY, width: imageWidth, height: highlightHeightInPixels)
    return image.cropping(to: cropRect)
}
