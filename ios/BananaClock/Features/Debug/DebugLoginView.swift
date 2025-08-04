//
//  DebugLoginView.swift
//  BananaClock
//
//  Debug-only login view for testing authentication flow
//

#if DEBUG
import SwiftUI

struct DebugLoginView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var email = "test@bananaclock.dev"
    @State private var password = "TestPassword123!"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateAccount = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: BananaTheme.Spacing.xl) {
                        // Debug Header
                        debugHeader
                        
                        // Login Form
                        loginForm
                        
                        // Action Buttons
                        actionButtons
                        
                        // Debug Info
                        debugInfo
                    }
                    .padding()
                }
            }
            .navigationTitle("Debug Login")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
        }
        .alert("Login Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Components
    
    private var debugHeader: some View {
        VStack(spacing: BananaTheme.Spacing.md) {
            Image(systemName: "ladybug")
                .font(.system(size: 64))
                .foregroundColor(BananaTheme.Colors.bananaYellow)
            
            Text("Debug Environment")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            Text("Login required on every debug launch")
                .font(.subheadline)
                .foregroundColor(BananaTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    private var loginForm: some View {
        VStack(spacing: BananaTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Enter email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.headline)
                    .foregroundColor(.white)
                
                SecureField("Enter password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .bananaCard()
    }
    
    private var actionButtons: some View {
        VStack(spacing: BananaTheme.Spacing.md) {
            BananaButton(
                "Login for Testing",
                icon: "lock.open"
            ) {
                Task {
                    await performLogin()
                }
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            
            Button(showCreateAccount ? "Back to Login" : "Create Test Account") {
                showCreateAccount.toggle()
                if showCreateAccount {
                    // Pre-fill with new test account data
                    email = "test\(Int.random(in: 1000...9999))@bananaclock.dev"
                    password = "TestPassword123!"
                }
            }
            .font(.subheadline)
            .foregroundColor(BananaTheme.Colors.bananaYellow)
        }
    }
    
    private var debugInfo: some View {
        VStack(spacing: BananaTheme.Spacing.sm) {
            Text("Debug Environment Info")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                debugInfoRow("Environment", AppEnvironment.isDebugEnvironment ? "Debug" : "Production")
                debugInfoRow("Supabase URL", AppEnvironment.supabaseURL)
                debugInfoRow("Force Login", AppEnvironment.forceLoginOnLaunch ? "Enabled" : "Disabled")
                debugInfoRow("Force Subscription", AppEnvironment.forceSubscriptionFlow ? "Enabled" : "Disabled")
                debugInfoRow("RevenueCat Sandbox", AppEnvironment.useRevenueCatSandbox ? "Enabled" : "Disabled")
            }
        }
        .bananaCard()
    }
    
    private func debugInfoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(BananaTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Actions
    
    private func performLogin() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if showCreateAccount {
                let _ = try await supabaseService.signUp(email: email, password: password)
                print("✅ Debug account created and signed in")
            } else {
                let _ = try await supabaseService.signIn(email: email, password: password)
                print("✅ Debug login successful")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Debug login failed: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    DebugLoginView()
}
#endif