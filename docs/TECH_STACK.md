# Tech Stack

**Canonical architecture:** [ARCHITECTURE.md](ARCHITECTURE.md) · [API.md](API.md)

**Last Updated:** May 6, 2026 (Xcode project currently sets iOS 26.4; prefer the project file over this note for the deployment target.)


## Core Platform

- **Platform**: Native iOS (target iOS 18+)
- **Language**: Swift 6
- **UI Framework**: SwiftUI + Apple Charts framework
- **IDE**: Xcode 26+ (final) + Cursor Pro (primary development)

## Data & Persistence

- **Local Database**: SwiftData (primary)
- **Biometrics Source of Truth**: HealthKit (read/write)
- **Cloud Backend**: Supabase (PostgreSQL + Auth + Realtime + pgvector for RAG)
- **Offline Strategy**: Fully local-first with optimistic UI and background sync

## AI Layer

- **Primary LLM**: xAI Grok API (streaming + tool calling)
- **On-device Fallback**: Apple Intelligence / Foundation Models
- **Memory & Context**: Supabase pgvector + custom auto-learning layer
- **Multimodal**: Grok vision for meal photo parsing

## Architecture

- Modern MVVM using `@Observable` macro
- Feature-based folder structure
- Repository pattern for data access
- Actor-based services for concurrency safety

## Security & Compliance

- HIPAA-aware architecture from day one
- Phase 1: Strong encryption + RLS (no full HIPAA yet)
- Phase 2: Full HIPAA when accepting medical records

## Monetization

- StoreKit 2 Subscriptions (Free tier + Premium AI Coach tier)

## Development Tools

- Cursor Pro (main coding)
- Grok (architecture, review, user stories)
- Git + GitHub
