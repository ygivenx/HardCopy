//
//  InterceptingTextView.swift
//  HardCopy
//
//  Created by Rohan Singh on 3/27/25.
//


import UIKit

class InterceptingTextView: UITextView {
    override var canBecomeFirstResponder: Bool { true }

    // Disable copy menu
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
}
