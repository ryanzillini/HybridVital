# Quick / manual food log

**Status:** Live  
**Feature:** FoodLogging  
**File:** [`QuickFoodLogView.swift`](../../HybridVital/Features/FoodLogging/Views/QuickFoodLogView.swift)  
**ViewModel:** `QuickFoodLogViewModel`  
**Opened from:** Home, Food hub, entry “Log a correction”  
**Opens:** dismiss on successful save  

## Purpose

Typed meal when the user already knows macros. Always editable fields including fiber and cholesterol.

## Layout

Cards: meal identity, amount, nutrition fields, cholesterol banner, notes, Save, disclaimer.

Inits: `QuickFoodLogView(repository:)` or `(repository:food:)` to prefill from `CatalogFood`.

## Data

Calories default to 4P+4C+9F unless the user edits calories (`setCalories`). Validation: name required, macros ≥ 0.

## Persistence

`FoodEntry` `source = .manual` on today. Prefill path still saves a **new** row (correction ≠ update).

## Protocol notes

Manual is the fallback for every other method. Keep field parity with the review sheet.
