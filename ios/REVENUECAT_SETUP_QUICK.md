# RevenueCat Quick Setup Guide

## Current Status
✅ **Hard paywall implemented** - App requires subscription for access  
✅ **Development bypass enabled** - Set to `true` in environment-config.swift  
✅ **PaywallView integrated** - Complete UI with pricing and features  

## Next Steps

### 1. Get RevenueCat API Key (5 minutes)
1. Go to https://app.revenuecat.com
2. Create account / sign in
3. Create new project "Banana Clock"
4. Go to Project Settings → General → API Keys
5. Copy the **Public App-specific API key** (starts with `appl_`)

### 2. Add API Key to App (2 minutes)
Add this line temporarily to your app launch (then remove):

```swift
// In banana-clock-app.swift, add to configureApp()
SecureKeyManager.shared.storeAPIKey("appl_your_key_here", service: .revenueCat)
```

### 3. Test the Setup (3 minutes)

**Test Development Bypass:**
1. Ensure `bypassPaywallInDevelopment = true` in environment-config.swift
2. Run app → Should go straight to MainTabView (bypass paywall)

**Test Hard Paywall:**
1. Set `bypassPaywallInDevelopment = false` in environment-config.swift  
2. Run app → Should show PaywallView (paywall enforced)
3. Tap "Debug: Skip" button → Should enter MainTabView

### 4. Production Setup (Later)
- Configure App Store Connect with subscription products
- Set up RevenueCat entitlements
- Test with TestFlight/sandbox purchases
- Deploy with `bypassPaywallInDevelopment = false`

## Current Behavior

**Development (bypassPaywallInDevelopment = true):**
- ✅ App opens directly to MainTabView 
- ✅ Full access to all features
- ✅ No paywall shown

**Testing Paywall (bypassPaywallInDevelopment = false):**
- ✅ App opens to PaywallView
- ✅ No access to MainTabView without subscription
- ✅ Debug "Skip" button available for testing

**Production (when ready):**
- ✅ Hard paywall enforced
- ✅ Only subscribers/trial users get app access
- ✅ Expired subscriptions return to paywall

## Files Modified
- ✅ `banana-clock-app.swift` - Hard paywall logic
- ✅ `environment-config.swift` - Development bypass flag  
- ✅ `DevelopmentSetup.swift` - RevenueCat status display
- ✅ `purchase-service.swift` - Already complete with RevenueCat integration
- ✅ `paywall-view.swift` - Already complete with subscription UI

## Ready for Production
The hard paywall system is **production-ready**. Just need to:
1. Add RevenueCat API key
2. Set `bypassPaywallInDevelopment = false` for production builds
3. Configure App Store Connect subscriptions

**Total setup time: ~10 minutes** 🚀