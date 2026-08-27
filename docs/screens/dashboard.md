# Dashboard (Home)

**Status:** Demo-backed  
**Feature:** Dashboard  
**File:** [`DashboardView.swift`](../../HybridVital/Features/Dashboard/Views/DashboardView.swift)  
**ViewModel:** `DashboardViewModel`  
**Opened from:** Home tab  
**Opens:** Live tracker, log-meal sheet, check-in, profile, insight sheet, food detail  

## Purpose

Today-at-a-glance: calories/macros vs targets, meals, Zone 2 week, one Coach insight, check-in CTA. First screen after onboarding.

## Layout

Scroll, `HVTheme` padding:

1. Title HybridVital + “Welcome back, {name}”
2. Quick actions: Zone 2, Log Meal
3. Today’s summary (hero kcal + four macros + bars)
4. Logged meals (or sample meals)
5. Zone 2 this week (minutes vs target)
6. Coach insight banner
7. Daily check-in card
8. `HVDisclaimer`

Toolbar: sparkles (insight) + profile.

## Data

| Field | Live | Fallback |
| --- | --- | --- |
| Name | `UserProfile.firstName` | `DemoCatalog.greetingName` |
| Macros / Z2 target | Profile | 180/150/80 · 150 min |
| Meals / totals | `food.getTodayEntries()` | `DemoCatalog.todayMeals` + “Sample day” |
| Week Z2 minutes | Sessions this week | `DemoCatalog.weeklyZone2CompletedMinutes` |
| Check-in | `fetchTodayLog()` energy/constipation | Empty CTA |
| Insight | — | `DemoCatalog.insights.first` |

Pull-to-refresh calls `viewModel.refresh()`.

## Actions

| Control | Destination |
| --- | --- |
| Zone 2 | `fullScreenCover` `LiveTrackerView` |
| Log Meal | Sheet: `FoodLogMethodSheet` then capture/search/voice/manual |
| Meal row | `FoodEntryDetailView` or demo meal sheet |
| Insight / sparkles | `DashboardInsightSheet` |
| Profile | Push `ProfileHomeView` (no nested stack) |
| Check-in | Sheet `DailyCheckInView` |

## Persistence

None directly. Child screens save.

## Protocol notes

- Sample caption when `todayEntries.isEmpty` — do not leave Home blank.
- Fiber target `35` is a **personal log target** on the VM, not a medical RDA claim.
- Insight sheet is local so Home does not depend on Coach’s `InsightDetailView`.

## Companion UI in the same file

- `DashboardInsightSheet` — title, kind chip, disclaimer
- `DashboardDemoMealSheet` — read-only sample meal
- `MealRow`, `MacroProgressRow`

## Future

Show last session on Home; swipe-to-delete meals; bind fiber target to profile.
