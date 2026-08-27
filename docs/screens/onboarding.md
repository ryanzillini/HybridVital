# Onboarding

**Status:** Live (writes profile)  
**Feature:** Onboarding  
**File:** [`OnboardingFlowView.swift`](../../HybridVital/Features/Onboarding/Views/OnboardingFlowView.swift)  
**ViewModel:** `OnboardingFlowViewModel`  
**Opened from:** `RootView` when onboarding is incomplete  
**Opens:** none (calls `onFinished` → tabs)  

## Purpose

Five-page pager to set goals, health context, and personal targets without implying a medical intake.

## Layout

`NavigationStack` + progress bar + `TabView` page style (dots, no system index) + Continue / Enter CTA + Skip.

| Page | Content |
| --- | --- |
| 0 Welcome | Positioning: local-first, Zone 2, Coach, food. Disclaimer. |
| 1 Goals | `GoalType` chips (multi-select) |
| 2 Health | Familial hypocholesterolemia toggle, cooking skill, `HealthIssue` chips |
| 3 Targets | Protein / carbs / fat, weekly Zone 2 minutes, estimated kcal |
| 4 Ready | Recap + `HVDisclaimer` |

## Data

Seeds from `training.getOrCreateProfile()` (unknown persisted enum values are dropped). Skip still sets the AppStorage flag so the portfolio can enter the app immediately.

## Actions

| Control | Effect |
| --- | --- |
| Continue | `advance()` + `persist()` |
| Enter HybridVital / Skip | `persist()`, `hasCompletedOnboarding = true`, `onFinished()` |
| Chips / toggle / steppers | VM state; persist on advance/finish |

## Persistence

`TrainingRepository.saveProfile`:

- `primaryGoals`, `hasFamilialHypocholesterolemia`, `cookingSkillLevel`, `commonIssues`
- `targetMacros`, `weeklyZone2TargetMinutes`

Does not currently write `firstName` (profile default is `"Ryan"`).

## Protocol notes

- Pager + explicit persist is the pattern for multi-step setup.
- Skip is required for demos; production may require finish.
- Health page copy: “only log what a clinician has already told you.”

## Future

Name, birth date, resting HR, HealthKit permission primer as extra pages — not before screen docs exist.
