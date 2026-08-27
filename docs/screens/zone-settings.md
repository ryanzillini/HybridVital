# Heart rate zones

**Status:** Live  
**Feature:** Training / Profile  
**File:** [`ZoneSettingsView.swift`](../../HybridVital/Features/Training/Views/ZoneSettingsView.swift)  
**ViewModel:** none  
**Opened from:** Tracker, Training hub, Profile (sheet)  
**Opens:** dismiss  

## Purpose

Edit max HR and per-zone min/max BPM. Zone 3 min is the walk cue (`zone3Floor`).

## Layout

Dark `Form`: stepper 120–220, “Recalculate from max HR”, then min/max fields per zone. Cancel / Save.

## Data

`repository.getOrCreateProfile().heartRateZones`. Recalculate uses `HeartRateZoneSettings.rebuilt(maxHR:)`.

## Persistence

`TrainingRepository.saveZoneSettings`. Tracker reloads on sheet dismiss (`reloadZones`).

## Protocol notes

Footer explains saved min/max are what the run uses; recalculate replaces with % of max. Resting HR is on the struct but not in this UI yet.
