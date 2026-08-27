# Coach memory settings

**Status:** Stub (in-memory toggles)  
**Feature:** Coach  
**File:** [`CoachMemorySettingsView.swift`](../../HybridVital/Features/Coach/Views/CoachMemorySettingsView.swift)  
**ViewModel:** none  
**Opened from:** Coach home Memory row  
**Opens:** none  

## Purpose

User override of automatic memory: mute layers, forget learned patterns. Privacy note: local-first, no upload.

## Layout

Inset grouped list: explainer, sections Permanent / Rolling / Learned, Forget on learned items, privacy footer, disclaimer.

State: `@State memories = DemoCatalog.memories`. Forget removes from the array only.

## Persistence

None. Restart restores catalog.

## Protocol notes

Matches [AI_MEMORY_SYSTEM.md](../AI_MEMORY_SYSTEM.md). Next: `@Model MemoryItem` or flags on profile + a learned-pattern entity. Forget must be user-initiated (never silent).
