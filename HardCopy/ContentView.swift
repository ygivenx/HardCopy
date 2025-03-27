// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var recognizedText: String = ""
    @State private var cameraViewController: CameraViewController?
    @State private var showCopiedToast = false
    @State private var isCameraMinimized = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top App Name
                Text("HardCopy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.label))
                    .padding(.top, 15)

                VStack {

                    Spacer()

                    if !isCameraMinimized {
                        CameraView { cgImage in
                            let recognizer = TextRecognizer()
                            recognizer.recognizeText(from: cgImage) { result in
                                DispatchQueue.main.async {
                                    recognizedText = result
                                    withAnimation {
                                        isCameraMinimized = true
                                    }
                                }
                            }
                        }
                        .frame(height: 300)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    if isCameraMinimized {
                        SelectableTextView(text: recognizedText)
                            .frame(minHeight: 150, maxHeight: .infinity)
                            .foregroundColor(Color(.label))
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 2)
                            .padding()

                        Button(action: {
                            UIPasteboard.general.string = recognizedText
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()

                            withAnimation {
                                showCopiedToast = true
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCopiedToast = false
                                    recognizedText = ""
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
                }
                .padding()
                .background(
                    ZStack {
                        Color(.systemBackground)

                        VStack {
                            Spacer()
                            Text("Highlight your favorite lines 📚")
                                .font(.footnote)
                                .foregroundColor(Color(.secondaryLabel))
                                .padding(.bottom, 50)
                        }
                    }
                )
            }

            if showCopiedToast {
                Text("Copied ✅")
                    .font(.caption)
                    .padding(10)
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 30)
            }
        }.onReceive(NotificationCenter.default.publisher(for: .triggerScan)) { _ in
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
