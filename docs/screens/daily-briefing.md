# Daily briefing

**Status:** Demo-backed  
**Feature:** Coach  
**File:** [`DailyBriefingView.swift`](../../HybridVital/Features/Coach/Views/DailyBriefingView.swift)  
**ViewModel:** none  
**Opened from:** Coach home briefing card  
**Opens:** none  

## Purpose

Morning-style recap: training week, nutrition week, today’s focus (protein/fiber), low-cook meal ideas.

## Layout

Intro + `weeklyReportSummary`, training recap from `weekTraining`, nutrition from `weekMacros`, focus banner, suggested meals, disclaimer.

## Data

Only `DemoCatalog` (not `ProgressSnapshot`). Fine until briefing should match Progress charts.

## Persistence

None.

## Protocol notes

When wiring live data, reuse `ProgressSnapshot.load` rather than a third aggregator.
