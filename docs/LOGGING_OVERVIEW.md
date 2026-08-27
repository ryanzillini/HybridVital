# Food Logging Overview — HybridVital

**Last Updated:** May 7, 2026  
**Owner:** Ryan + Grok Co-founder

## Philosophy

Effortless <15s logging is the #1 retention driver. Photo-first (Grok Vision) + manual/text fallback. Always editable. Ryan-tuned (high-protein, fiber emphasis, cholesterol awareness, low-cooking meals).

## Core Flow (MVP)

1. Dashboard + Button → Action sheet (Camera / Library / Text Search / Voice stub)
2. Photo → Grok Vision parse → Review/Edit sheet
3. Save → SwiftData + HealthKit Dietary Intake (optimistic)
4. Same-day history list

## Data Sources

- **Primary parse**: Grok Vision API (structured JSON output)
- **Search fallback**: USDA FoodData Central API + Open Food Facts (via `openfoodfacts-swift` SPM)
- **Storage**: SwiftData `FoodEntry` + `DailyLog` hub (HealthKit golden source for nutrients)

## Screens

Canonical per-screen docs: [screens/README.md](screens/README.md) (Food section).

Originally named:

- QuickLogEntryView → `QuickFoodLogView`
- FoodAnalysisReviewSheet
- FoodSearchView
- DailyFoodHistoryView


## Non-negotiables

- Zero friction on Ryan’s device
- Confidence score + mandatory edit for vision results
- Local-first, offline capable
- Prep for AI Coach rolling metrics (fiber, protein trends)

Next: Implement models → repo → views.
