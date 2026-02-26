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

## Current Build Status
- Hybrid architecture validated on work PC: Docker orchestration + native FARO Scene execution.
- Ingest/extract + status/log artifact generation is working.
- Scene launch probe stage is validated (`scene_launch_probe_done`, `result: ok`).
- Filename validation rule locked: enforce prefix `YY-CC-PPP-CLIENT-##-##`; keep suffix flexible.

## Operating Mode (Build Mode)
- Execute in small increments (1–2 steps max).
- Validate output after each step before proceeding.
- Keep stages explicit and machine-readable (`stage`, `result`, `reason_code`, artifacts).

## Roadmap & Execution Docs
- `ROADMAP_AUTONREG.md` — milestone plan from probe stage to governed full autonomy.
- `TODO_EXECUTION.md` — active execution checklist and Monday checkpoint plan.
- `DEPLOY_TOMORROW.md` — practical bring-up and deployment checklist.
- `PROJECT_SPEC_V1.md` — v1 scope/spec baseline.

## Immediate Next Steps
1. Re-run baseline `run_job.ps1` and capture fresh `status.json`.
2. Add and validate `registration_stub` stage transition.
3. Implement first safe SOP-mapped post-probe action.
4. Add first human validator gate with structured decision writeback.
5. Push milestone checkpoint with updated runbook/docs.
