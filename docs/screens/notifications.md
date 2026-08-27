# Notifications

**Status:** Partial  
**Feature:** Profile  
**File:** [`NotificationsSettingsView.swift`](../../HybridVital/Features/Profile/Views/NotificationsSettingsView.swift)  
**Opened from:** Profile  

## Purpose

Master switch stored on `UserProfile.notificationPreferences.enabled`. Extra toggles (meal reminder, Zone 2 nudge, coach briefing) are **local preview only** — not scheduled.

## Persistence

Master switch via `saveProfile` on change and disappear. Preview toggles die with the view.

## Protocol notes

Copy states they are not system notifications yet. When adding UNUserNotificationCenter, document the IDs in [API.md](../API.md) and persist three bools on `NotificationSettings`.
