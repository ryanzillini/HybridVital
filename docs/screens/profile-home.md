# Profile home

**Status:** Live  
**Feature:** Profile  
**File:** [`ProfileHomeView.swift`](../../HybridVital/Features/Profile/Views/ProfileHomeView.swift)  
**ViewModel:** none  
**Opened from:** Home toolbar (push — **no** inner `NavigationStack`)  
**Opens:** goals, preferences, notifications, zones sheet, privacy, about  

## Purpose

Identity + settings index. Replay onboarding via AppStorage.

## Layout

Hero name, goal chips, at-a-glance facts (FH flag, issues, cooking, Z2 target), settings rows, onboarding toggle, disclaimer.

## Data

`services.training.getOrCreateProfile()` on init and `onAppear`.

## Actions

| Onboarding completed toggle | Writes `hasCompletedOnboarding`. Off → RootView shows onboarding immediately. |
| Heart rate zones | Sheet `ZoneSettingsView` |

## Persistence

Read profile here; writes happen on child screens. Toggle is AppStorage only.

## Protocol notes

Push destinations must not wrap another stack. Preview wraps `NavigationStack` itself.
