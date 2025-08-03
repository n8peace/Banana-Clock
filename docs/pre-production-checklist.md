# Pre-Production Checklist - Banana Clock

## Overview
This checklist covers essential items to review before deploying Banana Clock to production. Each section should be thoroughly reviewed and verified.

---

## 🔒 Security & API Keys

### API Key Management
- [ ] Verify all API keys are in `Secrets.swift` (gitignored)
- [ ] Confirm no hardcoded API keys in source code
- [ ] Check Supabase API keys are production keys (not development)
- [ ] Verify RevenueCat API keys are production keys
- [ ] Ensure ElevenLabs API key has proper rate limiting configured
- [ ] Confirm OpenAI API key has spending limits set

### Authentication & Authorization
- [ ] Test Supabase RLS (Row Level Security) policies are properly restrictive
- [ ] Verify users can only access their own data
- [ ] Check wake-up alarm exclusion from bulk operations
- [ ] Confirm user timezone exclusion from deletion
- [ ] Test subscription verification through RevenueCat

### Data Protection
- [ ] Verify no sensitive data in logs or error messages
- [ ] Check audio files have 72-hour retention policy
- [ ] Confirm user data is properly encrypted in transit
- [ ] Test that deleted user data is fully removed

---

## 🎨 UI/UX Consistency

### Edit Mode Consistency
- [ ] Verify Timers, Alarms, and World Clock have identical edit mode behavior
- [ ] Check "Edit" button shows checkmark when active across all views
- [ ] Confirm bottom action bar appears consistently
- [ ] Test "Select All/Deselect All" functionality
- [ ] Verify bulk delete shows count "(n)" consistently

### Visual Consistency
- [ ] Dark mode only - no light mode leaks
- [ ] Banana yellow (#FDE043) used consistently for accents
- [ ] Navigation title "Banana Clock" persists across all views
- [ ] Tab bar icons and styling consistent
- [ ] Empty states have consistent design pattern

### Interaction Patterns
- [ ] Swipe-to-delete works in Timers and Alarms
- [ ] Row selection only works in edit mode
- [ ] Buttons are clickable in normal mode (Timers)
- [ ] Long press triggers (if implemented) work consistently
- [ ] Pull-to-refresh (if implemented) works consistently

---

## 🐛 Known Issues & Bug Fixes

### Timer Functionality
- [ ] Timer buttons (play/pause/cancel) are clickable
- [ ] Timer row selection works in edit mode
- [ ] Swipe-to-delete functions properly
- [ ] Timer state persists correctly
- [ ] Background timer updates work

### Alarm Integration
- [ ] AlarmKit alarms appear in native Clock app
- [ ] Wake-up alarm AI content generates at 2 AM
- [ ] Alarm snooze functionality works (1-15 minutes)
- [ ] Repeat schedules function correctly
- [ ] Audio fallback works when AI fails

### World Clock Features
- [ ] Timezone converter slider works smoothly
- [ ] AI recommendations trigger properly
- [ ] Date picker has proper contrast (light mode)
- [ ] Planetary time calculations are accurate
- [ ] Current timezone shows at top

---

## 💰 Monetization & Subscriptions

### RevenueCat Integration
- [ ] Hard paywall blocks all features for non-subscribers
- [ ] Free trial periods work correctly (3-day monthly, 7-day annual)
- [ ] Subscription restoration works
- [ ] Price points display correctly ($4.99/mo, $39.99/yr)
- [ ] Entitlement ID "banana_plus" properly configured

### Subscription Edge Cases
- [ ] Alarms continue working if subscription expires during active alarm
- [ ] Proper messaging when subscription is expired
- [ ] Grace period handling (if configured)
- [ ] Family sharing support (if enabled)

---

## 🔊 Audio & Background Modes

### Audio Playback
- [ ] All audio files are AAC format
- [ ] Audio mixer implementation for AI wake-up (if completed)
- [ ] Background audio continues when app is suspended
- [ ] Volume controls work properly
- [ ] Audio ducking behaves correctly with other apps

### Background Execution
- [ ] Timers continue counting in background
- [ ] Alarm notifications fire on time
- [ ] AI content generation runs at 2 AM
- [ ] Background fetch (if used) has reasonable intervals

---

## 📱 Device & OS Compatibility

### iOS Version Support
- [ ] Test on iOS 26.0 (minimum supported)
- [ ] Test on iOS 26.x (latest)
- [ ] Verify all iOS 26+ features work
- [ ] Verify AlarmKit custom sounds work properly

### Device Testing
- [ ] iPhone SE (smallest screen)
- [ ] iPhone 15 Pro (standard)
- [ ] iPhone 15 Pro Max (largest)
- [ ] iPad compatibility (if supported)
- [ ] Dynamic Island compatibility

### Permissions
- [ ] Notification permissions requested appropriately
- [ ] AlarmKit permissions handled gracefully
- [ ] Microphone permissions (if needed)
- [ ] Background refresh permissions

---

## 🌐 Backend & API Integration

### Supabase Functions
- [ ] All Edge Functions deployed to production
- [ ] Functions have proper error handling
- [ ] Rate limiting configured for external APIs
- [ ] Retry logic works for failed API calls
- [ ] Health check endpoint responds

### Content Generation Pipeline
- [ ] GPT-4o generates appropriate wake-up scripts
- [ ] ElevenLabs synthesis completes in reasonable time
- [ ] Weather data fetches successfully
- [ ] Headlines aggregation works
- [ ] Fallback content available for failures

### Database Performance
- [ ] Indexes created for common queries
- [ ] Old alarm cleanup runs properly
- [ ] Audio file cleanup after 72 hours
- [ ] No N+1 query issues

---

## 🚀 Performance & Optimization

### App Performance
- [ ] Cold start time under 2 seconds
- [ ] Smooth scrolling in all lists
- [ ] No memory leaks in timer updates
- [ ] Animations run at 60fps
- [ ] No excessive battery drain

### Network Optimization
- [ ] API calls have proper timeout values
- [ ] Unnecessary network requests minimized
- [ ] Caching implemented where appropriate
- [ ] Offline mode handles gracefully

---

## 📊 Analytics & Monitoring

### Error Tracking
- [ ] Crash reporting configured
- [ ] Non-fatal error logging in place
- [ ] Supabase function logs accessible
- [ ] RevenueCat webhook errors monitored

### Usage Analytics
- [ ] Key user actions tracked
- [ ] Subscription conversion events
- [ ] Feature adoption metrics
- [ ] Performance metrics collected

---

## 🧪 Final Testing Checklist

### Critical User Flows
- [ ] New user onboarding and subscription
- [ ] Setting a wake-up alarm with AI
- [ ] Creating and managing timers
- [ ] Adding world clock locations
- [ ] Using timezone converter

### Edge Cases
- [ ] App works without internet (where applicable)
- [ ] Handles timezone changes correctly
- [ ] Daylight saving time transitions
- [ ] Subscription expiry during usage
- [ ] Multiple alarms at same time

### Regression Testing
- [ ] All previously fixed bugs remain fixed
- [ ] No new issues introduced
- [ ] Core functionality unchanged
- [ ] Performance hasn't degraded

---

## 📋 Deployment Readiness

### Code Quality
- [ ] No commented-out code in production
- [ ] No debug print statements
- [ ] Error messages are user-friendly
- [ ] Code follows established patterns

### Documentation
- [ ] CLAUDE.md is up-to-date
- [ ] API documentation current
- [ ] Deployment instructions clear
- [ ] Known issues documented

### CI/CD Pipeline
- [ ] Build succeeds on main branch
- [ ] Tests pass (if implemented)
- [ ] Deployment scripts work
- [ ] Rollback procedure documented

---

## 🚨 Emergency Procedures

### Rollback Plan
- [ ] Previous version tagged and available
- [ ] Database migration rollback scripts ready
- [ ] Quick disable switches for features
- [ ] Communication plan for issues

### Support Readiness
- [ ] Support team briefed on new features
- [ ] FAQ updated for common issues
- [ ] Error messages provide helpful guidance
- [ ] Feedback mechanism in place

---

## Sign-off

- [ ] Development team review completed
- [ ] QA testing completed
- [ ] Product owner approval
- [ ] Legal/compliance review (if needed)
- [ ] Final go/no-go decision made

**Deployment Date:** _______________

**Approved By:** _______________

**Notes:**
_____________________________________
_____________________________________
_____________________________________