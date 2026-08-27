# Screen catalog

Every user-visible destination. Status:

- **Live** — reads/writes SwiftData or Apple APIs as described
- **Demo-backed** — UI complete; empty store or missing API uses `DemoCatalog`
- **Stub** — interaction works, backend is simulated (camera, voice, Grok)

New screens: copy the template in [`docs/README.md`](../README.md), add a row here, link the file. Same PR as the Swift.

## App

| Screen | Status | Doc |
| --- | --- | --- |
| App shell / tabs | Live | [app-shell.md](app-shell.md) |
| Onboarding | Live (profile save) | [onboarding.md](onboarding.md) |

## Home

| Screen | Status | Doc |
| --- | --- | --- |
| Dashboard | Demo-backed | [dashboard.md](dashboard.md) |
| Daily check-in | Live | [daily-check-in.md](daily-check-in.md) |
| Log-meal method picker | Live navigation | [food-log-method.md](food-log-method.md) |

## Train

| Screen | Status | Doc |
| --- | --- | --- |
| Training hub | Demo-backed week card | [training-hub.md](training-hub.md) |
| Live Zone 2 tracker | Live | [live-tracker.md](live-tracker.md) |
| Session summary | Live | [session-summary.md](session-summary.md) |
| Heart rate zones | Live | [zone-settings.md](zone-settings.md) |

## Food

| Screen | Status | Doc |
| --- | --- | --- |
| Food hub | Demo-backed | [food-hub.md](food-hub.md) |
| Photo / library capture | Stub | [photo-capture.md](photo-capture.md) |
| Vision review | Demo-backed save | [food-review.md](food-review.md) |
| Food search | Stub catalog | [food-search.md](food-search.md) |
| Voice log | Stub | [voice-log.md](voice-log.md) |
| Manual / quick log | Live | [quick-food-log.md](quick-food-log.md) |
| Food history | Demo-backed | [food-history.md](food-history.md) |
| Entry detail | Live | [food-entry-detail.md](food-entry-detail.md) |

## Coach

| Screen | Status | Doc |
| --- | --- | --- |
| Coach home | Demo-backed | [coach-home.md](coach-home.md) |
| Chat | Stub | [coach-chat.md](coach-chat.md) |
| Insight detail | Demo-backed | [insight-detail.md](insight-detail.md) |
| Daily briefing | Demo-backed | [daily-briefing.md](daily-briefing.md) |
| Memory settings | Stub (local toggles) | [coach-memory.md](coach-memory.md) |

## Progress

| Screen | Status | Doc |
| --- | --- | --- |
| Progress hub | Demo-backed | [progress-hub.md](progress-hub.md) |
| Macro trends | Demo-backed | [macro-trends.md](macro-trends.md) |
| Training trends | Demo-backed | [training-trends.md](training-trends.md) |
| Energy & recovery | Demo-backed | [energy-trends.md](energy-trends.md) |
| Weekly report | Demo-backed | [weekly-report.md](weekly-report.md) |

## Profile

| Screen | Status | Doc |
| --- | --- | --- |
| Profile home | Live | [profile-home.md](profile-home.md) |
| Goals | Live | [goals.md](goals.md) |
| Food preferences | Live | [preferences.md](preferences.md) |
| Notifications | Partial | [notifications.md](notifications.md) |
| Privacy & data | Stub export/delete | [privacy.md](privacy.md) |
| About | Live (static) | [about.md](about.md) |

## Widgets

| Surface | Status | Doc |
| --- | --- | --- |
| Live Activity / Dynamic Island / start widget | Partial | [widgets.md](widgets.md) |

## Graph (happy path)

```
Onboarding → Home
               ├─ Zone 2 fullScreen → Tracker → Session summary
               ├─ Log meal sheet → Capture | Search | Voice | Manual → Review → SwiftData
               ├─ Check-in sheet
               └─ Profile → Goals / Prefs / Zones / Privacy / About
Food tab  → same log methods + History → Detail
Coach tab → Briefing | Insights → Chat | Memory
Progress  → Macro | Training | Energy | Weekly report
```
