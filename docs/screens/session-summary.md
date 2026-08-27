# Session summary

**Status:** Live  
**Feature:** Training  
**File:** [`SessionSummaryView.swift`](../../HybridVital/Features/Training/Views/SessionSummaryView.swift)  
**ViewModel:** none  
**Opened from:** After tracker save, or hub session sheet  
**Opens:** Share sheet (export), delete confirm  

## Purpose

Post-run recap: duration, HR, time-in-zone, jog/walk rollups, HR chart, laps. Export JSON/CSV.

## Layout

Black scroll: header clock, 3×2 stats, zone bars (`ZonePalette`), optional `fatigueNote`, jog/walk stats, `Charts` line, lap list. Menu: Export, Delete.

## Data

All from the `TrainingSession` instance passed in. Chart if `downsampledHR.count > 1`.

## Actions

| Export JSON | Full session payload |
| Export CSV | HR + laps files |
| Delete | `onDelete` then dismiss; HK untouched |
| Close | `onDone` or dismiss |

## Persistence

Read-only except delete callback owned by presenter (hub or tracker).

## Protocol notes

- `ZonePalette` lives in Core, not this file.
- Share uses temp directory via `SessionExport` ([API.md](../API.md#export--share)).
