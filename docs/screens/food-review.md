# Vision / analysis review

**Status:** Demo-backed save  
**Feature:** FoodLogging  
**File:** [`FoodAnalysisReviewSheet.swift`](../../HybridVital/Features/FoodLogging/Views/FoodAnalysisReviewSheet.swift)  
**ViewModel:** `FoodAnalysisReviewViewModel`  
**Opened from:** Capture, voice, search, sample meal  
**Opens:** `FoodSearchView` (“Looks off”)  

## Purpose

Mandatory edit of a parsed meal. Confidence is a hint. Cholesterol banner if ≥ 100 mg.

## Layout

Confidence header, identity (name, brand, meal type), amount, full macros (including fiber/sugar/cholesterol/sodium), notes, Save, search fallback, disclaimer.

## Data

Init: `FoodAnalysisReviewSheet(repository:food:saveSource:onSaved:)`.  
`saveSource` defaults `.grokVision`; search/voice pass through.

## Actions

Save → `makeEntry` validation → `repository.save`. Cancel dismisses without save.

## Persistence

New `FoodEntry` on **today’s** `DailyLog`. Original row is not updated (no update API).

## Protocol notes

Vision results **never** skip this screen. That is a product non-negotiable ([LOGGING_OVERVIEW](../LOGGING_OVERVIEW.md)).
