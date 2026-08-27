# Database — SwiftData

HybridVital’s **application source of truth** is SwiftData. HealthKit holds biometric workouts (see [API.md](API.md#healthkit)). This page is the schema + repository contract.

Implementation: [`HybridVital/Core/Models/CoreModel.swift`](../HybridVital/Core/Models/CoreModel.swift)

---

## Container

Bootstrapped in [`HybridVitalApp`](../HybridVital/App/HybridVitalApp.swift):

```swift
ModelContainer(for:
  UserProfile.self,
  DailyLog.self,
  FoodEntry.self,
  TrainingSession.self,
  WorkoutInterval.self
)
```

On-disk (not in-memory) for the running app. Previews use `ModelConfiguration(isStoredInMemoryOnly: true)`.

`SwiftDataContainer` actor defines the same schema but is **not** attached to the scene. Do not call it until `@main` is switched over.

There is **no migration versioning** yet. Additive optional properties are safest. Renames/deletes require a plan before shipping to a device with data.

---

## Entity-relationship

```
UserProfile  (1, singleton-by-convention)
     └── heartRateZones, targetMacros, preferences (value types)

DailyLog (1 per calendar day)
     └── foodEntries [FoodEntry]  cascade delete

TrainingSession
     └── intervals [WorkoutInterval]  cascade delete, inverse \.session
```

There is no FK from sessions or logs to `UserProfile`. The profile is “the only UserProfile row.” Repositories `getOrCreateProfile()` with `fetchLimit: 1` sorted by `createdAt`.

---

## `@Model` types

### UserProfile

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `UUID` unique | |
| `firstName` | `String?` | Default `"Ryan"` in `init()` |
| `birthDate` | `Date?` | Drives `estimatedMaxHR` (220 − age, min 120) |
| `heightCm` | `Double?` | Unused in UI |
| `biologicalSex` | `BiologicalSex?` | |
| `hasFamilialHypocholesterolemia` | `Bool` | Default `true` — conservative cholesterol copy |
| `primaryGoals` | `[GoalType]` | Default cholesterol + hybrid athlete |
| `cookingSkillLevel` | `CookingSkillLevel` | Default `.low` |
| `commonIssues` | `[HealthIssue]` | Default constipation, low energy |
| `targetMacros` | `MacroTargets` | Default P 180 / C 150 / F 80 |
| `foodPreferences` | `[FoodPreference]` | Name + liked flag |
| `allergies` | `[String]` | |
| `dislikedFoods` | `[String]` | |
| `weeklyZone2TargetMinutes` | `Int` | Default 150 |
| `notificationPreferences` | `NotificationSettings` | `enabled` bool |
| `heartRateZones` | `HeartRateZoneSettings` | See value types |
| `createdAt` / `updatedAt` | `Date` | |

**Convention:** one profile. Never query “current user” by id.

### DailyLog

Query hub for a calendar day (start-of-day `date`).

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `UUID` unique | |
| `date` | `Date` | Start of day |
| `foodEntries` | `[FoodEntry]` | Cascade |
| `energyLevel` | `Int?` | 1–10 check-in |
| `constipationSeverity` | `Int?` | 1–10 check-in |
| `notes` | `String?` | |
| `createdAt` / `updatedAt` | `Date` | |

Food saves **always** attach to today’s log via `getOrCreateTodayLog()`. History uses `logs(inLastDays:)`.

### FoodEntry

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `UUID` unique | |
| `dailyLog` | `DailyLog?` | Inverse of log.foodEntries |
| `timestamp` | `Date` | |
| `mealType` | `MealType` | breakfast…other |
| `foodName` | `String` | |
| `brandName` | `String?` | |
| `quantity` | `Double` | |
| `unit` | `String` | Default `"g"` |
| `nutrition` | `NutritionInfo` | Embedded struct |
| `source` | `LogSource` | vision / manual / usda / off / voice |
| `confidenceScore` | `Double?` | 0…1 for vision |
| `imageFileName` | `String?` | Unused (no photo store yet) |
| `notes` | `String?` | |
| `createdAt` | `Date` | |

No update API. “Edit” today = user opens Quick Log with a catalog draft (does not mutate the original row). Delete is implemented.

### TrainingSession

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `UUID` unique | |
| `startedAt` / `endedAt` | `Date` / `Date?` | |
| `healthKitWorkoutUUID` | `UUID?` | Link to HK workout; delete in-app does **not** delete HK |
| `avgHR` `maxHR` `minHR` | `Double?` | |
| `zoneDurations` | `ZoneDurations` | Seconds per Z1–Z5 |
| `intervalCount` | `Int` | |
| `avgJogSeconds` `avgWalkSeconds` | `Double?` | |
| `longestJogSeconds` `fastestRecoverySeconds` | `Double?` | |
| `fatigueNote` | `String?` | Heuristic string |
| `notes` | `String?` | |
| `downsampledHR` | `[HRSamplePoint]` | Chart series |
| `activeCalories` `distanceMeters` | `Double?` | |
| `createdAt` | `Date` | |
| `intervals` | `[WorkoutInterval]` | Cascade |

Computed: `durationSeconds`, `sortedIntervals`.

### WorkoutInterval

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `UUID` unique | |
| `kind` | `IntervalKind` | jog / walk (`HybridVitalShared`) |
| `startedAt` / `endedAt` | `Date` / `Date?` | |
| `startHR` `endHR` `avgHR` `maxHR` `minHR` | `Double?` | |
| `durationSeconds` | `Double` | |
| `timeToReenterZone2Seconds` | `Double?` | Walk recovery |
| `session` | `TrainingSession?` | Inverse |

---

## Value types (not `@Model`)

Stored inline on models via `Codable` (SwiftData transforms).

| Type | Role |
| --- | --- |
| `NutritionInfo` | kcal, P/C/F/fiber/sugar/cholesterol/sodium + `customValues` |
| `MacroTargets` | Int grams P/C/F |
| `HeartRateZone` | number, name, min/max BPM |
| `HeartRateZoneSettings` | maxHR, optional restingHR, zones[]; `%` rebuild; `zone3Floor`; Z2/Z3 tests |
| `ZoneDurations` | seconds per zone, `%` Z2, at/above Z3 |
| `HRSamplePoint` | timestamp + bpm |
| `FoodPreference` | name + isLiked |
| `NotificationSettings` | enabled |

Enums (all `String` raw, Codable): `GoalType`, `CookingSkillLevel`, `HealthIssue`, `BiologicalSex`, `MealType`, `LogSource`, `IntervalKind` (shared target).

SwiftData decodes these with `try!`. Unknown raw values from older local stores (for example a retired `HealthIssue.bloodPressureWatch`) must not throw. Array enums (`GoalType`, `HealthIssue`) decode unknown strings as `.unrecognized`, hide that case from UI via `selectableCases`, and `TrainingRepository.getOrCreateProfile()` strips them on load. Single-value enums fall back (`CookingSkillLevel` → `.low`, `MealType` → `.other`, `LogSource` → `.manual`, `BiologicalSex` → `.other`).

UI helpers (`displayName`, `systemImage`) live on the enums in `CoreModel.swift`. Keep them there so every screen shares copy.

---

## Default profile (Ryan-tuned)

Set in `UserProfile.init()`:

- Name Ryan, familial hypocholesterolemia on
- Goals: cholesterol control + hybrid athlete
- Cooking: low
- Issues: constipation, low energy
- Macros 180 / 150 / 80
- Zone 2 target 150 min/week
- Zones from estimated max HR (180 if no birth date)

These are **product defaults**, not medical targets. Copy should say that.

---

## Repositories (internal API)

### FoodLoggingRepository

File: `Features/FoodLogging/Repository/FoodLoggingRepository.swift`

| Method | Behavior |
| --- | --- |
| `fetchTodayLog()` | `DailyLog` where `date` in `[today, tomorrow)` |
| `getOrCreateTodayLog()` | Insert start-of-day log if missing |
| `save(entry:)` | Attach to today, insert, save |
| `delete(entry:)` | Delete row, save |
| `getTodayEntries()` | Today’s meals, newest first |
| `getTodayNutritionTotals()` | Sum of `NutritionInfo` fields |
| `logs(inLastDays:)` | Logs with `date >= startOfDay(now − days)` |
| `saveDailyCheckIn(energy:constipation:notes:)` | Write 1–10 scores + notes on today |

**Not implemented:** update entry, save to a day other than today, HealthKit dietary write, pagination.

Errors: logged with `print`, methods return nil/empty or proceed anyway.

### TrainingRepository

File: `Features/Training/Repository/TrainingRepository.swift`

| Method | Behavior |
| --- | --- |
| `getOrCreateProfile()` | First profile or insert defaults + default zones |
| `saveZoneSettings(_:)` | Mutate profile.heartRateZones |
| `saveProfile(_:)` | Closure mutation + `updatedAt` |
| `save(session:)` | Insert session + intervals missing context |
| `recentSessions(limit:)` | `startedAt` descending, default 20 |
| `delete(session:)` | Local delete only (HK workout remains) |

---

## Derived reads (not extra tables)

`ProgressSnapshot.load(services:range:)` builds chart series from `logs(inLastDays:)` and `recentSessions`. If those are empty, it returns `DemoCatalog` series and flags `macrosAreSample` / `trainingIsSample`.

Coach does **not** query a memory table. Memory UI reads `DemoCatalog.memories`. Future: learned patterns as their own `@Model`.

---

## Planned models (not in schema)

From older specs: Bloodwork, SupplementLog, dedicated TrainingLog (sessions already cover Zone 2). Add only with a screen + repo + this file updated.

---

## Integrity rules

1. One `UserProfile`.
2. One `DailyLog` per start-of-day (enforced in repo, not a unique constraint on `date` beyond `id`).
3. Food entries always belong to a log after `save`.
4. Deleting a session does not touch HealthKit.
5. Do not store LLM transcripts yet (no `ChatMessage` `@Model`).
