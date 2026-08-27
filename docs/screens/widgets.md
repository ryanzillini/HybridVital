# Widgets & Live Activity

**Status:** Partial  
**Feature:** Training / App extensions  
**Files:**

- [`Zone2LiveActivity.swift`](../../HybridVitalWidgets/Zone2LiveActivity.swift)
- [`Zone2StartWidget.swift`](../../HybridVitalWidgets/Zone2StartWidget.swift)
- [`HybridVitalWidgets.swift`](../../HybridVitalWidgets/HybridVitalWidgets.swift)
- Shared: `Zone2ActivityAttributes`, `ToggleLapIntent`, `LapToggleChannel`

**Opened from:** Lock Screen, Dynamic Island, Home Screen  
**Opens:** Lap toggle into a running session; start widget does **not** deep-link  

## Purpose

Glanceable BPM, zone, jog/walk, elapsed. Island/lock button toggles lap without opening the app.

## Layout

Lock: large BPM, zone color (green vs orange at Z3). Island: compact BPM, expanded lap button. Home widget: start Zone 2 (decorative until URL/deep link).

## Data

`ActivityKit` state from `Zone2LiveActivityController` in the app process. Lap IPC: [API.md](../API.md#live-activities--widgets).

## Protocol notes

Shared types must live in `HybridVitalShared`. App Group `group.com.hybridvital.HybridVital`. Do not put SwiftData models in the widget target.
