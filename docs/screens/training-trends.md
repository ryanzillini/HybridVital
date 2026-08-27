# Training trends

**Status:** Demo-backed  
**Feature:** Progress  
**File:** [`TrainingTrendsView.swift`](../../HybridVital/Features/Progress/Views/TrainingTrendsView.swift)  
**Opened from:** Progress hub  
**Opens:** none  

## Purpose

Bar chart of Zone 2 minutes per day. Copy: consistency over intensity; rest days are plan, not failure.

## Data

`snapshot.trainingDays`. Tiles: total minutes, days trained, average Z2 %.

## Protocol notes

`Chart(snapshot.trainingDays)` requires `TrainingDay: Identifiable` (on `DemoCatalog.TrainingDay`).
