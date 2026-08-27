# Daily check-in

**Status:** Live  
**Feature:** Dashboard  
**File:** [`DailyCheckInView.swift`](../../HybridVital/Features/Dashboard/Views/DailyCheckInView.swift)  
**ViewModel:** none  
**Opened from:** Dashboard check-in card  
**Opens:** dismiss on save  

## Purpose

Twenty-second energy + digestion log so Coach can see patterns. Explicitly not a diagnosis.

## Layout

Dark `Form`:

- Energy 1–10 (capsules + adjustable a11y)
- Constipation severity 1–10 (labeled carefully)
- Optional notes
- Cancel / Save

## Data

Prefills from `repository.fetchTodayLog()` or defaults energy 6 / constipation 2.

## Actions

Save → `FoodLoggingRepository.saveDailyCheckIn(energy:constipation:notes:)`.

## Persistence

Writes `DailyLog.energyLevel`, `constipationSeverity`, `notes`, `updatedAt` for **today**.

## Protocol notes

- Clamp 1…10 in one helper.
- Footer copy states these are personal logs, not medical scores.
- Check-in lives on `DailyLog` (the day hub), not a separate entity.
