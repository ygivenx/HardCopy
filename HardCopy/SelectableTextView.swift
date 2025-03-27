//
//  SelectableTextView.swift
//  HardCopy
//
//  Created by Rohan Singh on 3/26/25.
//
import SwiftUI

struct SelectableTextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = UIColor.systemBackground
        textView.textColor = UIColor.label
        textView.font = UIFont.systemFont(ofSize: 16)
        return textView 
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}
