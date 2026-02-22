# First Run Checklist (Tomorrow)

1. Plug dongle in before launching Scene.
2. Run `scripts/windows/faro_probe.ps1`.
3. Run `scripts/windows/bootstrap.ps1`.
4. Start docker stack:
   - `docker compose up -d`
5. Place one small test zip in `incoming_raw`.
6. Create job folder in `working/<job_id>` and extract zip.
7. Launch Scene manually once for trust/license prompts.
8. Record outcome in `logs/<job_id>/run_summary.md`.
9. Commit milestone + push to `main`.
