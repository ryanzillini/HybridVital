# Macro trends

**Status:** Demo-backed  
**Feature:** Progress  
**File:** [`MacroTrendsView.swift`](../../HybridVital/Features/Progress/Views/MacroTrendsView.swift)  
**Opened from:** Progress hub  
**Opens:** none  

## Purpose

Line + area charts for protein, fiber, calories vs target rules. Cholesterol is informational copy only (no series).

## Layout

Range picker, optional sample caption, three `Chart` cards (`LineMark` + `AreaMark` + target `RuleMark`), cholesterol note card, disclaimer.

## Data

`ProgressSnapshot` for selected range. Target protein from profile; fiber 35; calories from macro math.

## Protocol notes

Apple Charts in Core-adjacent feature code is the analytics pattern (same as session HR). Keep `unit: .day` on x.
