# 🚀 Banana Clock iOS Setup Instructions

## Step 1: Navigate to your repo
```bash
cd ~/path/to/Banana-Clock
git checkout develop
git pull origin develop
```

## Step 2: Create iOS directory structure
```bash
mkdir -p ios/BananaClock/App/Config
mkdir -p ios/BananaClock/Core/{Models,Services,Extensions,Utilities}
mkdir -p ios/BananaClock/Features/{TabView,Alarms/{Views,ViewModels},WorldClock/{Views,ViewModels},Stopwatch/{Views,ViewModels},Timers/{Views,ViewModels},Premium}
mkdir -p ios/BananaClock/Design/{Components,Theme}
mkdir -p ios/BananaClock/Resources/Assets.xcassets/{AppIcon.appiconset,AccentColor.colorset,Colors}
mkdir -p ios/BananaClock/Resources/Sounds
mkdir -p ios/BananaClockTests
mkdir -p ios/BananaClockUITests
```

## Step 3: Create Xcode project
1. Open Xcode
2. File → New → Project
3. Choose iOS → App
4. Configure:
   - Product Name: `BananaClock`
   - Team: Your Apple Developer account
   - Organization Identifier: `bananaintelligence.ai`
   - Bundle Identifier: `bananaintelligence.ai.bananaclock`
   - Interface: SwiftUI
   - Language: Swift
   - Use Core Data: NO
   - Include Tests: YES
5. Save to: `Banana-Clock/ios/`

## Step 4: Add all Swift files
Copy each artifact file to its corresponding location in the project.

## Step 5: Configure Xcode project
1. **Add Swift Package Dependencies**:
   - File → Add Package Dependencies
   - Add `https://github.com/supabase/supabase-swift.git`
   - Add `https://github.com/RevenueCat/purchases-ios.git`

2. **Update Build Settings**:
   - iOS Deployment Target: 26.0
   - Swift Language Version: 5.9

3. **Add Capabilities**:
   - Background Modes (Audio, Fetch, Remote notifications)
   - Push Notifications (if using)

4. **Create Secrets.swift**:
   ```swift
   // BananaClock/App/Config/Secrets.swift
   struct Secrets {
       static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
       static let revenueCatAPIKey = "YOUR_REVENUECAT_KEY"
   }
   ```

5. **Update Info.plist**:
   - Replace the default Info.plist with the provided one
   - Update any placeholder values

## Step 6: Configure schemes
1. Edit Scheme → Run → Arguments → Environment Variables
2. Add for Debug scheme:
   - `SUPABASE_URL`: Your dev Supabase URL
   - `SUPABASE_ANON_KEY`: Your dev anon key
3. Add for Release scheme:
   - `SUPABASE_URL`: Your prod Supabase URL
   - `SUPABASE_ANON_KEY`: Your prod anon key

## Step 7: Test the build
```bash
cd ios
xcodebuild -scheme BananaClock -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

## Step 8: Commit to GitHub
```bash
git add ios/
git commit -m "feat: Add iOS app implementation"
git push origin develop
```

## Step 9: Run the app
1. Open `ios/BananaClock.xcodeproj` in Xcode
2. Select iPhone 15 Pro simulator
3. Press Cmd+R to build and run

## 🎉 You're all set!

### Next Steps:
- Test all features thoroughly
- Configure RevenueCat dashboard
- Set up TestFlight for beta testing
- Prepare App Store assets

### Important Notes:
- AlarmKit features require iOS 26+ and physical device
- AI wake-up features require Banana Plus subscription
- Ensure Supabase Edge Functions are deployed