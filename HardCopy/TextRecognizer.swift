//
//  TextRecognizer.swift
//  HardCopy
//
//  Created by rsingh on 3/26/25.
//

import Vision
import UIKit

class TextRecognizer {
    func recognizeText(from image: CGImage, completion: @escaping (String) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else {
                print("Text recognition error: \(error!.localizedDescription)")
                completion("")
                return
            }

            let recognizedStrings = request.results?
                .compactMap { $0 as? VNRecognizedTextObservation }
                .compactMap { $0.topCandidates(1).first?.string } ?? []

            let combinedText = recognizedStrings.joined(separator: "\n")
            completion(combinedText)
        }

        request.recognitionLanguages = ["en-US"]
        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error)")
                completion("")
            }
        }
    }
}
