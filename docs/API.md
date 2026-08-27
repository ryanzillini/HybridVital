# API contracts

Anything that is not SwiftData. Includes **live** Apple APIs, **widget IPC**, and **planned/mocked** HTTP so screens can ship against a frozen shape.

Repository methods are documented in [DATABASE.md](DATABASE.md) — those are the internal data API.

Status key: **Live** · **Partial** · **Mock / UI only** · **Planned**

---

## HealthKit

**Status: Live** for Zone 2 workout + HR samples. **Planned** for dietary writes.

File: [`HealthKitService.swift`](../HybridVital/Features/Training/Services/HealthKitService.swift)  
Session: [`WorkoutSessionManager.swift`](../HybridVital/Features/Training/Services/WorkoutSessionManager.swift)

### Authorization

| Direction | Types |
| --- | --- |
| Share | `heartRate`, `activeEnergyBurned`, `distanceWalkingRunning`, `workoutType` |
| Read | same |

`requestAuthorization()` throws `HealthKitServiceError.unavailable` if HK is missing (simulator copy explains a physical iPhone).

Location is requested separately (`LocationAuthorizer`) for outdoor run workouts.

### Workout session

- `HKWorkoutSession` + `HKLiveWorkoutBuilder`, activity outdoor run.
- Phases: idle → preparing → countdown → active / paused → ending.
- HR samples added to the builder at most every 5 seconds from BLE BPM.
- End: persist HK workout; UUID stored on `TrainingSession.healthKitWorkoutUUID`.

### Read API (used)

```swift
func fetchHeartRateSamples(from: Date, to: Date) async throws -> [HKQuantitySample]
```

### Dietary intake (planned, not coded)

Spec from [LOGGING_OVERVIEW](LOGGING_OVERVIEW.md): on food save, optimistic write of energy + macros to HealthKit dietary types. Contract when implemented:

| HK type (planned) | Source field |
| --- | --- |
| Dietary energy | `nutrition.calories` |
| Protein / carb / fat | grams |
| Fiber, sugar, sodium, cholesterol | matching fields |

Failures must not roll back SwiftData (local-first). Surface a non-blocking banner.

---

## Bluetooth LE — heart rate

**Status: Live**

File: [`HeartRateBLEService.swift`](../HybridVital/Features/Training/Services/HeartRateBLEService.swift)

| Item | Value |
| --- | --- |
| Service UUID | `180D` (Heart Rate) |
| Transport | Core Bluetooth central |
| Threading | Private queue; UI must **not** observe the service |
| UI contract | `snapshot() -> HeartRateSnapshot` polled ~1s from `LiveTrackerViewModel` |

`HeartRateSnapshot`: `bpm`, `status` (`HeartRateMonitorStatus`), `discovered` devices, `lastError`.

`HeartRateMonitorStatus`: idle, unauthorized, poweredOff, scanning, connecting(name), connected(name), unavailable.

Last device UUID stored in `UserDefaults` key `lastHeartRateMonitorUUID`.

Info.plist: `NSBluetoothAlwaysUsageDescription`. Background: `bluetooth-central`.

**Product copy:** no COROS account. Band talks BLE; Apple Health stores the workout.

---

## Live Activities & widgets

**Status: Live** (start widget does not deep-link into a session)

| Piece | File |
| --- | --- |
| Attributes | `HybridVitalShared/Zone2ActivityAttributes.swift` |
| Island + lock screen | `HybridVitalWidgets/Zone2LiveActivity.swift` |
| Home widget | `Zone2StartWidget.swift` |
| App controller | `Zone2LiveActivityController.swift` |
| Lap intent | `ToggleLapIntent.swift` |
| IPC | `LapToggleChannel.swift` |

**App Group:** `group.com.hybridvital.HybridVital`

**Lap toggle protocol**

1. Intent or island button → `LapToggleChannel.post()`
2. Enqueue timestamp in app-group `UserDefaults` key `pendingLapToggles`
3. Darwin notification `com.hybridvital.zone2.toggleLap`
4. App `LiveTrackerBridge.viewModel` drains queue and toggles jog/walk

This is the only supported extension → UI callback. Do not add a new singleton bridge without documenting it here.

Plist: `NSSupportsLiveActivities`, `NSSupportsLiveActivitiesFrequentUpdates`.

---

## Grok Vision (meal parse)

**Status: Mock / UI only** — shutter and PhotosPicker open review with `DemoCatalog.visionParse`.

### Planned request

| Field | Notes |
| --- | --- |
| Image | JPEG/HEIC from camera or library |
| Context | cooking skill, cholesterol flag, recent likes (optional) |
| Response format | JSON matching `CatalogFood` / `NutritionInfo` |

### Planned response (frozen for UI)

Matches `DemoCatalog.CatalogFood`:

```
name, brand?, mealType, source = grokVision,
quantity, unit, nutrition (NutritionInfo),
confidence: 0...1, notes?
```

### UI rules (already enforced)

- Show confidence badge
- User **must** be able to edit every macro before save
- High cholesterol → `CholesterolAwarenessBanner` (≥ 100 mg in `FoodLoggingTargets`)
- “Looks off — search instead” → `FoodSearchView`
- Save writes `FoodEntry.source = .grokVision` + `confidenceScore`

Errors: if the client fails, keep the user on the capture screen with a retry; do not auto-save.

---

## USDA FoodData Central

**Status: Mock / UI only** — `FoodSearchView` filters `DemoCatalog.searchResults` where `source == .usda`.

### Planned client

- Base: `https://api.nal.usda.gov/fdc/v1`
- Auth: `api_key` query param (store in Keychain / config, never in git)
- Search: `GET /foods/search?query=&pageSize=`
- Detail: `GET /food/{fdcId}`

### Map into app

| USDA | HybridVital |
| --- | --- |
| description | `foodName` |
| brandOwner | `brandName` |
| serving size | `quantity` + `unit` |
| protein/carb/fat/fiber/energy | `NutritionInfo` |
| — | `source = .usda` |

Client-side filter in the mock is `localizedCaseInsensitiveContains` on name/brand.

---

## Open Food Facts

**Status: Mock / UI only** — rows with `source == .openFoodFacts`.

Planned: `openfoodfacts-swift` SPM (not in the Xcode project yet). Same `CatalogFood` mapping; `source = .openFoodFacts`.

Barcode is not in the UI. When added, it is a search method, not a new tab.

---

## Voice log

**Status: Mock / UI only**

No Speech / SFSpeechRecognizer. `VoiceLogView` simulates listening, then a transcript field defaulting to a yogurt bowl, then `FoodAnalysisReviewSheet` with `source = .voice`.

Planned: on-device speech → same review sheet. Mic usage string not in Info.plist until live.

---

## Grok Coach

**Status: Mock / UI only**

VM: [`CoachChatViewModel`](../HybridVital/Features/Coach/ViewModels/CoachChatViewModel.swift)

### Planned live call

- Model: xAI Grok, streaming + tool calling ([TECH_STACK](TECH_STACK.md))
- System: conservative health, never diagnose, cholesterol-aware if profile flag
- Tools (planned): today’s nutrition, recent sessions, profile, rolling 7–30d metrics
- On-device fallback: Apple Foundation Models if specified later

### Current mock contract

1. Seed transcript from `DemoCatalog.conversation` (system + user + coach)
2. Optional `initialPrompt` appends a user message
3. `Task.sleep` ~1.1s “thinking”
4. Intent router on keywords: protein, fiber/lunch, zone/z2, energy, else general
5. Reply always cites chips + low-cook + not-a-diagnosis

No persistence of messages. Memory toggles are in-memory on `CoachMemorySettingsView`.

Automatic context layers: [AI_MEMORY_SYSTEM.md](AI_MEMORY_SYSTEM.md).

---

## Haptics

**Status: Live** — `HapticCoach` during Zone 2 (Z3 entry flash). Not a network API; listed so screens know it is training-only.

---

## Export / share

**Status: Live** for sessions; **Partial** for weekly report (ShareLink of a string).

`SessionExport`: JSON (full session) or CSV (HR + laps) to temp files, `ShareSheet` (UIKit).

Weekly report: `ShareLink(item: DemoCatalog.weeklyReportSummary)` — not a generated PDF.

Privacy screen “Export my data” is an **alert placeholder**.

---

## Photos

**Status: Partial** — `PhotosPicker` on library path; picker item is ignored and the same vision fixture is shown.

Plist: `NSPhotoLibraryUsageDescription`. No camera permission (capture is a stub viewfinder).

---

## Supabase (planned)

Not in the project. Intended: Auth, Postgres mirror of SwiftData, Realtime optional, **pgvector** for Coach RAG.

| Topic | Intent |
| --- | --- |
| Sync | Background, after local save; last-write + `updatedAt` |
| RLS | Per-user row isolation |
| Secrets | Never in the client beyond anon key; user JWT |
| PHI | No production sync until legal path is explicit |

Do not add the SDK until DATABASE has a sync field (`remoteId`, `dirty`).

---

## StoreKit 2 (planned)

Free vs Premium AI Coach. No product IDs yet. Do not gate current Coach UI.

---

## Adding a new external API

1. Section on this page (status, request, response, errors)
2. Fixture in `DemoCatalog` or a `*Service`
3. Screen marked Mock until the client exists
4. Secrets: xcconfig / Keychain, gitignored
