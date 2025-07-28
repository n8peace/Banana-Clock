//
//  HeadlinesPickerView.swift
//  BananaClock
//
//  Headlines categories picker view for AI wake-up
//

import SwiftUI

struct HeadlinesPickerView: View {
    @Binding var selectedCategories: Set<HeadlinesCategory>
    @Environment(\.dismiss) private var dismiss
    
    private let categories: [HeadlinesCategory] = [
        .politics, .business, .technology, .health, .sports, .entertainment, .science, .world
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(categories, id: \.self) { category in
                    Button {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                        HapticManager.shared.impact(.light)
                    } label: {
                        HStack {
                            Text(category.displayName)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.bananaYellow)
                            }
                        }
                    }
                    .listRowBackground(Color.backgroundSecondary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .navigationTitle("News Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.bananaYellow)
                }
            }
        }
    }
}

// #Preview {
//     HeadlinesPickerView(selectedCategories: .constant([.business, .technology]))
// } 