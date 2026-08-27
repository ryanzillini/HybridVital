# Food entry detail

**Status:** Live (real rows) / Demo (`DemoFoodDetailView`)  
**Feature:** FoodLogging  
**File:** [`FoodEntryDetailView.swift`](../../HybridVital/Features/FoodLogging/Views/FoodEntryDetailView.swift)  
**ViewModel:** none  
**Opened from:** Home, Food hub, history  
**Opens:** `QuickFoodLogView` (new correction row), delete confirm  

## Purpose

Show one meal’s nutrition and source; delete; optional “log a correction.”

## Layout

Meal type, name, amount, `FoodNutritionTiles`, cholesterol banner, source/confidence/brand/time, notes, correction CTA, delete, disclaimer.

`DemoFoodDetailView`: same tiles + optional “Add to today” which `save`s the fixture.

## Persistence

`delete(entry:)` only. Correction inserts another entry.

## Protocol notes

Until `update` exists, say “correction” not “edit” in UI. HK dietary not touched on delete.
