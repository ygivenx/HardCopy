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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Source")) {
                    TextField("e.g. Sapiens by Yuval Noah Harari", text: $tempSource)
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
        }
    }
}
