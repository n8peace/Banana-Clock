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
                .navigationTitle("Banana Clock")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                
                // Bottom floating action bar for selection mode
                if isEditing && !viewModel.selectableAlarms.isEmpty {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button {
                                if viewModel.selectedAlarmsCount == viewModel.selectableAlarms.count {
                                    viewModel.deselectAll()
                                } else {
                                    viewModel.selectAll()
                                }
                            } label: {
                                Text(viewModel.selectedAlarmsCount == viewModel.selectableAlarms.count ? "Deselect All" : "Select All")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(BananaTheme.Colors.backgroundSecondary)
                                    .cornerRadius(BananaTheme.Layout.cornerRadius)
                            }
                            
                            if viewModel.selectedAlarmsCount > 0 {
                                Button {
                                    Task {
                                        await viewModel.deleteSelectedAlarms()
                                    }
                                } label: {
                                    Text("Delete Selected (\(viewModel.selectedAlarmsCount))")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(BananaTheme.Colors.error)
                                        .cornerRadius(BananaTheme.Layout.cornerRadius)
                                }
                            }
                        }
                        .padding(.horizontal, BSpacing.md)
                        .padding(.bottom, BSpacing.md)
                        .background(
                            Rectangle()
                                .fill(Color.black.opacity(0.9))
                                .ignoresSafeArea()
                        )
                    }
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
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                // Clear selection when exiting edit mode
                viewModel.deselectAll()
            }
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
                .foregroundColor(.gray)
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
            // Wake Up section
            if let wakeUpAlarm = viewModel.wakeUpAlarm {
                // Section header
                HStack {
                    Text("Wake Up")
                        .font(BananaTheme.Typography.title3)
                        .foregroundColor(BananaTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, BananaTheme.Spacing.sm)
                .padding(.horizontal, BananaTheme.Spacing.md)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                
                // Wake Up alarm row
                let isEnabledBinding = Binding(
                    get: { wakeUpAlarm.isEnabled },
                    set: { newValue in
                        Task {
                            await viewModel.toggleAlarm(wakeUpAlarm, isEnabled: newValue)
                        }
                    }
                )
                
                AlarmRow(
                    alarm: wakeUpAlarm,
                    isEnabled: isEnabledBinding,
                    onTap: {
                        selectedAlarm = wakeUpAlarm
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
            
            // Other alarms section
            if !viewModel.otherAlarms.isEmpty {
                // Section header
                HStack {
                    Text("Other")
                        .font(BananaTheme.Typography.title3)
                        .foregroundColor(BananaTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, BananaTheme.Spacing.sm)
                .padding(.horizontal, BananaTheme.Spacing.md)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                
                // Other alarm rows
                ForEach(viewModel.otherAlarms) { alarm in
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
                            if isEditing {
                                // In edit mode, toggle selection instead of opening detail
                                viewModel.toggleSelection(for: alarm)
                            } else {
                                // Normal mode, open detail
                                selectedAlarm = alarm
                            }
                        },
                        isSelected: viewModel.isSelected(alarm),
                        showSelection: isEditing
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
            } else if viewModel.wakeUpAlarm != nil {
                // Empty state for Other section when only wake-up alarm exists
                VStack(spacing: BananaTheme.Spacing.lg) {
                    Image(systemName: "alarm")
                        .font(.system(size: 64))
                        .foregroundColor(BananaTheme.Colors.textTertiary)
                    
                    Text("No Other Alarms")
                        .font(.title2)
                        .foregroundColor(BananaTheme.Colors.textPrimary)
                    
                    Text("A banana a day keeps the doctor away")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    BananaButton("Add Alarm", icon: "plus") {
                        showingAddAlarm = true
                    }
                    .frame(width: 200)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
            

        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !viewModel.selectableAlarms.isEmpty {
                Button {
                    withAnimation {
                        isEditing.toggle()
                    }
                } label: {
                    if isEditing {
                        Image(systemName: "checkmark")
                            .foregroundColor(BananaTheme.Colors.bananaYellow)
                    } else {
                        Text("Edit")
                            .foregroundColor(BananaTheme.Colors.bananaYellow)
                    }
                }
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            if !isEditing {
                HStack(spacing: 16) {
                    // Test Supabase button
                    Button("Test Supabase") {
                        Task {
                            await testSupabaseConnection()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
                    
                    Button {
                        showingAddAlarm = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(BananaTheme.Colors.bananaYellow)
                    }
                }
            }
        }
    }
    
    private func testSupabaseConnection() async {
        let supabaseService = SupabaseService.shared
        
        print("🔍 Testing Supabase connection...")
        print("📱 Is configured: \(supabaseService.isConfigured)")
        print("👤 Is authenticated: \(supabaseService.isAuthenticated)")
        
        if let currentUser = supabaseService.currentUser {
            print("✅ Current user: \(currentUser.email)")
        } else {
            print("❌ No current user")
            
            // Try to sign up a test user
            do {
                let testEmail = "n8peace@gmail.com"
                let testPassword = "RemotePassw0rd123!"
                
                print("🔄 Attempting to sign up test user: \(testEmail)")
                
                let user = try await supabaseService.signUp(email: testEmail, password: testPassword)
                print("✅ Successfully signed up user: \(user.email)")
                
                // Try to sync preferences
                if let preferences = try await supabaseService.syncUserPreferences() {
                    print("✅ Successfully synced preferences: \(preferences.timezone)")
                } else {
                    print("⚠️ No preferences found (this is normal for new users)")
                }
                
            } catch {
                print("❌ Supabase test failed: \(error.localizedDescription)")
            }
        }
    }
    

}

#Preview {
    AlarmsView()
}
