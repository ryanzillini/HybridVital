# FoodLogging Feature

**Purpose**: Complete MVP food logging experience for Ryan dogfooding next week.

**Key Files & Responsibilities**

- `Models/` — SwiftData models (FoodEntry, NutritionInfo, etc.)
- `Repository/` — SwiftData + HealthKit writes, Supabase sync stub
- `Services/` — Grok Vision, USDA search, Open Food Facts
- `Views/` — SwiftUI screens
- `ViewModels/` — @Observable MVVM
- `FoodLoggingScreenDocs/` — Per-screen documentation

**Dependencies**

- SwiftData, HealthKit
- Grok API (vision)
- openfoodfacts-swift (SPM)
- USDA FDC API (URLSession)

**Acceptance Criteria for MVP** (see LOGGING_OVERVIEW.md)

This folder is self-contained and ready for Cursor parallel editing.
