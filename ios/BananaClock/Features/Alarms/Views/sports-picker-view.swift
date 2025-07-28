//
//  SportsPickerView.swift
//  BananaClock
//
//  Sports categories picker view for AI wake-up
//

import SwiftUI

struct SportsPickerView: View {
    @Binding var selectedCategories: Set<SportsCategory>
    @Environment(\.dismiss) private var dismiss
    
    private let categories: [SportsCategory] = [
        .football, .basketball, .baseball, .hockey, .soccer, .tennis, .golf
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
            .navigationTitle("Sports Categories")
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
//     SportsPickerView(selectedCategories: .constant([.football, .basketball]))
// } 