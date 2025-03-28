//
//  SnippetsManager.swift
//  HardCopy
//
//  Created by Rohan Singh on 3/27/25.
//


import Foundation

class SnippetsManager: ObservableObject {
    @Published private(set) var snippets: [Snippet] = []

    private let fileName = "snippets.json"

    init() {
        loadSnippets()
    }

    func addSnippet(_ snippet: Snippet) {
        snippets.append(snippet)
        saveSnippets()
    }
    
    func deleteSnippet(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        saveSnippets()
    }

    private func getFileURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(fileName)
    }

    private func saveSnippets() {
        do {
            let data = try JSONEncoder().encode(snippets)
            try data.write(to: getFileURL())
        } catch {
            print("❌ Failed to save snippets: \(error)")
        }
    }

    private func loadSnippets() {
        let url = getFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let data = try Data(contentsOf: url)
            snippets = try JSONDecoder().decode([Snippet].self, from: data)
        } catch {
            print("❌ Failed to load snippets: \(error)")
        }
    }
}
