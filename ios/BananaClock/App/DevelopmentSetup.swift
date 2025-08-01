//
//  DevelopmentSetup.swift
//  BananaClock
//
//  Development-only setup helpers for API keys and authentication
//  This file should only be used in DEBUG builds
//

#if DEBUG
import Foundation
import SwiftUI

struct DevelopmentSetupView: View {
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var isCheckingAuth = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Development Setup")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("AI features now use Supabase proxy")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("✨ What's New")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("OpenAI features are now proxied through Supabase Edge Functions. No local API keys needed!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("🔐 Authentication Required")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("AI features require user authentication through Supabase. Sign in to access AI-powered timezone recommendations.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("🛠️ Development Notes")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("All AI requests go through the 'openai-proxy' Edge Function. Check Supabase logs for debugging.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: checkAuthStatus) {
                    if isCheckingAuth {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Check Authentication Status")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCheckingAuth)
                
                if showSuccess {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Authentication Active!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("AI features are ready to use")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                VStack(spacing: 10) {
                    Text("Service Status")
                        .font(.headline)
                    
                    VStack(spacing: 5) {
                        HStack {
                            Text("Supabase Service:")
                            Text(SecureKeyManager.shared.hasAPIKey(service: .supabaseService) ? "✅ Configured" : "❌ Not Set")
                        }
                        .font(.caption)
                        
                        HStack {
                            Text("Supabase Anon:")
                            Text(SecureKeyManager.shared.hasAPIKey(service: .supabaseAnon) ? "✅ Configured" : "❌ Not Set")
                        }
                        .font(.caption)
                        
                        HStack {
                            Text("RevenueCat:")
                            Text(SecureKeyManager.shared.hasAPIKey(service: .revenueCat) ? "✅ Configured" : "❌ Not Set")
                        }
                        .font(.caption)
                        
                        HStack {
                            Text("Paywall Bypass:")
                            Text(AppEnvironment.bypassPaywallInDevelopment ? "✅ Enabled" : "❌ Disabled")
                        }
                        .font(.caption)
                    }
                }
                
                VStack(spacing: 10) {
                    Text("💰 RevenueCat Testing")
                        .font(.headline)
                    
                    Text("Toggle paywall bypass in environment-config.swift")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Set bypassPaywallInDevelopment = false to test paywall")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func checkAuthStatus() {
        errorMessage = ""
        isCheckingAuth = true
        
        Task {
            do {
                // Check if user is authenticated with Supabase
                let session = try await SupabaseService.shared.getCurrentSession()
                
                await MainActor.run {
                    if session != nil {
                        showSuccess = true
                        errorMessage = ""
                        
                        // Hide success message after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showSuccess = false
                        }
                    } else {
                        errorMessage = "No active authentication session. Please sign in to use AI features."
                        showSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to check authentication: \(error.localizedDescription)"
                    showSuccess = false
                }
            }
            
            await MainActor.run {
                isCheckingAuth = false
            }
        }
    }
}

// MARK: - Quick Setup Extension for AppDelegate/SceneDelegate
extension SecureKeyManager {
    /// Call this in your app launch for development builds
    static func setupDevelopmentEnvironment() {
        #if DEBUG
        let manager = SecureKeyManager.shared
        
        print("🔧 Development Environment Setup")
        print("================================")
        
        // Check current status
        manager.checkAllKeyStatuses()
        
        // Check for required Supabase keys
        if !manager.hasAPIKey(service: .supabaseAnon) || !manager.hasAPIKey(service: .supabaseService) {
            print("\n⚠️  Supabase Keys Missing!")
            print("📝 To set up Supabase:")
            print("   1. Configure keys in environment-config.swift")
            print("   2. Or add to your .env file")
            print("   3. Supabase keys are required for AI features")
        }
        
        print("\n✨ OpenAI Integration:")
        print("   • Now uses Supabase proxy (no local keys needed)")
        print("   • Requires user authentication")
        print("   • Check 'openai-proxy' Edge Function in Supabase")
        
        print("================================\n")
        #endif
    }
}

// MARK: - Development Menu Item
struct DevelopmentMenuItem: View {
    var body: some View {
        #if DEBUG
        NavigationLink(destination: DevelopmentSetupView()) {
            Label("Development Setup", systemImage: "wrench.and.screwdriver")
        }
        #else
        EmptyView()
        #endif
    }
}
#endif