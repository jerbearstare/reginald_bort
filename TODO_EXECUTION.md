# Reginald_bort — Execution TODO (Build Mode)

_Last updated: 2026-02-26 (UTC)_

## Priority 0 — Pipeline Progression (After Scene Probe)
- [ ] Re-run `run_job.ps1` and capture fresh `status.json` baseline
- [ ] Add `registration_stub` stage to `run_job.ps1`
- [ ] Validate stage transition appears in status/logs
- [ ] Add first safe, non-destructive post-probe FARO action
- [ ] Re-test and confirm failure reason codes are actionable

## Priority 1 — SOP Mapping
- [ ] Ingest human SOP from Jerry (registration procedure)
- [ ] Map SOP into pipeline gates:
  - [ ] automated steps
  - [ ] human confirmation checkpoints
- [ ] Update runbook/checklist to reflect exact gate sequence

## Priority 2 — Release Checkpoint (Monday Night Push)
- [ ] Update docs (`README.md`, `PROJECT_SPEC_V1.md`, checklist)
- [ ] Include run evidence paths/examples
- [ ] Commit in logical chunks
- [ ] Push clean checkpoint to `main`

## Priority 3 — Budget Proposal Package (Deferred)
- [ ] Finalize printable **Executive Proposal Template v1**
  - [ ] Dial in margins/spacing/font to match Jerry’s markup preference
  - [ ] Produce clean Letter PDF
  - [ ] Approve final print sample
  - [ ] Save reusable template source + print recipe in repo/docs

## Working Rules (locked)
- Build Mode only: 1–2 steps at a time, verify before proceeding
- Filename validation: enforce prefix `YY-CC-PPP-CLIENT-##-##` only
- Suffix qualifiers remain flexible (must not fail jobs)
- v1 ingest path remains `...\TESTING ENV\incoming_raw`
