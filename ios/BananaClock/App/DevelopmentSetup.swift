//
//  DevelopmentSetup.swift
//  BananaClock
//
//  Development-only setup helpers for API keys
//  This file should only be used in DEBUG builds
//

#if DEBUG
import Foundation
import SwiftUI

struct DevelopmentSetupView: View {
    @State private var openAIKey = ""
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var isValidating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Development Setup")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Enter your OpenAI API key for development")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("OpenAI API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SecureField("sk-...", text: $openAIKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                Button(action: saveKey) {
                    if isValidating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Save API Key")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(openAIKey.isEmpty || isValidating)
                
                if showSuccess {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("API Key Saved Successfully!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("You can now use OpenAI features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                VStack(spacing: 10) {
                    Text("Current Status")
                        .font(.headline)
                    
                    HStack {
                        Text("OpenAI Key:")
                        Text(SecureKeyManager.shared.hasAPIKey(service: .openAI) ? "✅ Configured" : "❌ Not Set")
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveKey() {
        errorMessage = ""
        isValidating = true
        
        // Basic validation
        guard openAIKey.hasPrefix("sk-") else {
            errorMessage = "Invalid key format. OpenAI keys start with 'sk-'"
            isValidating = false
            return
        }
        
        // Save to keychain
        do {
            try SecureKeyManager.shared.storeAPIKey(openAIKey, service: .openAI)
            showSuccess = true
            openAIKey = "" // Clear the field
            
            // Hide success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showSuccess = false
            }
        } catch {
            errorMessage = "Failed to save key: \(error.localizedDescription)"
        }
        
        isValidating = false
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
        
        // If OpenAI key is missing, provide instructions
        if !manager.hasAPIKey(service: .openAI) {
            print("\n⚠️  OpenAI API Key Not Found!")
            print("📝 To set up your OpenAI key:")
            print("   1. Get your key from: https://platform.openai.com/api-keys")
            print("   2. In the app, go to Settings > Development Setup")
            print("   3. Or programmatically: SecureKeyManager.shared.storeOpenAIKey(\"sk-...\")")
        }
        
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