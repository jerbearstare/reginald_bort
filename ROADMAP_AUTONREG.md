# Reginald_bort — AutonReg Roadmap

_Last updated: 2026-02-26 (UTC)_

## Objective
Build from today’s validated probe pipeline into a governed, production-ready, increasingly autonomous FARO registration workflow with strong QA/QC and human oversight where needed.

---

## Current Baseline (already proven)
- Work-PC-first architecture is functioning (Docker orchestration + native FARO Scene execution).
- Ingest/extract + status/log artifacts are working.
- Scene launch probe is successful in `run_job.ps1` (`scene_launch_probe_done`, `result: ok`).
- Build Mode is locked: 1–2 steps at a time, verify every step.
- Filename rule locked: enforce prefix `YY-CC-PPP-CLIENT-##-##`; suffix is flexible.

---

## Phase Plan (Milestones + Acceptance Checkpoints)

## M1 — Deterministic Stage Engine
**Goal:** Clear, repeatable stage flow with machine-readable outcomes.

### Scope
- Formalize stage sequence:
  1. `ingest_done`
  2. `name_validation_done`
  3. `scene_launch_probe_done`
  4. `registration_stub_done`
  5. `export_stub_done`
  6. `job_complete`
- Standard status payload fields per stage:
  - `stage`
  - `result` (`ok`/`fail`/`pending_validation`)
  - `reason_code`
  - `timestamp_utc`
  - `artifacts`

### Acceptance checkpoint
- 3 consecutive reruns with expected stage progression and no ambiguous status output.

---

## M2 — SOP-Mapped Human Validator Loop
**Goal:** Convert SOP into explicit auto steps + human gates.

### Scope
- Parse SOP into categories:
  - **Auto now**
  - **Auto + human validation gate**
  - **Human-only for now**
- Introduce validator state:
  - `pending_validation`
- For each validation gate, produce checklist prompt:
  - what to inspect
  - expected pass criteria
  - reject conditions
- Record validator outcome:
  - `decision` (`approve`/`reject`/`approve_with_note`)
  - `validator`
  - `validated_at_utc`
  - `notes`

### Acceptance checkpoint
- 1 full job completed with at least one validator gate and a complete audit trail.

---

## M3 — Production Pilot (Human-in-the-loop)
**Goal:** Daily-usable operation with controlled risk.

### Scope
- Queue processing from v1 ingest path.
- Retry + safe-fail behavior by reason code.
- Operator runbook/checklist aligned to real workflow.
- Clean notifications for start/fail/complete.

### Acceptance checkpoint
- 10 pilot jobs processed.
- <10% rework outside known validator-gated steps.

---

## M4 — QA/QC Scoring (Rules-first)
**Goal:** Quantify quality before introducing ML decisions.

### Scope
- Capture structured QA metrics per job (example buckets):
  - registration quality indicators
  - scan coverage/completeness signals
  - timing anomalies
  - output consistency checks
- Build rules-based quality score:
  - `green` / `yellow` / `red`
- Alerting and report surface for reviewers.

### Acceptance checkpoint
- QA score aligns with human judgment over 20+ jobs.

---

## M5 — Semi-Autonomous Operations
**Goal:** Human only handles uncertainty/exceptions.

### Scope
- Auto-pass `green` jobs.
- Route `yellow/red` jobs to validator queue.
- Add reason-code playbooks for common failures.

### Acceptance checkpoint
- >60% jobs complete with no manual touch, without quality regression.

---

## M6 — Full AutonReg (Governed)
**Goal:** OpenClaw-orchestrated end-to-end autonomous operations.

### Scope
- OpenClaw owns scheduling/watch, orchestration, status fanout, notifications, reporting.
- Human role shifts to exception management and periodic QA review.
- Governance controls:
  - audit log integrity
  - rollback/hold mechanisms
  - change-control checkpoints

### Acceptance checkpoint
- Stable unattended operations over agreed burn-in period (e.g., 2–4 weeks).

---

## Human Validator Design (Target State)
Validator is a **first-class stage**, not ad-hoc.

### Validator workflow
1. Pipeline emits `pending_validation` with gate-specific checklist.
2. Human reviews required artifacts.
3. Human submits structured decision.
4. Pipeline either advances or branches to correction path.

### Required record fields
- `job_id`
- `gate_id`
- `decision`
- `validator`
- `validated_at_utc`
- `notes`
- `artifact_refs`

---

## QA/QC ML Growth Path (Data-first)
ML is introduced after consistent structured history exists.

### Data capture first
For every run, persist:
- inputs + metadata
- stage durations
- status transitions
- validator decisions
- QA metrics
- failure reason codes
- final disposition

### Model progression
1. Pass-risk classifier (likely pass vs likely needs review)
2. Anomaly detection (detect unusual runs)
3. Fix suggestion model (reason-code remediation hints)

### Guardrail
- ML starts as advisory only.
- Autonomy level increases only after measured precision/recall thresholds are met.

---

## Build Mode Execution Rules (Locked)
- Work in 1–2 command steps.
- Validate output after each step.
- No broad refactors mid-run.
- Every stage change must update status semantics + runbook notes.

---

## Monday Night Checkpoint Plan
1. Fresh baseline rerun (`run_job.ps1`) + capture `status.json`.
2. Add `registration_stub` stage and validate transition.
3. Implement first safe SOP-mapped post-probe action.
4. Add first validator gate + decision writeback.
5. Update docs (`README.md`, `PROJECT_SPEC_V1.md`, checklist).
6. Commit and push clean milestone checkpoint.

---

## Immediate Next Action
Proceed with Monday Step 1 baseline rerun, then move sequentially through the checkpoint plan in Build Mode.
