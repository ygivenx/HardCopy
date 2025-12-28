//
//  SourceHistoryManager.swift
//  HardCopy
//
//  Created by Rohan Singh on 3/29/25.
//

import Foundation

func saveLastSource(_ source: String) {
    guard !source.isEmpty else { return }

    // Load existing history
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

    // Also update last source with timestamp for 1-hour auto-fill
    let entry = ["source": source, "timestamp": Date().timeIntervalSince1970] as [String : Any]
    UserDefaults.standard.set(entry, forKey: "lastSnippetSource")
}

func loadRecentSource(within seconds: TimeInterval = 3600) -> String? {
    guard let entry = UserDefaults.standard.dictionary(forKey: "lastSnippetSource"),
          let source = entry["source"] as? String,
          let timestamp = entry["timestamp"] as? TimeInterval else { return nil }

    let age = Date().timeIntervalSince1970 - timestamp
    return age <= seconds ? source : nil
}

func loadSourceHistory() -> [String] {
    return UserDefaults.standard.stringArray(forKey: "sourceHistory") ?? []
}
