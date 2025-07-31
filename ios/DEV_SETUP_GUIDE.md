# OpenAI API Key Setup Guide (Development)

## Quick Setup (3 Ways)

### Option 1: Programmatic Setup (Fastest)
Add this code temporarily in any view's `.onAppear` or in `BananaClockApp.swift`:

```swift
SecureKeyManager.shared.storeOpenAIKey("sk-your-actual-key-here")
```

Run the app once, then remove the code. The key is now stored securely in the iOS Keychain.

### Option 2: In-App UI Setup
1. Run the app in debug mode
2. Add this to your Settings view or any debug menu:

```swift
DevelopmentMenuItem()  // This will show "Development Setup" link
```

3. Tap "Development Setup" and enter your key

### Option 3: Command Line (During Development)
In your app delegate or any initialization code:

```swift
// Check if key exists
if !SecureKeyManager.shared.hasAPIKey(service: .openAI) {
    // You'll see this in console:
    // ⚠️  OpenAI API Key Not Found!
    // 📝 To set up your OpenAI key:
    //    1. Get your key from: https://platform.openai.com/api-keys
    //    2. Or programmatically: SecureKeyManager.shared.storeOpenAIKey("sk-...")
}
```

## Verify Setup

Run this anywhere in your app to check status:

```swift
SecureKeyManager.shared.checkAllKeyStatuses()
```

You'll see:
```
🔍 API Key Status Check:
   RevenueCat: ❌ Missing
   Supabase (Anon): ❌ Missing
   Supabase (Service): ❌ Missing
   OpenAI: ✅ Available    <-- This should be green
```

## Where to Get Your OpenAI Key

1. Go to https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Copy the key (starts with `sk-`)
4. Use one of the methods above to store it

## Security Notes

- The key is stored in iOS Keychain (encrypted)
- Never commit the key to source control
- The `DevelopmentSetup.swift` file is only compiled in DEBUG builds
- Keys are device-specific and don't sync to iCloud

## Usage in Your Code

Once set up, the key is automatically available:

```swift
let openAIKey = AppEnvironment.openAIAPIKey
// This will retrieve from Keychain or fall back to environment variable
```

## Removing a Key

```swift
try? SecureKeyManager.shared.removeAPIKey(service: .openAI)
```