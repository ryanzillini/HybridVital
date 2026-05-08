# Core/Models

**Last Updated:** May 7, 2026  
**Purpose**: Single source of truth for all SwiftData models and shared value types used across HybridVital.  
**Philosophy**: Lean, extensible, Ryan-first, HealthKit-compatible. Changes here are schema-breaking → plan migrations early.

**Files**

- `CoreModels.swift` — All @Model classes + enums + structs

**Rules**

- Every persisted model = `@Model`
- Value types (structs) preferred for NutritionInfo, targets, etc.
- All models must be Codable where possible (Supabase / AI serialization)
- Document Ryan-specific defaults and constraints inline
- Keep models small — DailyLog is the query hub

**See also**: DATA_MODELS.md (master spec), ARCHITECTURE..md
