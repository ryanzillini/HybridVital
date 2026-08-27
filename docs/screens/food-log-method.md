# Log-meal method picker

**Status:** Live (navigation only)  
**Feature:** Dashboard / Food  
**File:** [`FoodLogMethodSheet.swift`](../../HybridVital/Features/Dashboard/Views/FoodLogMethodSheet.swift)  
**Enum:** [`FoodLogMethod.swift`](../../HybridVital/Features/FoodLogging/FoodLogMethod.swift)  
**Opened from:** Dashboard “Log Meal” (first step of the sheet)  
**Opens:** parent sets `selectedLogMethod` → capture / search / voice / manual  

## Purpose

One list of log paths so Home and any future entry point share copy and icons.

## Layout

Scroll of rows: icon, title, subtitle, chevron. Cancel in toolbar.

`FoodLogMethod`: camera, library, search, voice, manual.

## Data

None. Pure navigation.

## Actions

`onSelect(FoodLogMethod)` — Dashboard replaces sheet content with the matching screen.

Food **tab** does not use this sheet; it uses a grid on `FoodLogHubView` that calls the same destinations.

## Protocol notes

- New log path = add enum case + titles + both Home sheet and Food hub grid.
- Do not invent a second enum for the same five methods.
