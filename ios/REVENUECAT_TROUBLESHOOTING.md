# RevenueCat Troubleshooting Guide

## 🚨 "Invalid API Key" Error - Step by Step Fix

### Step 1: Verify API Key in RevenueCat Dashboard

1. **Go to RevenueCat Dashboard**: https://app.revenuecat.com/
2. **Select your project** (or create one if you haven't)
3. **Go to Project Settings** → **API Keys**
4. **Copy the Public API Key** (should start with `appl_`)

### Step 2: Check Project Status

Make sure your RevenueCat project is:
- ✅ **Active** (not suspended)
- ✅ **Has the correct platform** (iOS)
- ✅ **Linked to App Store Connect** (if you have products)

### Step 3: Verify App Bundle Identifier

The bundle identifier in your Xcode project must match what's configured in RevenueCat:

1. **In Xcode**: Check your bundle identifier in project settings
2. **In RevenueCat**: Go to Project Settings → App Configuration
3. **Ensure they match**: Should be `bananaclock.bananaintelligence.ai`

### Step 4: Test with Debug Logging

I've added debug logging to help identify the issue. Run the app and check the Xcode console for:

```
🔑 RevenueCat API Key: appl_YGEFzvwuYvHFfzXQAJlQsdzMjyW
✅ RevenueCat API Key format looks correct
🔍 Checking subscription status...
❌ Subscription check failed with error: [error details]
```

### Step 5: Common Issues and Solutions

#### Issue: "Invalid API Key" with correct format
**Possible causes:**
- API key is from a different project
- Project is suspended or inactive
- Bundle identifier mismatch

**Solution:**
1. Create a new RevenueCat project
2. Use the new project's API key
3. Ensure bundle identifier matches

#### Issue: "Project not found"
**Solution:**
1. Verify you're using the correct API key
2. Check if the project is active in RevenueCat dashboard
3. Try creating a new project

#### Issue: "Products not found"
**Solution:**
1. This is normal if you haven't set up products yet
2. The app should still work and show the paywall
3. Products are only needed for actual purchases

### Step 6: Create a Test Project

If the issue persists, let's create a fresh RevenueCat project:

1. **Go to RevenueCat**: https://app.revenuecat.com/
2. **Click "New Project"**
3. **Name**: "Banana Clock Test"
4. **Platform**: iOS
5. **Copy the new API key**
6. **Update Secrets.swift** with the new key

### Step 7: Minimal Configuration Test

For testing, you can temporarily disable the subscription check:

```swift
// In purchase-service.swift, comment out the subscription check:
func configure() {
    // ... configuration code ...
    
    // Comment out this line temporarily:
    // Task {
    //     await checkSubscriptionStatus()
    // }
}
```

This will let the app start and show the main interface without checking subscription status.

### Step 8: Verify Network Connectivity

Make sure your device/simulator can reach RevenueCat:
- Check internet connection
- Try on a different network
- Test with a VPN disabled

### Step 9: Check RevenueCat SDK Version

Ensure you're using a compatible RevenueCat SDK version:

```swift
// In your Package.swift or SPM dependencies
// Should be using a recent version like 4.x or 5.x
```

### Step 10: Contact RevenueCat Support

If none of the above works:
1. Go to RevenueCat dashboard
2. Click "Support" or "Help"
3. Provide your project ID and error details

## 🔍 Debug Information

When you run the app, look for these debug messages in Xcode console:

- `🔑 RevenueCat API Key: [key]` - Shows the key being used
- `✅ RevenueCat API Key format looks correct` - Key format is valid
- `🔍 Checking subscription status...` - Starting subscription check
- `❌ Subscription check failed with error: [error]` - Detailed error info

## 📱 Expected Behavior

After fixing the API key issue:
1. App should start without credentials error
2. Should show paywall (since you're not subscribed)
3. Should be able to navigate through the app
4. Subscription features should be locked behind paywall

## 🔐 Security Reminder

- Never commit your actual API keys to version control
- The `Secrets.swift` file is in `.gitignore`
- Use different API keys for development and production 