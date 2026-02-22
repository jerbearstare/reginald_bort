# Reginald_bort — Execution Spec v1

## Pipeline States
1. `ingest_detected`
2. `project_setup`
3. `preprocessing`
4. `registration`
5. `qa_check`
6. `post_processing`
7. `final_check`
8. `project_close`
9. `done` / `failed`

## Gates
- G1: Input package completeness (zip/files/control)
- G2: Registration quality threshold met
- G3: QA slices approved (human)
- G4: Export artifacts present

## Minimal Artifact Contract
- Inputs:
  - raw uploads
  - control/tiepoint CSV
- Outputs:
  - registered Scene project
  - RCS export
  - QA images/slices
  - run log
  - summary note

## Failure Policy
- Any failed gate => stop, notify overseer, keep artifacts for audit.

## Notifications
- Start
- Gate pass/fail
- Final summary

## Validation Plan
- Run on 3-4 representative projects
- Track:
  - runtime
  - manual interventions
  - failure causes
  - output quality acceptance
