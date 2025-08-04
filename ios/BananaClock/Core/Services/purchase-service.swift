//
//  PurchaseService.swift
//  BananaClock
//
//  RevenueCat subscription management
//

import Foundation
import RevenueCat
import SwiftUI

@MainActor
class PurchaseService: NSObject, ObservableObject {
    static let shared = PurchaseService()
    
    @Published var isSubscribed = false
    @Published var isLoading = false
    @Published var purchaseError: Error?
    @Published var offerings: Offerings?
    
    private let userDefaults = UserDefaults.standard
    private let subscriptionStatusKey = "subscription_status"
    private let lastCheckKey = "last_subscription_check"
    
    private override init() {
        super.init()
        loadCachedSubscriptionStatus()
    }
    
    // MARK: - Configuration
    
    func configure() {
        let apiKey = AppEnvironment.revenueCatAPIKey
        guard !apiKey.isEmpty else {
            print("❌ RevenueCat API Key not found in secure storage or environment")
            print("📱 App will run in demo mode without subscription features")
            return
        }
        
        #if DEBUG
        if AppEnvironment.useRevenueCatSandbox {
            print("🧪 RevenueCat SANDBOX Mode Enabled")
            print("🔑 Using sandbox API key: \(String(apiKey.prefix(10)))...")
        } else {
            print("🚀 RevenueCat PRODUCTION Mode in Debug Build")
            print("🔑 Using production API key: \(String(apiKey.prefix(10)))...")
        }
        #else
        print("🚀 RevenueCat PRODUCTION Mode")
        print("🔑 Using API key: \(String(apiKey.prefix(10)))...")
        #endif
        
        // Validate API key format
        if apiKey.isEmpty {
            print("❌ RevenueCat API Key is empty!")
            return
        } else if !apiKey.hasPrefix("appl_") {
            print("❌ RevenueCat API Key format is invalid (should start with 'appl_')")
            return
        } else {
            print("✅ RevenueCat API Key format looks correct")
        }
        
        // Configure with sandbox mode support
        let builder = Configuration.Builder(withAPIKey: apiKey)
            .with(storeKitVersion: .storeKit2)
        
        #if DEBUG
        if AppEnvironment.useRevenueCatSandbox {
            // Enable sandbox testing features
            builder.with(usesStoreKit2IfAvailable: true)
            print("✅ RevenueCat configured for SANDBOX testing")
        }
        #endif
        
        Purchases.configure(with: builder.build())
        
        // Set up purchase listener
        Purchases.shared.delegate = self
        
        // Check cached status on startup
        loadCachedSubscriptionStatus()
        
        // Refresh status
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    // MARK: - Subscription Status
    
    func checkSubscriptionStatus() async {
        isLoading = true
        print("🔍 Checking subscription status...")
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let hasActiveSubscription = !customerInfo.entitlements.active.isEmpty
            print("✅ Subscription check successful. Active subscription: \(hasActiveSubscription)")
            
            await MainActor.run {
                self.isSubscribed = hasActiveSubscription
                self.cacheSubscriptionStatus(hasActiveSubscription)
                self.isLoading = false
            }
        } catch {
            print("❌ Subscription check failed with error: \(error)")
            print("🔍 Error type: \(type(of: error))")
            print("🔍 Error description: \(error.localizedDescription)")
            
            await MainActor.run {
                self.purchaseError = error
                self.isLoading = false
                // On error, assume not subscribed and show paywall
                self.isSubscribed = false
            }
        }
    }
    
    func hasActiveSubscription() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            return !customerInfo.entitlements.active.isEmpty
        } catch {
            return false
        }
    }
    
    // MARK: - Caching
    
    private func loadCachedSubscriptionStatus() {
        isSubscribed = userDefaults.bool(forKey: subscriptionStatusKey)
    }
    
    private func cacheSubscriptionStatus(_ status: Bool) {
        userDefaults.set(status, forKey: subscriptionStatusKey)
        userDefaults.set(Date(), forKey: lastCheckKey)
    }
    
    func shouldRefreshSubscriptionStatus() -> Bool {
        guard let lastCheck = userDefaults.object(forKey: lastCheckKey) as? Date else {
            return true
        }
        
        // Refresh every 24 hours
        return Date().timeIntervalSince(lastCheck) > 24 * 60 * 60
    }
    
    // MARK: - Offerings
    
    func loadOfferings() async {
        isLoading = true
        
        do {
            let offerings = try await Purchases.shared.offerings()
            await MainActor.run {
                self.offerings = offerings
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.purchaseError = error
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Purchase
    
    func purchase(package: Package) async throws {
        isLoading = true
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            let hasActiveSubscription = !result.customerInfo.entitlements.active.isEmpty
            
            await MainActor.run {
                self.isSubscribed = hasActiveSubscription
                self.cacheSubscriptionStatus(hasActiveSubscription)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.purchaseError = error
                self.isLoading = false
            }
            throw error
        }
    }
    
    func restorePurchases() async throws {
        isLoading = true
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            let hasActiveSubscription = !customerInfo.entitlements.active.isEmpty
            
            await MainActor.run {
                self.isSubscribed = hasActiveSubscription
                self.cacheSubscriptionStatus(hasActiveSubscription)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.purchaseError = error
                self.isLoading = false
            }
            throw error
        }
    }
    
    // MARK: - Development Bypass
    
    #if DEBUG
    func bypassPaywallForTesting() {
        isSubscribed = true
        cacheSubscriptionStatus(true)
    }
    
    func clearDebugSubscription() async {
        print("🧪 Clearing debug subscription state...")
        
        // Clear subscription cache
        userDefaults.removeObject(forKey: subscriptionStatusKey)
        userDefaults.removeObject(forKey: lastCheckKey)
        
        // Reset subscription state
        isSubscribed = false
        
        // Force RevenueCat to refresh from sandbox/current environment
        do {
            let _ = try await Purchases.shared.syncPurchases()
            print("✅ RevenueCat sync completed")
        } catch {
            print("⚠️ RevenueCat sync failed: \(error.localizedDescription)")
        }
        
        print("✅ Debug subscription state cleared")
    }
    #endif
}

// MARK: - RevenueCat Delegate

extension PurchaseService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        let hasActiveSubscription = !customerInfo.entitlements.active.isEmpty
        
        self.isSubscribed = hasActiveSubscription
        self.cacheSubscriptionStatus(hasActiveSubscription)
    }
}

// MARK: - Paywall View
// Note: PaywallView is defined in Features/Premium/paywall-view.swift