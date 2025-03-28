//
//  SnippetListView.swift
//  HardCopy
//
//  Created by Rohan Singh on 3/27/25.
//


import SwiftUI

struct SnippetListView: View {
    @ObservedObject var manager: SnippetsManager

    var body: some View {
        NavigationView {
            List {
                ForEach(manager.snippets.sorted(by: { $0.timestamp > $1.timestamp })) { snippet in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(snippet.text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(nil)

                        Text(snippet.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let source = snippet.source {
                            Text("📚 \(source)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .onDelete { indexSet in
                    let sortedSnippets = manager.snippets.sorted(by: { $0.timestamp > $1.timestamp })
                    indexSet.map { sortedSnippets[$0] }.forEach { manager.deleteSnippet($0) }
                }
            }
            .navigationTitle("Saved Snippets")
        }
    }
}
