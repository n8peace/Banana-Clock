import SwiftUI

struct AlarmsView: View {
    @StateObject private var viewModel = AlarmsViewModel()
    @State private var showingAddAlarm = false
    @State private var selectedAlarm: Alarm?
    @State private var isEditing = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page title - positioned at top of screen
                Text(viewModel.navigationTitle)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BSpacing.md)
                    .padding(.top, BSpacing.sm)
                    .padding(.bottom, BSpacing.lg)
                
                NavigationStack {
                    if viewModel.alarms.isEmpty {
                        ScrollView {
                            emptyStateView
                                .frame(maxWidth: .infinity, minHeight: 400)
                        }
                    } else {
                        alarmsList
                    }
                }
                .navigationTitle("BANANA")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
            }
        }
        .sheet(isPresented: $showingAddAlarm) {
            AlarmDetailView(alarm: nil) { newAlarm in
                Task {
                    await viewModel.addAlarm(newAlarm)
                }
            }
        }
        .sheet(item: $selectedAlarm) { alarm in
            AlarmDetailView(
                alarm: alarm,
                onSave: { updatedAlarm in
                    Task {
                        await viewModel.updateAlarm(updatedAlarm)
                    }
                },
                onDelete: { alarmToDelete in
                    Task {
                        await viewModel.deleteAlarm(alarmToDelete)
                    }
                }
            )
        }
        .task {
            await viewModel.loadAlarms()
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: BananaTheme.Spacing.lg) {
            Image(systemName: "alarm")
                .font(.system(size: 64))
                .foregroundColor(BananaTheme.Colors.textTertiary)
            
            Text("No Alarms")
                .font(.title2)
                .foregroundColor(BananaTheme.Colors.textPrimary)
            
            Text("A banana a day keeps the doctor away")
                .font(.body)
                .foregroundColor(BananaTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            BananaButton("Add Alarm", icon: "plus") {
                showingAddAlarm = true
            }
            .frame(width: 200)
        }
        .padding()
    }
    
    private var alarmsList: some View {
        List {
            ForEach(viewModel.alarms) { alarm in
                let isEnabledBinding = Binding(
                    get: { alarm.isEnabled },
                    set: { newValue in
                        Task {
                            await viewModel.toggleAlarm(alarm, isEnabled: newValue)
                        }
                    }
                )
                
                AlarmRow(
                    alarm: alarm,
                    isEnabled: isEnabledBinding,
                    onTap: {
                        selectedAlarm = alarm
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
            .onDelete { indexSet in
                Task {
                    await viewModel.deleteAlarms(at: indexSet)
                }
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !viewModel.alarms.isEmpty {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation {
                        isEditing.toggle()
                    }
                }
                .foregroundColor(BananaTheme.Colors.bananaYellow)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingAddAlarm = true
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
            }
        }
    }
}

#Preview {
    AlarmsView()
}
