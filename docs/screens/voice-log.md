# Voice log

**Status:** Stub  
**Feature:** FoodLogging  
**File:** [`VoiceLogView.swift`](../../HybridVital/Features/FoodLogging/Views/VoiceLogView.swift)  
**ViewModel:** none  
**Opened from:** Home or Food hub  
**Opens:** `FoodAnalysisReviewSheet` (`source: .voice`)  

## Purpose

Mic + waveform UX for <15s logging. No Speech framework.

## Layout

Mic button, capsule waveform, status, transcript field after “capture”, Confirm meal, disclaimer that voice is simulated.

Idle → listening (~1.8s animated bars) → captured. Transcript defaults to yogurt/berries/honey/chia.

## Data

Confirm builds `DemoCatalog.CatalogFood` from `visionParse` with the transcript as `name` and `source: .voice`.

## Persistence

On review save.

## Protocol notes

Do not add mic plist keys until SFSpeechRecognizer (or equivalent) is wired. [API.md](../API.md#voice-log).
