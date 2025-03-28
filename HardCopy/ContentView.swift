// ContentView.swift
import SwiftUI

struct CameraOverlay: View {
    var highlightHeight: CGFloat

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let maskY = (height - highlightHeight) / 2

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
                    CameraView { cgImage in
                        let cameraHeight: CGFloat = 300
                        if let cropped = cropToCameraPreview(from: cgImage, previewHeightInPoints: cameraHeight) {
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

                    Button(action: {
                        let cleanedSelected = cleanRecognizedText(selectedText)
                        let cleanedFull = cleanRecognizedText(recognizedText)
                        let textToCopy = cleanedSelected.isEmpty ? cleanedFull : cleanedSelected

                        UIPasteboard.general.string = textToCopy
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()

                        let newSnippet = Snippet(text: textToCopy)
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
