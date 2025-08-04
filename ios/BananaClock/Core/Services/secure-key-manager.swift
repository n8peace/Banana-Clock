//
//  SecureKeyManager.swift
//  BananaClock
//
//  Secure API key management using iOS Keychain
//

import Foundation
import Security

enum APIService: String, CaseIterable {
    case revenueCat = "revenue_cat"
    case revenueCatSandbox = "revenue_cat_sandbox"
    case supabaseAnon = "supabase_anon"
    case supabaseService = "supabase_service"
    // openAI removed - now handled via Supabase proxy
    
    var keychainKey: String {
        return "banana_clock_api_key_\(rawValue)"
    }
    
    var displayName: String {
        switch self {
        case .revenueCat: return "RevenueCat"
        case .revenueCatSandbox: return "RevenueCat (Sandbox)"
        case .supabaseAnon: return "Supabase (Anon)"
        case .supabaseService: return "Supabase (Service)"
        }
    }
}

class SecureKeyManager: ObservableObject {
    static let shared = SecureKeyManager()
    
    @Published var isInitialized = false
    @Published var missingKeys: [APIService] = []
    
    private init() {
        checkKeyStatus()
    }
    
    // MARK: - Key Management
    
    #if DEBUG
    /// Convenience method for setting up all development keys at once
    /// Usage in Xcode debug console:
    /// SecureKeyManager.shared.setupDevelopmentKeys(
    ///     supabaseAnon: "your_supabase_anon_key",
    ///     supabaseService: "your_supabase_service_key", 
    ///     revenueCatProduction: "your_production_key",
    ///     revenueCatSandbox: "your_sandbox_key"
    /// )
    func setupDevelopmentKeys(
        supabaseAnon: String? = nil,
        supabaseService: String? = nil,
        revenueCatProduction: String? = nil,
        revenueCatSandbox: String? = nil
    ) {
        print("🔧 Setting up development API keys...")
        
        if let key = supabaseAnon {
            do {
                try storeAPIKey(key, service: .supabaseAnon)
                print("✅ Supabase anon key stored")
            } catch {
                print("❌ Failed to store Supabase anon key: \(error)")
            }
        }
        
        if let key = supabaseService {
            do {
                try storeAPIKey(key, service: .supabaseService)
                print("✅ Supabase service key stored")
            } catch {
                print("❌ Failed to store Supabase service key: \(error)")
            }
        }
        
        if let key = revenueCatProduction {
            do {
                try storeAPIKey(key, service: .revenueCat)
                print("✅ RevenueCat production key stored")
            } catch {
                print("❌ Failed to store RevenueCat production key: \(error)")
            }
        }
        
        if let key = revenueCatSandbox {
            do {
                try storeAPIKey(key, service: .revenueCatSandbox)
                print("✅ RevenueCat sandbox key stored")
            } catch {
                print("❌ Failed to store RevenueCat sandbox key: \(error)")
            }
        }
        
        print("🎉 Development key setup complete!")
        checkAllKeyStatuses()
    }
    #endif
    
    func storeAPIKey(_ key: String, service: APIService) throws {
        guard !key.isEmpty else {
            throw KeyManagerError.emptyKey
        }
        
        // Validate key format based on service
        try validateKeyFormat(key, for: service)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: service.keychainKey,
            kSecValueData as String: key.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Remove existing key first
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeyManagerError.storageFailed(status)
        }
        
        print("✅ Stored API key for \(service.displayName)")
        Task { @MainActor in
            checkKeyStatus()
        }
    }
    
    func retrieveAPIKey(service: APIService) -> String? {
        // Try keychain first
        if let keychainKey = retrieveFromKeychain(service: service) {
            return keychainKey
        }
        
        // Try environment variable fallback (development only)
        if let envKey = retrieveFromEnvironment(service: service) {
            print("🔄 Using environment variable for \(service.displayName)")
            return envKey
        }
        
        return nil
    }
    
    func removeAPIKey(service: APIService) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: service.keychainKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeyManagerError.removalFailed(status)
        }
        
        print("🗑️ Removed API key for \(service.displayName)")
        Task { @MainActor in
            checkKeyStatus()
        }
    }
    
    func hasAPIKey(service: APIService) -> Bool {
        // Check keychain first
        if retrieveFromKeychain(service: service) != nil {
            return true
        }
        
        // Check environment variables
        if retrieveFromEnvironment(service: service) != nil {
            return true
        }
        
        // Check if the app environment has fallback keys (development only)
        #if DEBUG
        switch service {
        case .supabaseAnon:
            return !AppEnvironment.supabaseAnonKey.isEmpty
        case .revenueCat, .revenueCatSandbox:
            return !AppEnvironment.revenueCatAPIKey.isEmpty
        case .supabaseService:
            return !AppEnvironment.supabaseServiceKey.isEmpty
        }
        #else
        return false
        #endif
    }
    
    // MARK: - Private Methods
    
    private func retrieveFromKeychain(service: APIService) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: service.keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    private func retrieveFromEnvironment(service: APIService) -> String? {
        let envKey: String
        switch service {
        case .revenueCat:
            envKey = "REVENUECAT_API_KEY"
        case .revenueCatSandbox:
            envKey = "REVENUECAT_SANDBOX_API_KEY"
        case .supabaseAnon:
            envKey = "SUPABASE_ANON_KEY"
        case .supabaseService:
            envKey = "SUPABASE_SERVICE_KEY"
        }
        
        return ProcessInfo.processInfo.environment[envKey]
    }
    
    private func validateKeyFormat(_ key: String, for service: APIService) throws {
        switch service {
        case .revenueCat, .revenueCatSandbox:
            guard key.hasPrefix("appl_") else {
                throw KeyManagerError.invalidKeyFormat("RevenueCat key should start with 'appl_'")
            }
        case .supabaseAnon, .supabaseService:
            guard key.hasPrefix("eyJ") else {
                throw KeyManagerError.invalidKeyFormat("Supabase key should be a JWT token")
            }
        }
    }
    
    private func checkKeyStatus() {
        Task { @MainActor in
            missingKeys = APIService.allCases.filter { !hasAPIKey(service: $0) }
            isInitialized = true
        }
    }
    
    // MARK: - Development Helpers
    
    func setupDevelopmentKeys() {
        Task { @MainActor in
            // Only for development - prompt for missing keys
            for service in missingKeys {
                print("⚠️ Missing API key for \(service.displayName)")
                print("   Please add key using: SecureKeyManager.shared.storeAPIKey(\"your_key\", service: .\(service.rawValue))")
            }
        }
    }
    
    // OpenAI key management removed - now handled via Supabase proxy
    
    /// Debug method to check all key statuses
    func checkAllKeyStatuses() {
        print("🔍 API Key Status Check:")
        for service in APIService.allCases {
            let hasKey = hasAPIKey(service: service)
            let status = hasKey ? "✅ Available" : "❌ Missing"
            print("   \(service.displayName): \(status)")
        }
    }
    
    func clearAllKeys() {
        for service in APIService.allCases {
            try? removeAPIKey(service: service)
        }
        Task { @MainActor in
            checkKeyStatus()
        }
    }
}

// MARK: - Error Types

enum KeyManagerError: LocalizedError {
    case emptyKey
    case invalidKeyFormat(String)
    case storageFailed(OSStatus)
    case removalFailed(OSStatus)
    case keyNotFound
    
    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "API key cannot be empty"
        case .invalidKeyFormat(let message):
            return "Invalid key format: \(message)"
        case .storageFailed(let status):
            return "Failed to store key in keychain: \(status)"
        case .removalFailed(let status):
            return "Failed to remove key from keychain: \(status)"
        case .keyNotFound:
            return "API key not found"
        }
    }
} 