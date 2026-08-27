# Food preferences & allergies

**Status:** Live  
**Feature:** Profile  
**File:** [`PreferencesSettingsView.swift`](../../HybridVital/Features/Profile/Views/PreferencesSettingsView.swift)  
**Opened from:** Profile  

## Purpose

Cooking skill, allergies, disliked foods, liked `FoodPreference` rows (heart toggle).

## Persistence

`saveProfile`: `allergies`, `dislikedFoods`, `foodPreferences`, `cookingSkillLevel`. Also on disappear.

## Protocol notes

These arrays are Coach context (permanent profile). Search/vision should exclude allergies once APIs are live — call that out in [API.md](../API.md) when implemented.
