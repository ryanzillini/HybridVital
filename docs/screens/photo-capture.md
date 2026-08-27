# Photo / library capture

**Status:** Stub  
**Feature:** FoodLogging  
**File:** [`PhotoCaptureStubView.swift`](../../HybridVital/Features/FoodLogging/Views/PhotoCaptureStubView.swift)  
**ViewModel:** none  
**Opened from:** Home method sheet or Food hub  
**Opens:** `FoodAnalysisReviewSheet` with `DemoCatalog.visionParse`  

## Purpose

Viewfinder UX for photo-first logging without camera permission. Library uses `PhotosPicker` then the **same** fixture.

## Layout

Full-screen dark: rounded viewfinder + grid, shutter, optional “Choose from library”, analyzing overlay (“Reading the plate…” ~700ms).

## Data

No image is sent anywhere. Review always loads `DemoCatalog.visionParse` (`source` grokVision, confidence ~0.81).

## Persistence

None until review saves.

## Protocol notes

- Do not add `NSCameraUsageDescription` until a real capture pipeline exists.
- Analyzing overlay is the loading pattern for future Grok latency.
- Contract: [API.md — Grok Vision](../API.md#grok-vision-meal-parse).
