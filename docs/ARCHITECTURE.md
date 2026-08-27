# Architecture — HybridVital

**Status:** implemented local-first iOS app with a walkable product shell. Cloud, Grok, and dietary HealthKit writes are designed, not fully live.

Related: [PLAYBOOK](PLAYBOOK.md) · [FRAMEWORKS](FRAMEWORKS.md) · [DATABASE](DATABASE.md) · [API](API.md) · [screens](screens/README.md)

---

## Approach

```
User
  → SwiftUI (tabs + sheets)
    → AppServices { FoodLoggingRepository, TrainingRepository }
      → SwiftData (app source of truth)
      → HealthKit (biometric golden source, Zone 2 writes)
      → Core Bluetooth (COROS HR band, polled snapshots)
      → DemoCatalog (fixtures when store is empty or API is absent)
        → future: background sync → Supabase (Postgres + pgvector)
        → future: Grok (vision, coach tools, streaming)
```

**Local-first:** the app is useful with no network. Optimistic UI is the default. Supabase is a *mirror and memory store*, not the runtime dependency.

**HealthKit:** workouts, HR samples, energy, distance for Zone 2. Dietary intake writes are specified, not implemented.

**AI Coach:** differentiator. Context is assembled from profile + rolling logs automatically. Chat is canned/`DemoCatalog` until Grok tool-calling lands. See [AI_MEMORY_SYSTEM.md](AI_MEMORY_SYSTEM.md) and [API.md](API.md#grok-coach).

---

## Folder structure

```
HybridVital/                 # main app (synchronized Xcode folder)
  App/                       # @main, RootView (composition + tabs)
  Core/
    Models/                  # SwiftData @Model + value types (one file)
    Persistence/             # SwiftDataContainer actor (unused by @main today)
    UI/                      # HVTheme, ZonePalette, shared controls
    Demo/                    # DemoCatalog fixtures
    AppServices.swift        # DI bag
  Features/
    Onboarding/
    Dashboard/
    Training/                # Views, ViewModels, Repository, Services, Utilities
    FoodLogging/
    Coach/
    Progress/
    Profile/

HybridVitalShared/           # app + widget: IntervalKind, Live Activity attrs, lap channel
HybridVitalWidgets/          # Live Activity + start widget
docs/                        # this knowledge base
```

Xcode uses `PBXFileSystemSynchronizedRootGroup` — files under `HybridVital/` are picked up automatically. No `pbxproj` membership edits for new Swift files.

---

## App shell

[`HybridVitalApp`](../HybridVital/App/HybridVitalApp.swift) creates a `ModelContainer` for:

`UserProfile`, `DailyLog`, `FoodEntry`, `TrainingSession`, `WorkoutInterval`

and injects it with `.modelContainer`. `RootView` then:

1. Builds `AppServices` from `@Environment(\.modelContext)`
2. If `AppStorage("hasCompletedOnboarding")` is false → `OnboardingFlowView`
3. Else → `TabView` with five roots

| Tab | Root view | Owns |
| --- | --- | --- |
| Home | `DashboardView(services:)` | nutrition snapshot, check-in, meal entry, profile push |
| Train | `TrainingHubView(repository:)` | Zone 2 start, history, zones sheet |
| Food | `FoodLogHubView(repository:)` | all log methods, today, history |
| Coach | `CoachHomeView(services:)` | briefing, insights, chat, memory |
| Progress | `ProgressHubView(services:)` | charts + weekly report |

Profile is **not** a tab. It is pushed from Home’s toolbar.

`SwiftDataContainer` (actor) duplicates container setup and is **not** used by `@main`. Treat `HybridVitalApp` as canonical until the actor is wired.

---

## Layering

| Layer | Responsibility | May import |
| --- | --- | --- |
| Views | Layout, navigation, a11y | ViewModels, repos via init, `HVTheme`, `DemoCatalog` |
| ViewModels | Session lifecycle, validation, mock “LLM” | Repos, services, models |
| Repository | Fetch/save SwiftData | `ModelContext`, models |
| Services | HealthKit, BLE, Live Activity, haptics, zone math | Apple frameworks, models |
| Models | Schema + value types | Foundation, SwiftData |

Views must not issue ad-hoc `FetchDescriptor`s. Repositories must not import SwiftUI.

---

## Navigation patterns

| Pattern | Used for |
| --- | --- |
| `TabView` | Primary IA |
| `NavigationStack` per tab root | Push (history, trends, settings) |
| `.sheet` | Log methods, review, zones, check-in, insight, session detail |
| `.fullScreenCover` | Live Zone 2 tracker, camera stub |
| `@AppStorage` | Onboarding gate; Profile can flip it to replay |

Keep **one** stack on the path. Tab roots have a stack; push destinations (Profile, Goals, trends) should not wrap another `NavigationStack`.

---

## State

- **SwiftData** for anything that should survive launches (profile, meals, sessions, check-ins).
- **`@Observable` ViewModels** for live sessions (tracker, chat, dashboard refresh).
- **`DemoCatalog`** for walkable empty states and unimplemented APIs.
- **App Group `UserDefaults` + Darwin notify** for widget → app lap toggles ([API.md](API.md#widgets--live-activities)).

There is no coordinator/router type. Navigation is SwiftUI-native. If the graph grows, introduce a `Route` enum per feature — do not globalize until two features need the same deep link.

---

## Concurrency

- BLE lives off the main actor; UI **polls** `snapshot()` on a 1s clock (do not `@Observable` the CB manager).
- Workout + Live Activity updates are `@MainActor`.
- Repositories are main-context today (UI-driven). Background `ModelContext` exists on `SwiftDataContainer` but is unused.

---

## Security / compliance posture

Designed HIPAA-*aware*, not certified:

- Health data stays on-device first
- Conservative Coach copy
- Privacy screen explains local-first, HealthKit, future mirror
- No claim of HIPAA, diagnosis, or treatment

When Supabase lands: RLS, encryption, BAA, audit — see [API.md](API.md#supabase-planned).

---

## What is live vs designed

| Slice | Live in app | Spec only / mocked |
| --- | --- | --- |
| Zone 2 BLE + HealthKit workout | Yes | — |
| SwiftData meals / profile / sessions | Yes | — |
| Food vision / USDA / voice | UI + fixtures | Network clients |
| Coach chat + memory UX | UI + canned replies | Grok + pgvector |
| Dietary HealthKit writes | — | Spec |
| Supabase sync | — | Spec |
| StoreKit | — | Spec |

---

## Related stubs

The old file `ARCHITECTURE..md` (double dot) is a pointer. Do not add content there.
