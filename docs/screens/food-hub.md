# Food hub

**Status:** Demo-backed  
**Feature:** FoodLogging  
**File:** [`FoodLogHubView.swift`](../../HybridVital/Features/FoodLogging/Views/FoodLogHubView.swift)  
**ViewModel:** none  
**Opened from:** Food tab  
**Opens:** capture, search, voice, manual, review, history, entry detail  

## Purpose

“Log in under 15 seconds” — all methods on one hub, plus today totals and meals.

## Layout

Hero copy, camera hero tile, 2×2 other methods, today rings (cal/protein/fiber) + carb/fat bars, meal list, history link, disclaimer.

## Data

Live `getTodayEntries` / totals. If empty: `DemoCatalog.todayMeals` and `NutritionInfo.sum`, caption “Sample day”.

Targets: `FoodLoggingTargets` (2200 kcal, 180 P, 150 C, 80 F, 35 fiber) in `FoodLoggingSupport.swift`.

## Actions

| camera/library | `fullScreenCover` `PhotoCaptureStubView` |
| search/voice/manual | sheets |
| Sample meal | `FoodAnalysisReviewSheet` (can save fixture into today) |
| Real meal | `FoodEntryDetailView` |
| Food history | push `DailyFoodHistoryView` |

## Persistence

None on the hub; children call `save`.

## Protocol notes

Method grid must stay in sync with `FoodLogMethod` and the Home picker.
