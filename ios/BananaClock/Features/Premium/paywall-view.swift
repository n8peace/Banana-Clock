//
//  PaywallView.swift
//  BananaClock
//
//  Premium subscription paywall
//

import SwiftUI
import Foundation
import RevenueCat

struct PaywallView: View {
    @StateObject private var purchaseService = PurchaseService.shared
    // @Environment(\.dismiss) private var dismiss  // Temporarily disabled
    // @State private var selectedPackage: Package?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: BananaTheme.Spacing.xl) {
                        // Hero Section
                        heroSection
                        
                        // Features
                        featuresSection
                        
                        // Pricing
                        // if let offerings = purchaseService.offerings {
                        //     pricingSection(offerings)
                        // }
                        
                        // CTA Button
                        // purchaseButton
                        
                        // Restore
                        // restoreButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Banana Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // dismiss()  // Temporarily disabled
                    }
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
                }
            }
        }
        // .task {
        //     await purchaseService.loadOfferings()
        // }
        .alert("Purchase Error", isPresented: .constant(purchaseService.purchaseError != nil)) {
            Button("OK") {
                purchaseService.purchaseError = nil
            }
        } message: {
            if let error = purchaseService.purchaseError {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Sections
    
    private var heroSection: some View {
        VStack(spacing: BananaTheme.Spacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundColor(BananaTheme.Colors.bananaYellow)
            
            Text("Wake Up Better")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            Text("Personalized AI wake-up experiences tailored just for you")
                .font(.body)
                .foregroundColor(BananaTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: BananaTheme.Spacing.md) {
            FeatureRow(
                icon: "mic.fill",
                title: "AI Wake-Up Voice",
                description: "Choose from 3 unique personalities"
            )
            
            FeatureRow(
                icon: "cloud.sun.fill",
                title: "Weather-Aware Scripts",
                description: "Wake up to personalized weather updates"
            )
            
            FeatureRow(
                icon: "newspaper.fill",
                title: "Daily Briefings",
                description: "Start your day informed with news highlights"
            )
            
            FeatureRow(
                icon: "clock.fill",
                title: "AI Time Converter",
                description: "Natural language time zone conversions"
            )
            
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Features",
                description: "All premium sounds and customizations"
            )
        }
        .padding(.vertical)
    }
    
    // private func pricingSection(_ offerings: Offerings) -> some View {
    //     VStack(spacing: BananaTheme.Spacing.md) {
    //         if let monthlyPackage = offerings.current?.monthly,
    //            let yearlyPackage = offerings.current?.annual {
    //             
    //             PricingCard(
    //                 package: monthlyPackage,
    //                 isSelected: selectedPackage?.identifier == monthlyPackage.identifier,
    //                 badge: nil
    //             ) {
    //                 selectedPackage = monthlyPackage
    //             }
    //             
    //             PricingCard(
    //                 package: yearlyPackage,
    //                 isSelected: selectedPackage?.identifier == yearlyPackage.identifier,
    //                 badge: "BEST VALUE"
    //             ) {
    //                 selectedPackage = yearlyPackage
    //             }
    //         }
    //     }
    // }
    
    // private var purchaseButton: some View {
    //     BananaButton(
    //         selectedPackage != nil ? "Start Free Trial" : "Choose a Plan",
    //         icon: "sparkles"
    //     ) {
    //         if let package = selectedPackage {
    //             Task {
    //                 try await purchaseService.purchase(package: package)
    //                 // dismiss()  // Temporarily disabled
    //             }
    //         }
    //     }
    //     .disabled(selectedPackage == nil || purchaseService.isLoading)
    // }
    
    // private var restoreButton: some View {
    //     Button("Restore Purchases") {
    //         Task {
    //             try await purchaseService.restorePurchases()
    //             if purchaseService.isSubscribed {
    //                 // dismiss()  // Temporarily disabled
    //             }
    //         }
    //     }
    //     .font(.footnote)
    //     .foregroundColor(BananaTheme.Colors.textSecondary)
    // }
}

// MARK: - Feature Row
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: BananaTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(BananaTheme.Colors.bananaYellow)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(BananaTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Pricing Card
// private struct PricingCard: View {
//     let package: Package
//     let isSelected: Bool
//     let badge: String?
//     let action: () -> Void
//     
//     var body: some View {
//         Button(action: action) {
//             VStack(spacing: BananaTheme.Spacing.sm) {
//                 if let badge = badge {
//                     Text(badge)
//                         .font(.caption.bold())
//                         .foregroundColor(.black)
//                         .padding(.horizontal, 12)
//                         .padding(.vertical, 4)
//                         .background(BananaTheme.Colors.bananaYellow)
//                         .cornerRadius(12)
//                 }
//                 
//                 HStack {
//                     VStack(alignment: .leading, spacing: 4) {
//                         Text(package.storeProduct.localizedTitle)
//                             .font(.headline)
//                             .foregroundColor(.white)
//                         
//                         Text(package.storeProduct.localizedPriceString)
//                             .font(.title2.bold())
//                             .foregroundColor(isSelected ? BananaTheme.Colors.bananaYellow : .white)
//                     }
//                     
//                     Spacer()
//                     
//                     Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
//                         .font(.title2)
//                         .foregroundColor(isSelected ? BananaTheme.Colors.bananaYellow : .gray)
//                 }
//                 .padding()
//             }
//             .bananaCard()
//             .overlay(
//                 RoundedRectangle(cornerRadius: BananaTheme.Layout.largeCornerRadius)
//                     .stroke(
//                         isSelected ? BananaTheme.Colors.bananaYellow : Color.clear,
//                         lineWidth: 2
//                     )
//             )
//         }
//         .buttonStyle(PlainButtonStyle())
//     }
// }