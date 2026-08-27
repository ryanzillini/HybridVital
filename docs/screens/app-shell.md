# App shell / tabs

**Status:** Live  
**Feature:** App  
**File:** [`HybridVital/App/RootView.swift`](../../HybridVital/App/RootView.swift)  
**ViewModel:** none (`@State` services + AppStorage)  
**Opened from:** `HybridVitalApp` `WindowGroup`  
**Opens:** Onboarding or five tab roots  

## Purpose

Composition root after SwiftData is ready. Owns dark chrome, green tint, and whether the user has finished onboarding.

## Layout

- Loading: black + `ProgressView` until `AppServices` exists
- Else if `hasCompletedOnboarding == false`: `OnboardingFlowView`
- Else: `TabView` — Home, Train, Food, Coach, Progress
- Tab bar: visible, black toolbar background

## Data

| Source | Live | Notes |
| --- | --- | --- |
| `@Environment(\.modelContext)` | Yes | From `HybridVitalApp` |
| `AppServices(food:training:)` | Yes | Built once in `.task` |
| `@AppStorage("hasCompletedOnboarding")` | Yes | Default `false` |

## Actions

None besides tab switching. Profile replay of onboarding flips the same AppStorage key.

## Persistence

Does not write models. Container created in `HybridVitalApp` for the five `@Model` types.

## Protocol notes

- **DI:** this is the only place repositories are constructed for the running app.
- **Do not** put feature UI back in this file (old `DashboardView` lived here; it moved).
- Tab roots each own a `NavigationStack` except destinations that are pushed from Home (Profile).

## Future

Deep links from `Zone2StartWidget`. Scene restore of an in-progress workout.
