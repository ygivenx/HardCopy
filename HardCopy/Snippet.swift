//
//  Snippet.swift
//  HardCopy
//
//  Created by Rohan Singh on 3/27/25.
//


import Foundation

struct Snippet: Identifiable, Codable {
    let id: UUID
    let text: String
    let timestamp: Date
    let source: String? // Optional: e.g., book title
    let tags: [String]

    init(text: String, source: String? = nil, tags: [String] = []) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.source = source
        self.tags = tags
    }
}
