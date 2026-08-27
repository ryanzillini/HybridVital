# Weekly report

**Status:** Demo-backed  
**Feature:** Progress  
**File:** [`WeeklyReportView.swift`](../../HybridVital/Features/Progress/Views/WeeklyReportView.swift)  
**Opened from:** Progress hub  
**Opens:** system share sheet  

## Purpose

Narrative week + stat grid + share. Copy from `DemoCatalog.weeklyReportSummary` even when snapshot is live — known gap.

## Layout

Narrative card, 2×3 metrics (Z2, protein, fiber, energy, sessions, Z2 %), green Share report, disclaimer.

Share: `ShareLink(item: summary)` string, not PDF.

## Protocol notes

When generating a real report, build the string from `ProgressSnapshot` in one function and document it in [API.md](../API.md#export--share).
