//
//  PurchaseService.swift
//  BananaClock
//
//  RevenueCat subscription management
//

import Foundation
// import RevenueCat  // Temporarily disabled
import SwiftUI

@MainActor
class PurchaseService: ObservableObject {
    static let shared = PurchaseService()
    
    @Published var isSubscribed = false
    // @Published var offerings: Offerings?  // Temporarily disabled
    @Published var isLoading = false
    @Published var purchaseError: Error?
    
    private init() {}
    
    // MARK: - Configuration
    
    func configure() {
        // Temporarily disabled until RevenueCat is properly configured
        print("⚠️ RevenueCat temporarily disabled")
    }
    
    // MARK: - Subscription Status
    
    func checkSubscriptionStatus() async {
        // Temporarily disabled
        isSubscribed = false
    }
    
    func hasActiveSubscription() async -> Bool {
        // Temporarily disabled
        return false
    }
    
    // MARK: - Offerings
    
    func loadOfferings() async {
        // Temporarily disabled
        isLoading = false
    }
    
    // MARK: - Purchase
    
    func purchase(package: Any) async throws {
        // Temporarily disabled
        throw NSError(domain: "PurchaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Purchases temporarily disabled"])
    }
    
    func restorePurchases() async throws {
        // Temporarily disabled
        throw NSError(domain: "PurchaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Purchases temporarily disabled"])
    }
}

// MARK: - Paywall View
// Note: PaywallView is defined in Features/Premium/paywall-view.swift