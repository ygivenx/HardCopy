//
//  SourceEntryModal.swift
//  HardCopy
//
//  Created by Rohan Singh on 3/29/25.
//
import SwiftUI

struct SourceEntryModal: View {
    @Binding var source: String
    @Environment(\.dismiss) var dismiss
    var onSave: () -> Void

    @State private var tempSource: String = ""
    @State private var recentSources: [String] = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Source")) {
                    TextField("e.g. Sapiens by Yuval Noah Harari", text: $tempSource)
                }

                if !recentSources.isEmpty {
                    Section(header: Text("Recent Sources")) {
                        ForEach(recentSources, id: \.self) { recentSource in
                            Button(action: {
                                tempSource = recentSource
                            }) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .foregroundColor(Color(red: 37/255, green: 99/255, blue: 235/255))
                                        .imageScale(.small)
                                    Text(recentSource)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if tempSource == recentSource {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Source")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        source = tempSource
                        saveLastSource(tempSource)
                        dismiss()
                        onSave()
                    }
                    .disabled(tempSource.isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            tempSource = source
            recentSources = loadSourceHistory()
        }
    }
}
