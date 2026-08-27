# Build playbook — HybridVital

This is the protocol for building **any** feature in this app, and the template for building the next app. Follow it in order. Skip a step only if you can point to an existing artifact that already covers it.

HybridVital is local-first SwiftUI, but the **sequence** is framework-agnostic: intent → data → contracts → screens → wire → document.

---

## 0. Non-negotiables (product)

Copy these into every feature spec. If a screen violates one, it is not done.

1. **Ease of logging** — food and check-ins should be reachable in one or two taps.
2. **Automatic context for Coach** — never ask the user to recap macros, Zone 2, or profile.
3. **Local-first** — SwiftData is the app source of truth. HealthKit is the biometric golden source. Cloud is a future mirror, not a blocker.
4. **Conservative health copy** — no diagnoses, no medication changes, clinician language on Coach / Progress / food cholesterol flags.
5. **Dark-first UI** — `HVTheme`, not `Color(.systemBackground)`.
6. **Documented screens** — every destination in `docs/screens/` using the template in [`screens/README.md`](screens/README.md).

Project rules live in [`.cursorrules`](../.cursorrules) and [`CURSOR_RULES.md`](CURSOR_RULES.md).

---

## 1. Write the intent (before code)

Capture, even if short:

| Field | Example |
| --- | --- |
| Job to be done | Log a meal in under 15 seconds |
| Primary user | Ryan, low cook skill, cholesterol-aware |
| Success | Entry in `DailyLog.foodEntries` today, visible on Home + Food |
| Failure modes | Silent save, no review of vision, medical overclaim |
| Live vs demo | Save hits SwiftData; vision/search may use `DemoCatalog` until APIs exist |

Do **not** start in a View file.

---

## 2. Data model first

Edit [`HybridVital/Core/Models/CoreModel.swift`](../HybridVital/Core/Models/CoreModel.swift) (or add a `@Model` there — one schema file until it hurts).

Checklist:

- Persist with `@Model`. Prefer structs (`NutritionInfo`, `MacroTargets`) for nested values.
- Enums: `String, Codable, CaseIterable, Identifiable` + `displayName` (and `systemImage` if the UI chips them).
- Ryan defaults belong on `UserProfile.init()`, not hardcoded in a single view.
- Schema changes are breaking — note them in [`DATABASE.md`](DATABASE.md).
- If Coach will need it later, put it on `DailyLog` or `UserProfile` now rather than inventing a parallel store.

Then update [`DATABASE.md`](DATABASE.md) in the same PR.

---

## 3. Repository = the internal API

Views do not own `ModelContext` queries. They talk to a feature repository.

| Feature | Type | File |
| --- | --- | --- |
| Food + check-in + day hub | `FoodLoggingRepository` | `Features/FoodLogging/Repository/` |
| Profile + zones + sessions | `TrainingRepository` | `Features/Training/Repository/` |

**Protocol for a new repository method:**

1. Name it after the user job (`saveDailyCheckIn`, `recentSessions`), not after SQL.
2. Swallow or surface errors consistently (today: `print` + empty/optional; target: user-visible + `Logger`).
3. Keep it `@Observable` if the UI should refresh from the same instance.
4. Document the method in [`DATABASE.md`](DATABASE.md) (signature, predicates, side effects).
5. If it is a *future* network call, still write the method shape in [`API.md`](API.md) and return demo data until the client exists.

`AppServices` is the composition root: `{ food, training }`. Pass that (or the one repo a tab needs) into views. Do not add a third global singleton without a doc note.

---

## 4. External API contract (even if mocked)

If the screen will eventually call Grok, USDA, HealthKit, BLE, or Supabase:

1. Add a section to [`API.md`](API.md): endpoint/types, request, response, error, auth, what the UI does on failure.
2. Implement a **fixture** in `DemoCatalog` or a `*Service` that returns that shape.
3. Mark the screen **Demo-backed** or **Stub** in its screen doc until the live client exists.
4. Never block the screen inventory on the live API. UI + contract first, client second.

This is how Food vision, search, voice, and Coach chat shipped as a walkable product.

---

## 5. Screen inventory

List every destination before building:

- Tab root vs sheet vs fullScreenCover vs push
- Init signature (always explicit: `DashboardView(services:)`)
- What is live vs `DemoCatalog`
- Empty, loading, error, sample-data states

Add a stub row to [`screens/README.md`](screens/README.md), then a file under `docs/screens/` **in the same change as the SwiftUI file**.

---

## 6. Design system, then view

Use [`FRAMEWORKS.md`](FRAMEWORKS.md) tokens:

- `HVTheme`, `HVCard`, `HVPrimaryButton`, `HVMetricTile`, `HVProgressBar`, `HVInsightBanner`, `HVDisclaimer`, `HVEmptyState`
- `.hvScreen()` + `.preferredColorScheme(.dark)`
- Macro colors from `HVTheme` (not one-off blues)
- Zone colors from `ZonePalette`

Layout pattern for hubs: `NavigationStack` → `ScrollView` → `VStack(spacing: HVTheme.stackSpacing)` → cards → disclaimer.

ViewModels: `@Observable` + `@State` in the view, created in `init`. Use a VM when there is lifecycle, validation, or async; view-local `@State` is fine for sheets with three fields.

---

## 7. Demo fallback (portfolio + empty-state)

If a query returns empty, **show sample UI** with a “Sample day/week/data” caption rather than a barren screen. Home, Food, Progress, and Coach all do this via `DemoCatalog`.

When real rows exist, hide the sample caption and bind to SwiftData.

Do not seed the real store with fake meals unless the user asks. Overlay/catalog is enough.

---

## 8. Wire navigation last

`RootView` owns:

- `ModelContext` → `AppServices`
- `@AppStorage("hasCompletedOnboarding")`
- Tab bar

Features own their `NavigationStack` (tab roots) or are pushed/sheeted from a parent that already has one. Do not nest extra stacks on push destinations (Profile is a push from Home — no inner `NavigationStack`).

---

## 9. Document in the same PR

Minimum for a feature PR:

1. [`DATABASE.md`](DATABASE.md) if schema or repo methods changed
2. [`API.md`](API.md) if an edge was added or mocked
3. One screen file per new destination
4. Catalog row in [`screens/README.md`](screens/README.md)

Architecture/frameworks only change when the *way we build* changes.

---

## 10. Feature folder recipe

```
HybridVital/Features/<Name>/
  Views/           # SwiftUI screens
  ViewModels/      # @Observable, only if non-trivial
  Repository/      # SwiftData access
  Services/        # HealthKit, BLE, future HTTP
  Utilities/       # formatters, export
  <Name>_README.md # optional pointer back to docs/
```

Shared UI → `Core/UI`. Shared models → `Core/Models`. Widget types → `HybridVitalShared`.

---

## Definition of done

- [ ] Intent written (even a paragraph in the screen doc)
- [ ] Models + repository methods documented
- [ ] API contract documented (live or planned)
- [ ] Screen uses `HVTheme` and `HVDisclaimer` where health claims could appear
- [ ] Empty state or DemoCatalog fallback
- [ ] `docs/screens/<slug>.md` exists and is linked from the catalog
- [ ] Navigation is reachable from the tab shell or a documented deep path
