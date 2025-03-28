//
//  SelectableTextView.swift
//  HardCopy
//
//  Created by Rohan Singh on 3/26/25.
//
import SwiftUI

struct SelectableTextView: UIViewRepresentable {
    let text: String
    @Binding var selectedText: String

    func makeUIView(context: Context) -> InterceptingTextView {
        let textView = InterceptingTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor.label
        textView.text = text
        return textView
    }

    func updateUIView(_ uiView: InterceptingTextView, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SelectableTextView

        init(_ parent: SelectableTextView) {
            self.parent = parent
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            if let range = textView.selectedTextRange {
                parent.selectedText = textView.text(in: range) ?? ""
            }
        }
    }
}
