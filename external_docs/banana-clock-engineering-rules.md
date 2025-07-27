# Banana Clock iOS - Engineering Excellence Rules

## 🚀 Project Mission
Build a world-class iOS clock app that feels indistinguishable from Apple's native apps while delivering innovative AI-powered features with uncompromising reliability.

---

## 🏗️ Architecture Principles

### 1. **Zero Tolerance for Technical Debt**
- Every line of code must be production-ready
- No "temporary" solutions - build it right the first time
- Refactor immediately when patterns emerge
- Document all architectural decisions in ADRs (Architecture Decision Records)

### 2. **API Design First**
- Design all service interfaces before implementation
- Use protocol-oriented programming for all services
- Every public API must have comprehensive documentation
- Design for testability from day one

### 3. **Defensive Programming**
- Assume all external data is invalid until proven otherwise
- Handle all edge cases explicitly
- Use Swift's type system to make invalid states unrepresentable
- Fail gracefully with user-friendly error messages

---

## 🔐 AlarmKit Integration Rules

### Critical Requirements
```swift
// NEVER compromise on alarm reliability
- Alarms MUST fire 100% of the time
- Audio MUST play even in silent mode
- Fallback mechanisms for every failure point
- Test on real devices with various states (low battery, DND, etc.)
```

### Implementation Standards
1. **State Management**: Use finite state machines for alarm states
2. **Persistence**: Dual persistence (AlarmKit + Core Data backup)
3. **Monitoring**: Log all alarm events for debugging
4. **Testing**: Automated tests for all alarm scenarios

---

## 💻 Code Quality Standards

### Swift Best Practices
```swift
// Required for all code
- Use Swift 6 strict concurrency checking
- Implement proper actor isolation
- Use @MainActor for all UI updates
- Leverage async/await throughout
- No force unwrapping (!) except in tests
- Use guard for early returns
- Prefer immutable data structures
```

### Naming Conventions
```swift
// Clarity over brevity
✅ func scheduleAlarmForWakeUpTime(_ time: Date) async throws
❌ func schedAlrm(_ t: Date) async throws

// Boolean naming
✅ isAlarmEnabled, hasActiveSubscription, shouldShowPaywall
❌ alarmEnabled, subscription, paywall
```

### Documentation Requirements
```swift
/// Schedules an AI-powered wake-up alarm for the specified time.
/// 
/// - Parameters:
///   - wakeUpTime: The desired wake-up time in the user's timezone
///   - voiceOption: The AI voice to use for wake-up content
/// - Returns: The created alarm instance
/// - Throws: 
///   - `AlarmError.unauthorized` if AlarmKit permissions not granted
///   - `AlarmError.quotaExceeded` if user has reached alarm limit
///
/// - Note: This method requires an active Banana Plus subscription
func scheduleAIWakeUpAlarm(
    for wakeUpTime: Date,
    voice voiceOption: VoiceOption
) async throws -> Alarm
```

---

## 🧪 Testing Requirements

### Coverage Targets
- **Unit Tests**: 90% code coverage minimum
- **UI Tests**: All critical user flows
- **Integration Tests**: All external service interactions
- **Performance Tests**: App launch, alarm scheduling, audio playback

### Test Pyramid
```
         /\
        /UI\        10% - Critical user journeys
       /----\
      / Intg \      20% - Service integration
     /--------\
    /   Unit   \    70% - Business logic
   /____________\
```

### Testing Checklist
- [ ] All public methods have tests
- [ ] Edge cases explicitly tested
- [ ] Error conditions verified
- [ ] Memory leaks checked
- [ ] Thread safety validated
- [ ] Performance benchmarked

---

## 🎨 UI/UX Excellence

### Apple HIG Compliance
- **Touch Targets**: Minimum 44x44 points
- **Typography**: Dynamic Type support required
- **Colors**: Semantic colors with dark mode support
- **Animation**: 60 FPS minimum, respect reduce motion
- **Haptics**: Appropriate tactile feedback
- **Accessibility**: VoiceOver, Voice Control, Switch Control

### Performance Standards
```swift
// Required metrics
- App launch: < 1 second
- View transitions: < 0.3 seconds
- Alarm scheduling: < 100ms
- Audio start: < 50ms
- Memory usage: < 100MB baseline
- Battery impact: < 5% daily
```

---

## 🔒 Security & Privacy

### Data Protection
```swift
// Mandatory practices
- Keychain for sensitive data
- Encrypted Core Data for user content
- No logging of personal information
- SSL pinning for API calls
- Biometric authentication for premium features
```

### Privacy Guidelines
- Minimal data collection
- Clear privacy labels
- Opt-in for all analytics
- Data deletion on request
- No third-party tracking

---

## 🚦 Development Workflow

### Pre-Commit Checklist
```bash
# Must pass before ANY commit
1. swift-format --recursive Sources/ Tests/
2. swiftlint analyze --strict
3. xcodebuild test -scheme BananaClock
4. instruments -t "Memory Leaks" -l 30000
5. git diff --check (no whitespace errors)
```

### Pull Request Standards
- Atomic commits with clear messages
- Comprehensive PR description
- Test coverage report
- Performance impact analysis
- Screenshots/videos for UI changes
- Two approvals required

### Branch Strategy
```
main (production)
  └── develop (staging)
        └── feature/alarm-kit-integration
        └── feature/ai-wake-up
        └── bugfix/audio-delay
```

---

## 🎯 Quality Gates

### Definition of Done
- [ ] Code follows all style guidelines
- [ ] Unit tests written and passing
- [ ] UI tests for user-facing changes
- [ ] Documentation updated
- [ ] Accessibility verified
- [ ] Performance benchmarked
- [ ] Security review passed
- [ ] QA sign-off received

### Performance Monitoring
```swift
// Required MetricKit integration
- App launch time
- Hang rate
- Crash rate
- Memory usage
- Disk writes
- Battery drain
```

---

## 🛠️ Error Handling

### User-Facing Errors
```swift
// Always provide actionable messages
✅ "Unable to schedule alarm. Please grant alarm permissions in Settings."
❌ "Error: Permission denied"

// Include recovery suggestions
✅ "AI wake-up unavailable. Check your internet connection or try again."
❌ "Network error"
```

### Logging Standards
```swift
// Use structured logging
logger.error("Alarm scheduling failed", 
    metadata: [
        "alarm_id": alarmID,
        "error": error.localizedDescription,
        "retry_count": retryCount
    ]
)
```

---

## 📱 Device Compatibility

### Testing Matrix
- **Primary**: iPhone 16 Pro (latest iOS 26)
- **Secondary**: iPhone 15, iPhone 14
- **Minimum**: iPhone 13 (oldest supported)
- **Edge Cases**: Low storage, poor network, battery saver

### Capability Detection
```swift
// Never assume device capabilities
if AlarmManager.shared.isAvailable {
    // Use AlarmKit
} else {
    // Graceful degradation
}
```

---

## 🌟 Innovation Guidelines

### AI Features
- Response time < 2 seconds
- Offline fallback required
- Cost optimization (cache responses)
- Privacy-preserving design
- Graceful degradation

### Future-Proofing
- Design for extensibility
- Version all APIs
- Feature flag new capabilities
- Maintain backwards compatibility
- Plan for deprecation

---

## 📊 Success Metrics

### Code Quality KPIs
- **Build Success Rate**: > 99%
- **Test Pass Rate**: 100%
- **Code Review Turnaround**: < 24 hours
- **Bug Escape Rate**: < 0.1%
- **Technical Debt**: < 5% of codebase

### Runtime KPIs
- **Crash-Free Rate**: > 99.9%
- **Alarm Success Rate**: > 99.99%
- **Audio Playback Success**: > 99.9%
- **API Response Time**: < 200ms p95
- **User Rating**: > 4.8 stars

---

## 🚨 Red Flags to Avoid

### Architecture Smells
- ❌ Massive view controllers
- ❌ Circular dependencies
- ❌ Global mutable state
- ❌ Synchronous network calls
- ❌ Hardcoded values

### Code Smells
- ❌ Functions > 50 lines
- ❌ Classes > 300 lines
- ❌ Cyclomatic complexity > 10
- ❌ Nested callbacks > 3 levels
- ❌ Copy-pasted code

---

## 🎓 Continuous Learning

### Required Knowledge
- AlarmKit documentation (when available)
- Latest Swift evolution proposals
- Apple WWDC sessions on time-based apps
- Audio programming best practices
- Subscription app guidelines

### Team Standards
- Code review participation
- Weekly architecture discussions
- Monthly performance reviews
- Quarterly security audits
- Annual HIG compliance check

---

## 🍌 The Banana Standard

**Every decision should answer "YES" to these questions:**
1. Would Apple engineers be proud of this code?
2. Will this delight users at 6 AM when their alarm goes off?
3. Can another developer understand this in 6 months?
4. Does this make the app more reliable?
5. Is this the simplest solution that works perfectly?

**Remember**: We're not just building an app, we're crafting an experience that users trust with the most important moment of their day - waking up.

---

## 📝 Living Document

This document evolves with the project. Proposed changes require:
1. Concrete justification
2. Team consensus
3. Documentation update
4. Retroactive application where feasible

**Last Updated**: [Auto-update with each change]
**Version**: 1.0.0