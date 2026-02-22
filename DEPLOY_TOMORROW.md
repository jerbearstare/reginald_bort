# Reginald_bort — Tomorrow Deploy Plan (Work PC First)

## Mission for Tomorrow
Get a **first successful automated interaction** between OpenClaw orchestration and FARO Scene 2022 on your work PC.

Success criteria (v1):
1. OpenClaw pipeline starts from a test input folder.
2. FARO Scene 2022 is detected and can be launched by automation.
3. SDK path is detected (if present) and probe script completes.
4. A milestone run log is generated and committed.

Grand-win criteria:
- A full registration pass runs end-to-end on one test project.

---

## Architecture (v1, pragmatic isolation)
Because FARO Scene is a Windows GUI app with dongle licensing, full containerization of Scene is not realistic.

Use **hybrid isolation**:
- Docker container: orchestrator and job logic
- Native Windows host: FARO Scene execution runner (PowerShell)
- Shared job folders between orchestrator and host

This gives isolation for automation logic while keeping Scene stable.

---

## Confirmed Inputs
- Scene installer: `SCENE_2022.2.0.10355_Setup`
- SDK location candidate: `C:\Program Files\FARO\FARO LS`
- Dropbox test intake root: `E:\Eclipse VD Dropbox\EclipseVD\POINTCLOUD\TESTING ENV`
- ZIP contains scans only (CSV elsewhere for now)
- Outputs needed: **RCS + report + QA images** (no Scene project copy)
- Git workflow: direct to `main`, milestone commits
- Notifications: Telegram + GitHub

---

## Folder Contract (v1)
Under your testing root:

- `incoming_raw/` — zipped scan projects
- `working/<job_id>/` — extracted + processing workspace
- `outputs/<job_id>/` — RCS + report + QA images
- `logs/<job_id>/` — stage logs + timings + errors
- `control_csv/` — parked for now (future step)

---

## Day-1 Execution Sequence

### Stage 0 — Prep (15–25 min)
1. Install/confirm Docker Desktop on Windows.
2. Confirm Scene 2022 installed + launches manually.
3. Confirm dongle present and license recognized by Scene.
4. Run FARO probe script (`scripts/windows/faro_probe.ps1`).

### Stage 1 — Bootstrap runtime (20–30 min)
1. Create folder contract under testing root.
2. Start orchestrator container (`docker compose up -d`).
3. Run bootstrap script (`scripts/windows/bootstrap.ps1`).
4. Verify `config/local.env` has correct paths.

### Stage 2 — First automated proof (20–45 min)
1. Drop one small ZIP into `incoming_raw/`.
2. Trigger dry-run:
   - unzip
   - job scaffolding
   - logging
   - FARO launch/check hook
3. Confirm logs are written and stage status recorded.

### Stage 3 — Milestone + commit (10 min)
1. Save run artifacts in `runs/<date>/<job_id>/`.
2. Commit with `[scout-bot]` marker.
3. Push to `main`.

---

## Hard Limits / Guardrails (v1)
- If Scene cannot launch via automation: mark run `failed_scene_launch` and stop.
- If dongle/license unavailable: mark run `failed_license` and stop.
- No destructive deletes of raw input zips in v1.
- Keep every failure log.

---

## Milestone Commit Plan
1. `milestone: bootstrap paths + env wiring [scout-bot]`
2. `milestone: FARO probe + launch check [scout-bot]`
3. `milestone: first dry-run pipeline [scout-bot]`
4. `milestone: first real test artifact bundle [scout-bot]`

---

## Tomorrow Go/No-Go Checklist
- [ ] Scene launches manually
- [ ] Dongle recognized
- [ ] FARO probe script passes
- [ ] Docker orchestrator running
- [ ] Test ZIP discovered in incoming folder
- [ ] Job log + status file produced

If first run fails, it still counts as progress if logs capture where and why.
