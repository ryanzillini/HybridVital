# Training hub

**Status:** Demo-backed (week minutes)  
**Feature:** Training  
**File:** [`TrainingHubView.swift`](../../HybridVital/Features/Training/Views/TrainingHubView.swift)  
**ViewModel:** none  
**Opened from:** Train tab  
**Opens:** Live tracker, zone settings, session summary  

## Purpose

Start Zone 2, see weekly volume, browse/delete recent sessions.

## Layout

Scroll: start card (green heart, 180pt), week minutes card, zones row, COROS help copy, session list or empty `HVEmptyState`, disclaimer.

## Data

| | Live | Fallback |
| --- | --- | --- |
| Sessions | `recentSessions()` | Empty state (no fake rows) |
| Week minutes | Sum `zone2Seconds` this week | `DemoCatalog.weeklyZone2CompletedMinutes` + “Sample week” |
| Target | `profile.weeklyZone2TargetMinutes` | 150 |

## Actions

- Start → `fullScreenCover` `LiveTrackerView`
- Zones → sheet `ZoneSettingsView`
- Session row → sheet `SessionSummaryView` (delete callback)
- Context menu delete → confirm; HK workout left intact

## Persistence

Delete via `TrainingRepository.delete`. Start/save happens in the tracker VM.

## Protocol notes

- Destructive copy must mention Apple Health is preserved.
- Hub is dark cards, not a system `List`, to match Home.
