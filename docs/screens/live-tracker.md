# Live Zone 2 tracker

**Status:** Live  
**Feature:** Training  
**File:** [`LiveTrackerView.swift`](../../HybridVital/Features/Training/Views/LiveTrackerView.swift)  
**ViewModel:** [`LiveTrackerViewModel`](../../HybridVital/Features/Training/ViewModels/LiveTrackerViewModel.swift)  
**Opened from:** Home Zone 2 or Training hub (`fullScreenCover`)  
**Opens:** `ZoneSettingsView` sheet; on end, `SessionSummaryView` in-place  

## Purpose

Outdoor Zone 2 session: BLE HR, HealthKit workout, jog/walk laps, Z3 haptic cue.

## Layout

Forced dark. Three modes: **setup** (connection card, start), **active** (clock, BPM, zone, lap CTA), **summary** (after save).

Interactive dismiss disabled while live. End/Pause in toolbar.

## Data

| Source | Role |
| --- | --- |
| `HeartRateBLEService.snapshot()` | BPM, status, devices (polled 1s) |
| `WorkoutSessionManager` | HK session, calories, distance, phase |
| `repository.getOrCreateProfile().heartRateZones` | Zone math |
| Widget lap channel | Toggle jog/walk |

## Actions

Start (optionally without HR), pause/resume, lap (jog ↔ walk), undo last lap, end (confirm), zone settings, COROS help alert.

## Persistence

On end: `TrainingRepository.save(session:)` with intervals, zone durations, downsampled HR, HK UUID. Then `savedSession` swaps UI to summary.

## Protocol notes

- **Do not** `@Observable` the BLE service. Poll snapshots.
- `LiveTrackerBridge` is a weak static for widget callbacks — documented in [API.md](../API.md); don’t clone for other features.
- Z3 flash + haptics are coaching cues, not medical alerts.

## Future

Resume an orphaned HK session; start-widget deep link.
