# Documentation index

HybridVital’s knowledge base. Use it as the template for the next app: **playbook → architecture → frameworks → database → APIs → screens**.

| Doc | Layer |
| --- | --- |
| [PLAYBOOK.md](PLAYBOOK.md) | How we build a feature from intent to PR |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System shape, folders, shell, live vs planned |
| [FRAMEWORKS.md](FRAMEWORKS.md) | MVVM, theme, repos, demo, health copy |
| [DATABASE.md](DATABASE.md) | SwiftData schema + repository methods |
| [API.md](API.md) | HealthKit, BLE, widgets, Grok/USDA mocks, Supabase |
| [screens/README.md](screens/README.md) | Every screen |

### Legacy / topic notes

| Doc | Role |
| --- | --- |
| [TECH_STACK.md](TECH_STACK.md) | Original stack choices (iOS target in that file may lag the Xcode project) |
| [LOGGING_OVERVIEW.md](LOGGING_OVERVIEW.md) | Food-logging product philosophy |
| [AI_MEMORY_SYSTEM.md](AI_MEMORY_SYSTEM.md) | Coach memory layers |
| [DATA_MODELS.md](DATA_MODELS.md) | Stub — **use DATABASE.md** |
| [CURSOR_RULES.md](CURSOR_RULES.md) | Same as `.cursorrules` |
| [ARCHITECTURE..md](ARCHITECTURE..md) | Filename typo — **use ARCHITECTURE.md** |

---

## Screen template (copy into `docs/screens/<slug>.md`)

```markdown
# <Screen title>

**Status:** Live | Demo-backed | Stub
**Feature:** …
**File:** `HybridVital/Features/…`
**ViewModel:** none | `…ViewModel`
**Opened from:** …
**Opens:** …

## Purpose
## Layout
## Data
## Actions
## Persistence
## Protocol notes
## Future
```
