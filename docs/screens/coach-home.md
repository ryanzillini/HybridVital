# Coach home

**Status:** Demo-backed  
**Feature:** Coach  
**File:** [`CoachHomeView.swift`](../../HybridVital/Features/Coach/Views/CoachHomeView.swift)  
**ViewModel:** none  
**Opened from:** Coach tab  
**Opens:** briefing, insight detail, chat, memory  

## Purpose

Differentiator landing: context already loaded, insights, ask, suggested prompts. User should not recap.

## Layout

Greeting (time of day + firstName), “Today” chip strip from system message, daily briefing card, insight list, Ask Coach CTA, suggested prompt grid, memory row, `HVDisclaimer`.

Shared chrome: `CoachComponents.swift` (chips, CTA label, row card).

## Data

Name from profile else `DemoCatalog`. Chips/insights/prompts/summary from `DemoCatalog`. No SwiftData chat.

## Actions

NavigationLinks into Coach stack (this tab owns `NavigationStack`).

## Protocol notes

- Mint (`HVTheme.coach`) only on this feature.
- Automatic context is a **product** requirement; the system chip card is the visual proof.
- Conservative copy on the home disclaimer, not only in chat.
