# Core/Models

**Canonical docs:** [DATABASE.md](../../../docs/DATABASE.md) · [PLAYBOOK.md](../../../docs/PLAYBOOK.md)

**File:** `CoreModel.swift` — all `@Model` types, enums, and value types.

**Rules**

- Every persisted type = `@Model`
- Value types for `NutritionInfo`, targets, zones
- Enums expose `displayName` (and `systemImage` when chipped)
- Schema changes are breaking — update DATABASE.md in the same PR
