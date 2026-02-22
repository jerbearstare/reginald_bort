# Reginald_bort

Auto-registration orchestration system for FARO Scene workflows.

## Vision
Reginald_bort monitors incoming RAW scan uploads, runs a registration pipeline, performs QA checks, and publishes processed outputs + notes.

## v1 Scope (Lean)
- Single-project pipeline
- Trigger on Dropbox tag/folder (`RAW`)
- Preprocess scans
- Run registration
- Generate QA slices/screens
- Human pass/fail gate
- Post-process + export (RCS + notes)
- Project closeout upload + summary

## Core Agents
- Overseer
- Project Agent
- Registration Agent
- Checking Agent (human-in-the-loop)

## Immediate Next Steps
1. Lock folder/data contract
2. Define pipeline states + pass/fail gates
3. Build first runner script (local, manual trigger)
4. Add notification templates
5. Validate with 3-4 real projects
