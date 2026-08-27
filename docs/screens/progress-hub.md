# Progress hub

**Status:** Demo-backed  
**Feature:** Progress  
**File:** [`ProgressHubView.swift`](../../HybridVital/Features/Progress/Views/ProgressHubView.swift)  
**ViewModel:** `ProgressHubViewModel`  
**Opened from:** Progress tab  
**Opens:** macro / training / energy trends, weekly report  

## Purpose

Week/month snapshot: Zone 2 vs target, macro adherence, energy/digestion, links to charts.

## Layout

Segmented Week/Month, Zone 2 hero, adherence tiles, energy tiles, insight banner, trend rows, recent sessions (only if SwiftData has any), disclaimer.

## Data

`ProgressSnapshot.load(services:range:)` — [DATABASE.md](../DATABASE.md#derived-reads-not-extra-tables). Sample caption via `HVSampleCaption` when flags are set.

## Persistence

Read-only.

## Protocol notes

One snapshot type feeds hub **and** child charts. Don’t fetch again with a different date math.
