import SwiftUI

struct ContentView: View {
    @State private var recognizedText: String = ""

    var body: some View {
        VStack {
            Text("Text Snippet Capture")
                .font(.title2)
                .bold()
                .padding(.top)

            Spacer()

            Image("SampleText")
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .border(Color.green)



            ScrollView {
                Text(recognizedText.isEmpty ? "Scanned text will appear here..." : recognizedText)
                    .padding()
            }
            .frame(height: 150)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding()

            Button(action: {
                // Simulate an image for now until we use a live camera frame
                if let sampleImage = UIImage(named: "SampleText")?.cgImage {
                    let recognizer = TextRecognizer()
                    recognizer.recognizeText(from: sampleImage) { result in
                        DispatchQueue.main.async {
                            recognizedText = result
                        }
                    }
                } else {
                    recognizedText = "⚠️ No sample image found."
                }
            }) {
                Text("Scan")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }


            Spacer()
        }
        .padding()
        .background(Color.white)
    }
}
