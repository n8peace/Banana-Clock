-- Migration: Remove vibration setting from alarms
-- All alarms now assume vibration is always enabled

-- Note: This migration documents the removal of vibration settings
-- from the iOS app. The vibrationEnabled field has been removed from:
-- 1. Alarm model (alarm-model.swift)
-- 2. Core Data model (CDAlarm entity)
-- 3. UI components (alarm-detail-view.swift)
-- 4. Services (core-data-manager.swift, alarmkit-service.swift)

-- Vibration is now always assumed to be enabled for all alarms 