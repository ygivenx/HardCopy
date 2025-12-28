//
//  SourceHistoryManager.swift
//  HardCopy
//
//  Created by Rohan Singh on 3/29/25.
//

import Foundation

enum SourceHistoryManager {
    static func save(_ source: String) {
        guard !source.isEmpty else { return }

        // Save for 1-hour auto-fill
        let entry: [String: Any] = ["source": source, "timestamp": Date().timeIntervalSince1970]
        UserDefaults.standard.set(entry, forKey: "lastSnippetSource")

        // Also save to history
        var history = loadSourceHistory()

        // Remove if already exists (to move to front)
        history.removeAll { $0 == source }

        // Add to front
        history.insert(source, at: 0)

        // Keep only last 10
        if history.count > 10 {
            history = Array(history.prefix(10))
        }

        UserDefaults.standard.set(history, forKey: "sourceHistory")
    }

    static func load(within seconds: TimeInterval = 3600) -> String? {
        guard let entry = UserDefaults.standard.dictionary(forKey: "lastSnippetSource"),
              let source = entry["source"] as? String,
              let timestamp = entry["timestamp"] as? TimeInterval else { return nil }

        let age = Date().timeIntervalSince1970 - timestamp
        return age <= seconds ? source : nil
    }

    static func loadSourceHistory() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "sourceHistory") ?? []
    }
}

// Standalone functions for backwards compatibility
func loadSourceHistory() -> [String] {
    return SourceHistoryManager.loadSourceHistory()
}

func saveLastSource(_ source: String) {
    SourceHistoryManager.save(source)
}

func loadRecentSource(within seconds: TimeInterval = 3600) -> String? {
    return SourceHistoryManager.load(within: seconds)
}
