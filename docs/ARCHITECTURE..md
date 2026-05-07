# Architecture Decisions

## High-Level Approach

- **Local-First** with HealthKit as golden source
- **SwiftData** as the app’s source of truth for custom data
- **Supabase** as secure cloud mirror + AI memory store
- **Modern MVVM** with lightweight ViewModels

## Key Design Principles

- Ease of logging is non-negotiable
- Automatic context for AI Coach
- Secure by design (future HIPAA path)
- Scalable to millions eventually

## Data Flow

User → HealthKit + SwiftData (optimistic) → Background Sync → Supabase → AI Tools (RAG + live queries)

## Folder Structure

(See main README or project root)
