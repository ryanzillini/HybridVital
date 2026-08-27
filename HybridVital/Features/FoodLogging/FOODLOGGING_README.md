# FoodLogging Feature

**Canonical docs**

- Product philosophy: [LOGGING_OVERVIEW.md](../../../docs/LOGGING_OVERVIEW.md)
- Schema + repo: [DATABASE.md](../../../docs/DATABASE.md)
- Vision / USDA / voice contracts: [API.md](../../../docs/API.md)
- Screens: [docs/screens/README.md](../../../docs/screens/README.md) (Food section)

**Code**

| Path | Role |
| --- | --- |
| `Repository/FoodLoggingRepository.swift` | Today log, CRUD, check-in, history |
| `FoodLogMethod.swift` | Camera / library / search / voice / manual |
| `Views/` | Hub, capture, review, search, voice, quick log, history, detail |
| `Views/FoodLoggingSupport.swift` | Targets, rings, meal rows, cholesterol banner |

**Status:** Manual save/delete are live SwiftData. Photo, search, and voice are UI + `DemoCatalog` until Grok/USDA/OFF clients exist. HealthKit dietary writes are specified, not implemented.
