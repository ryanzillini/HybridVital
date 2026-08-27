# Coach chat

**Status:** Stub  
**Feature:** Coach  
**File:** [`CoachChatView.swift`](../../HybridVital/Features/Coach/Views/CoachChatView.swift)  
**ViewModel:** [`CoachChatViewModel`](../../HybridVital/Features/Coach/ViewModels/CoachChatViewModel.swift)  
**Opened from:** Ask Coach, suggested prompts, insight “Ask about this”  
**Opens:** none  

## Purpose

Threaded chat with pinned automatic context. Mock Grok: delay + canned conservative replies.

## Layout

Pinned system context card, transcript bubbles (`CoachMessageBubble`), thinking row, composer, disclaimer.

`init(services:initialPrompt:)`. `.task` seeds the prompt if present.

## Data

Starts as `DemoCatalog.conversation`. New messages stay in VM memory. Intent router: protein, fiber, zone 2, energy, general — see [API.md](../API.md#grok-coach).

## Persistence

None. Closing the screen drops the thread (except what was in the demo seed).

## Protocol notes

- Always mention clinician for lipids/meds/GI.
- Cite live chips (protein/fiber/Z2) in replies so the “already knows” promise is visible.
- Streaming later should keep the thinking row, then append tokens — don’t redesign the bubble first.
