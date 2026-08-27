# Goals settings

**Status:** Live  
**Feature:** Profile  
**File:** [`GoalsSettingsView.swift`](../../HybridVital/Features/Profile/Views/GoalsSettingsView.swift)  
**Opened from:** Profile  
**Opens:** dismiss after save  

## Purpose

Multi-select `GoalType`. Cholesterol control selected → copy stays conservative.

## Persistence

`saveProfile { $0.primaryGoals = … }` on Save, toolbar Save, and `onDisappear` if not yet saved.

## Protocol notes

Auto-save on disappear avoids lost taps; `didSave` prevents double work. Same chip language as onboarding.
