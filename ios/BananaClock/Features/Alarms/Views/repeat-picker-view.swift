//
//  RepeatPickerView.swift
//  BananaClock
//
//  Repeat day picker view
//

import SwiftUI

struct RepeatPickerView: View {
    @Binding var selectedDays: Set<Alarm.Weekday>
    // @Environment(\.dismiss) private var dismiss  // Temporarily disabled
    
    private let weekdays: [Alarm.Weekday] = [
        .sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(weekdays, id: \.self) { weekday in
                    Button {
                        if selectedDays.contains(weekday) {
                            selectedDays.remove(weekday)
                        } else {
                            selectedDays.insert(weekday)
                        }
                        HapticManager.shared.impact(.light)
                    } label: {
                        HStack {
                            Text(weekday.fullName)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            if selectedDays.contains(weekday) {
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
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // dismiss()  // Temporarily disabled
                    }
                    .foregroundColor(.bananaYellow)
                }
            }
        }
    }
}

// #Preview {
//     RepeatPickerView(selectedDays: .constant([.monday, .wednesday, .friday]))
// } 