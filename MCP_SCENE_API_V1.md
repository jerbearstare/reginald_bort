# FARO Scene Automation API - MCP v1

Overview
- Objective: Define a command schema (MCP) for automating FARO Scene workflows.
- Parties: client (request), server (response), with QC gates.

1. scene.create_project
- Purpose: Initialize a new Scene project.
- Request (JSON):
  ```json
  {
    "project_id": "proj_2026_0227",
    "name": "CustomerA_LakeView",
    "template": "default",
    "owner": "reginald_bot",
    "options": {"units": "meters", "alignment": "world"}
  }
  ```
- Response (JSON):
  ```json
  {
    "status": "ok",
    "project_id": "proj_2026_0227",
    "scene_id": "scene_12345",
    "created_at": "2026-02-27T06:32:00Z",
    "qc": {"passes": true, "metrics_url": "/qc/proj_2026_0227"}
  }
  ```
- QC Metrics: scene_id, created_at, units, alignment, qc_passes, metrics_url

2. scene.import_scans
- Purpose: Ingest scans into project.
- Request:
  ```json
  {
    "project_id": "proj_2026_0227",
    "scan_source": "local_drive",
    "paths": ["/data/proj_2026_0227/scan1.las","scan2.las"],
    "alignment": "auto"
  }
  ```
- Response:
  ```json
  {
    "status": "accepted",
    "import_id": "imp_98765",
    "scans": 2,
    "estimated_completion_sec": 120
  }
  ```
- QC Metrics: import_id, scans, total_size_mb, started_at, estimated_completion_sec

3. scene.start_processing
- Purpose: Kick processing/registration.
- Request:
  ```json
  {
    "project_id": "proj_2026_0227",
    "processing_profile": "default_reg",
    "priority": "normal"
  }
  ```
- Response:
  ```json
  {
    "status": "started",
    "process_id": "proc_55555",
    "started_at": "2026-02-27T06:34:00Z"
  }
  ```
- QC Metrics: process_id, started_at, profile, priority

4. scene.wait_processing_complete
- Purpose: Poll until complete or timeout.
- Request:
  ```json
  {
    "project_id": "proj_2026_0227",
    "process_id": "proc_55555",
    "timeout_sec": 3600
  }
  ```
- Response (poll):
  ```json
  {
    "status": "complete",
    "progress": 100,
    "registrations_ok": true,
    "export_ready": true
  }
  ```
- QC Metrics: progress, registrations_ok, export_ready, completed_at

5. scene.target_based_reg
- Purpose: Target-based regression against ground-truth targets.
- Request:
  ```json
  {
    "project_id": "proj_2026_0227",
    "target_id": "target_42",
    "reg_parameters": {"strategy":"pinhole","rigid_transform":true}
  }
  ```
- Response:
  ```json
  {
    "status": "reg_completed",
    "target_id": "target_42",
    "metrics": {"rmse":0.012, "mean_error":0.004}
  }
  ```
- QC Metrics: rmse, mean_error, target_id

6. scene.cloud_based_reg
- Purpose: Cloud-based refinement.
- Request:
  ```json
  {
    "project_id": "proj_2026_0227",
    "cloud_profile": "auto_refine",
    "segments": ["seg1","seg2"]
  }
  ```
- Response:
  ```json
  {
    "status": "ok",
    "cloud_job_id": "cloud_8833",
    "refinement": {"rmse": 0.009, "completeness": 0.98}
  }
  ```
- QC Metrics: cloud_job_id, rmse, completeness

7. scene.export_data_report
- Purpose: Export data report (PDF/CSV).
- Request:
  ```json
  {
    "project_id": "proj_2026_0227",
    "format": "pdf",
    "include_isomaps": true
  }
  ```
- Response:
  ```json
  {
    "status": "exported",
    "report_url": "/exports/proj_2026_0227/report.pdf",
    "size_kb": 20480
  }
  ```
- QC Metrics: report_url, size_kb, format

8. scene.export_rcs
- Purpose: Export RCS (scene compatibility sheet).
- Request:
  ```json
  {
    "project_id": "proj_2026_0227",
    "format": "rcs"
  }
  ```
- Response:
  ```json
  {
    "status": "exported",
    "rcs_url": "/rcs/proj_2026_0227.rcs"
  }
  ```
- QC Metrics: rcs_url

9. scene.export_eshare
- Purpose: Share to eShare portal.
- Request:
  ```json
  {
    "project_id": "proj_2026_0227",
    "eshare_token": "token_xyz",
    "permissions": ["view","comment"]
  }
  ```
- Response:
  ```json
  {
    "status": "shared",
    "eshare_url": "https://eshare.example/proj_2026_0227"
  }
  ```
- QC Metrics: eshare_url, permissions

QC Gating
- Each stage returns a qc object with passes boolean and metrics_url or report_url.
- The orchestration should halt on qc_passes == false and require human QC review.
