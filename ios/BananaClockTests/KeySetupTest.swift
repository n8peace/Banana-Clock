import XCTest
@testable import BananaClock

class KeySetupTest: XCTestCase {
    func testSetupKeys() {
        print("🔧 Starting key setup...")
        
        SecureKeyManager.shared.setupDevelopmentKeys(
            supabaseAnon: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwcWlhcm5raHphYmdneGlsdGNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1MzA0OTMsImV4cCI6MjA2ODEwNjQ5M30.JB36Fx6KSXWMKiiX8MmCx8pEpBn5sKKt3xVQCdxqssY",
            supabaseService: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwcWlhcm5raHphYmdneGlsdGNpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjUzMDQ5MywiZXhwIjoyMDY4MTA2NDkzfQ.7wrYhMv0LyMMTSR-hN3Ltg15YmppOs75zbrETlrz4J0",
            revenueCatSandbox: "appl_YGEFzvwuYvHFfzXQAJlQsdzMjyW"
        )
        
        print("✅ Keys setup complete!")
        
        // Verify the keys were stored
        SecureKeyManager.shared.checkAllKeyStatuses()
    }
}