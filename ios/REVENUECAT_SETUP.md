# RevenueCat Setup Guide

## 🚨 Fix for "Invalid API key" Error

The app is currently showing a "There was a credentials issue. Check the underlying error for more details. Invalid API key." error because the RevenueCat API key is not configured.

## 🔧 Quick Fix

1. **Get your RevenueCat API Key**:
   - Go to [RevenueCat Dashboard](https://app.revenuecat.com/)
   - Select your project (or create one if you haven't)
   - Go to **Project Settings** → **API Keys**
   - Copy your **Public API Key** (starts with `appl_`)

2. **Update the Secrets.swift file**:
   - Open `ios/BananaClock/App/Config/Secrets.swift`
   - Replace `YOUR_REVENUECAT_API_KEY_HERE` with your actual API key
   - Example:
     ```swift
     static let revenueCatAPIKey = "appl_your_actual_key_here"
     ```

3. **Clean and rebuild**:
   - In Xcode: Product → Clean Build Folder
   - Build and run the app again

## 📋 RevenueCat Project Setup (if needed)

If you don't have a RevenueCat project set up yet:

1. **Create a RevenueCat account** at [revenuecat.com](https://www.revenuecat.com/)

2. **Create a new project**:
   - Click "New Project"
   - Name it "Banana Clock"
   - Select iOS platform

3. **Configure App Store Connect**:
   - Go to **App Store Connect** → **My Apps**
   - Create a new app if needed
   - Go to **Features** → **In-App Purchases**
   - Create these products:
     - Product ID: `banana_plus_monthly`
     - Product ID: `banana_plus_yearly`

4. **Link to RevenueCat**:
   - In RevenueCat, go to **Project Settings** → **App Store Connect**
   - Follow the linking process

5. **Create Entitlements**:
   - In RevenueCat, go to **Entitlements**
   - Create entitlement: `banana_plus`
   - Add both products to this entitlement

## 🔍 Troubleshooting

- **"Invalid API key"**: Make sure you're using the Public API key, not the Secret key
- **"Project not found"**: Verify your project is active in RevenueCat
- **"Products not found"**: Ensure your App Store Connect products are properly linked

## 📱 Test the Fix

After updating the API key:
1. Clean build folder in Xcode
2. Build and run the app
3. The app should now start without the credentials error
4. You should see the paywall (since you're not subscribed yet)

## 🔐 Security Note

The `Secrets.swift` file is already added to `.gitignore` to prevent accidentally committing your API keys to version control. 