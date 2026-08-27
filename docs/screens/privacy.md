# Privacy & data

**Status:** Stub (export/delete alerts only)  
**Feature:** Profile  
**File:** [`PrivacySettingsView.swift`](../../HybridVital/Features/Profile/Views/PrivacySettingsView.swift)  
**Opened from:** Profile  

## Purpose

Explain local-first, HealthKit as biometric source, future Supabase mirror. HIPAA-*aware* language without claiming certification.

## Actions

Export → alert (no file). Delete local data → confirm alert (**does not wipe** SwiftData).

## Protocol notes

Wire export to a real archive using the same temp-file pattern as `SessionExport`. Delete must be explicit and listed here before it actually `delete`s models.
