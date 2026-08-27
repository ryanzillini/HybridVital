# Frameworks and protocols

Reusable kits. If you invent a new pattern in a feature, either promote it here or delete it.

See [PLAYBOOK](PLAYBOOK.md) for the build sequence and [ARCHITECTURE](ARCHITECTURE.md) for where files live.

---

## 1. Modern MVVM (`@Observable`)

**When to add a ViewModel**

- Session or chat lifecycle
- Validation + save
- Combining several repository calls into one screen state
- Mock streaming / delayed replies

**When not to**

- Static settings forms with a handful of `@State` fields (Goals, Notifications)
- Pure display of a snapshot passed in (Session summary)

**Shape**

```swift
@Observable
@MainActor
final class ExampleViewModel {
    let services: AppServices
    var errorMessage: String?
    init(services: AppServices) { ... }
    func refresh() { ... }
}

struct ExampleView: View {
    let services: AppServices
    @State private var viewModel: ExampleViewModel
    init(services: AppServices) {
        self.services = services
        _viewModel = State(initialValue: ExampleViewModel(services: services))
    }
}
```

Create the VM in the view `init`, not in `body`. Use `@Bindable var viewModel = viewModel` only when you need `$viewModel.field`.

**Existing VMs:** `LiveTrackerViewModel`, `DashboardViewModel`, `OnboardingFlowViewModel`, `QuickFoodLogViewModel`, `FoodAnalysisReviewViewModel`, `CoachChatViewModel`, `ProgressHubViewModel`.

---

## 2. Repository pattern

Repositories are the **only** SwiftData API the UI uses.

- `@Observable final class`
- Hold `ModelContext`
- Methods named for jobs, not tables
- `print("[Feature] …")` on failure today — replace with `os.Logger` when observability lands (do not scatter `Logger` in views first)

Pass `AppServices` or a single repo through `init`. No service locator besides that bag.

---

## 3. Feature folders

`App / Core / Features`. New product surface = new folder under `Features/`, not a file dumped in `App/`. Dashboard used to live in `RootView`; that was a mistake — do not put feature UI back in `App/`.

Shared widgets/Live Activity types go in `HybridVitalShared` so the extension can compile without the app target.

---

## 4. Design system (`HVTheme`)

File: [`HybridVital/Core/UI/HVTheme.swift`](../HybridVital/Core/UI/HVTheme.swift)

| Token | Use |
| --- | --- |
| `HVTheme.background` | Black canvas |
| `HVTheme.card` / `cardElevated` | Surfaces (`white.opacity(0.06/0.08)`) |
| `HVTheme.accent` | Green CTAs, Zone 2, tab tint |
| `HVTheme.coach` | Mint — Coach only |
| `HVTheme.calories/protein/carbs/fat/fiber` | Macro coloring (keep consistent across Home, Food, Progress) |
| `HVTheme.warning` / `danger` | Cholesterol flags, destructive |
| `radiusS/M/L`, `pagePadding`, `stackSpacing` | 12 / 16 / 24 · 16 · 20 |

**Controls:** `HVCard`, `HVSectionHeader`, `HVMetricTile`, `HVPrimaryButton` (green, black label, height 56), `HVQuickActionTile`, `HVProgressBar`, `HVInsightBanner`, `HVDisclaimer`, `HVEmptyState`.

**Modifiers:** `.hvScreen()` (hidden scroll chrome, black, dark, green tint), `.hvInlineNav()`.

**Zones:** [`ZonePalette`](../HybridVital/Core/UI/ZonePalette.swift) — Z1 gray, Z2 green, Z3 yellow, Z4 orange, Z5 red. Do not duplicate this enum in feature files.

Primary CTA pattern from Training: green fill, **black** text, 16pt continuous rounded rect.

---

## 5. Demo catalog

File: [`HybridVital/Core/Demo/DemoCatalog.swift`](../HybridVital/Core/Demo/DemoCatalog.swift)

Fixtures for:

- Week/month macros and training days
- Food search + vision parse + sample meals
- Coach conversation, prompts, insights, memories
- Weekly report copy

**Protocol:** screens that would look empty on a fresh install **must** fall back here and caption “Sample …”. When SwiftData has rows, hide the caption.

Do not put one-off lorem arrays in views.

---

## 6. Logging (product + engineering)

**Product:** logging food/check-ins must feel effortless ([LOGGING_OVERVIEW](LOGGING_OVERVIEW.md)). Photo-first, always editable, confidence + mandatory review for vision.

**Engineering:** today `print("[Feature] …")`. Target: `Logger` subsystem `com.hybridvital` with categories `training`, `food`, `coach`, `sync`. User-visible errors for save failures (food save currently can fail silently).

---

## 7. Conservative health protocol

Every Coach, Progress, and cholesterol-related food surface includes `HVDisclaimer` or equivalent.

Allowed: pattern language (“fiber dip days lined up with lower energy **in this sample**”).

Forbidden: diagnose, prescribe meds, tell the user to skip clinician care, claim HIPAA certification.

Familial hypocholesterolemia on the profile **tightens** copy; it does not unlock medical advice.

---

## 8. Accessibility baseline

Minimum on every interactive control:

- Icon-only buttons: `.accessibilityLabel`
- Session/meal rows that look like buttons: `.accessibilityAddTraits(.isButton)`
- Hero metrics: combined label (“Zone 2 183 of 150 minutes”)

Dynamic Type: prefer semantic fonts; hero numbers use `HVFont.heroMetric` + `minimumScaleFactor` on tiles.

We are **not** at enterprise a11y yet. New screens should not ship with *zero* labels.

---

## 9. Previews

In-memory `ModelContainer` for all five `@Model` types + `AppServices` or the feature repo. Dark scheme. See `DashboardView` and `ZoneSettingsView` previews.

---

## 10. Copy / naming

- User-facing: “Zone 2”, “Coach”, “log”, not “persist”, “ingest”, “CRUD”
- Types: `FoodEntry` not `MealDTO` in the app layer
- Files: `*View.swift`, `*ViewModel.swift`, `*Repository.swift`, `*Service.swift`
