# HybridVital

Native iOS health companion: Zone 2 training, effortless food logging, and an AI Coach that already knows the day.

This repo is also the **reference implementation** for how we design, persist, integrate, and ship screens. Start in documentation, not in a random Swift file.

## Documentation map

| Layer | Read this | What it is |
| --- | --- | --- |
| How we build | [`docs/PLAYBOOK.md`](docs/PLAYBOOK.md) | Front-to-end protocol for every new feature |
| System shape | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Local-first, folders, data flow, tab shell |
| Reusable kits | [`docs/FRAMEWORKS.md`](docs/FRAMEWORKS.md) | MVVM, theme, DI, logging, health copy |
| Persistence | [`docs/DATABASE.md`](docs/DATABASE.md) | SwiftData schema, repositories, queries |
| Edges | [`docs/API.md`](docs/API.md) | HealthKit, BLE, widgets, planned Grok / USDA / Supabase |
| UI inventory | [`docs/screens/README.md`](docs/screens/README.md) | Every screen, with a link to its spec |

**Rule:** a feature is not done until its screen docs exist and the repository/API contracts are updated.

## App at a glance

- **Platform:** SwiftUI, iOS 26+, SwiftData, HealthKit
- **Shell:** onboarding → five tabs (Home, Train, Food, Coach, Progress) + Profile stack
- **Differentiator:** AI Coach with automatic context (mock chat today, Grok later)
- **Visual:** dark-first, green accent, rounded hero metrics

## Run

Open `HybridVital.xcodeproj` in Xcode 26. Target a physical iPhone for BLE + HealthKit Zone 2. Simulator is enough to walk the rest of the UI (demo catalog fills empty data).
