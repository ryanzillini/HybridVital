# Food history

**Status:** Demo-backed  
**Feature:** FoodLogging  
**File:** [`DailyFoodHistoryView.swift`](../../HybridVital/Features/FoodLogging/Views/DailyFoodHistoryView.swift)  
**ViewModel:** none  
**Opened from:** Food hub  
**Opens:** `FoodEntryDetailView` / `DemoFoodDetailView`  

## Purpose

Last 7 days of meals and day-level calories/protein/fiber.

## Layout

Horizontal day picker, summary card, meal list or empty, disclaimer.

## Data

`repository.logs(inLastDays: 14)`. If no meals in those logs, `usingDemo`: `DemoCatalog.weekMacros` for the selected day + `todayMeals` as the list (same sample meals on every demo day).

## Persistence

Read-only besides what detail/delete does.

## Protocol notes

Demo list repeating todayMeals is acceptable for portfolio; replace with per-day fixtures if history is demoed in a talk.
