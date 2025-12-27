//
//  SourceHistoryManager.swift
//  HardCopy
//
//  Created by Rohan Singh on 3/29/25.
//

import Foundation

enum SourceHistoryManager {
    static func save(_ source: String) {
        let entry: [String: Any] = ["source": source, "timestamp": Date().timeIntervalSince1970]
        UserDefaults.standard.set(entry, forKey: "lastSnippetSource")
    }

    static func load(within seconds: TimeInterval = 3600) -> String? {
        guard let entry = UserDefaults.standard.dictionary(forKey: "lastSnippetSource"),
              let source = entry["source"] as? String,
              let timestamp = entry["timestamp"] as? TimeInterval else { return nil }

        let age = Date().timeIntervalSince1970 - timestamp
        return age <= seconds ? source : nil
    }
}
