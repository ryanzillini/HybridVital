# Food search

**Status:** Stub catalog  
**Feature:** FoodLogging  
**File:** [`FoodSearchView.swift`](../../HybridVital/Features/FoodLogging/Views/FoodSearchView.swift)  
**ViewModel:** none  
**Opened from:** Food hub, Home, review “search instead”  
**Opens:** `FoodAnalysisReviewSheet`  

## Purpose

Client-side search over a fixture list shaped like USDA + Open Food Facts.

## Layout

Search field, Recents / USDA / OFF sections (`FoodMealRow`), empty state, disclaimer that listings are a local demo catalog.

## Data

`DemoCatalog.searchResults`, filter on name/brand. `source` splits sections.

## Actions

Tap → review sheet. Context menu: review or **Add now** (`makeFoodEntry` + `repository.save`) with “Added …” notice.

`onSaved` lets the parent dismiss a stack of sheets.

## Persistence

Only on add/review save. See [API.md](../API.md#usda-fooddata-central).

## Protocol notes

When the real APIs land, keep this view; swap the array for a service result of the same `CatalogFood` shape.
