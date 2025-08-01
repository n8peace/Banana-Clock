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
    case supabaseAnon = "supabase_anon"
    case supabaseService = "supabase_service"
    // openAI removed - now handled via Supabase proxy
    
    var keychainKey: String {
        return "banana_clock_api_key_\(rawValue)"
    }
    
    var displayName: String {
        switch self {
        case .revenueCat: return "RevenueCat"
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
        return retrieveAPIKey(service: service) != nil
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
        case .supabaseAnon:
            envKey = "SUPABASE_ANON_KEY"
        case .supabaseService:
            envKey = "SUPABASE_SERVICE_KEY"
        }
        
        return ProcessInfo.processInfo.environment[envKey]
    }
    
    private func validateKeyFormat(_ key: String, for service: APIService) throws {
        switch service {
        case .revenueCat:
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