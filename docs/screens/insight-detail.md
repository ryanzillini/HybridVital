# Insight detail

**Status:** Demo-backed  
**Feature:** Coach  
**File:** [`InsightDetailView.swift`](../../HybridVital/Features/Coach/Views/InsightDetailView.swift)  
**ViewModel:** none  
**Opened from:** Coach home insight rows  
**Opens:** `CoachChatView` with a pre-seeded prompt  

## Purpose

Explain why an insight appeared (memory layers) and that it is not a diagnosis.

## Layout

Insight banner, “Not a diagnosis” banner, why copy (by `insight.kind`), Permanent / Rolling / Learned cards from `DemoCatalog.memories`, Ask Coach CTA, disclaimer.

`init(insight:services:)` — services optional; falls back to repos from `modelContext`.

Home’s `DashboardInsightSheet` is a **lighter** cousin; keep both until Home should push this type.

## Persistence

None.

## Protocol notes

Kind strings (`Learned pattern`, `Rolling metric`, `Live context`) must match `DemoCatalog.Insight.kind` — they drive copy switches.
