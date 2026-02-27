# AUTOMATION EXECUTION PLAN for FARO Scene MCP

Goal: Replace manual project creation with automation stage flow that enforces QC gates before human review.

1) Stage Mapping
- ingest_extract_done -> run_stage_ingest
- scene_import_done -> scene.import_scans
- scene_processing_done -> scene.start_processing
- pre_reg -> scene.wait_processing_complete
- reg -> scene.target_based_reg and/or scene.cloud_based_reg
- exports -> scene.export_data_report, scene.export_rcs, scene.export_eshare
- qc -> final QC check gates; human in the loop

2) Patch plan for run_job.ps1
- Rename stages in the script to reflect new order:
  - ingest_extract_done -> run_stage_ingest
  - scene_import_done -> scene.import_scans
  - scene_processing_done -> scene.start_processing
  - pre_reg -> scene.wait_processing_complete
  - reg -> (split into) scene.target_based_reg, scene.cloud_based_reg
  - exports -> keep as is but ensure invoked after reg
  - qc -> qc_gate_check
- Ordering:
  1. run_stage_ingest (ingest scans) and initial QC placeholders
  2. scene.import_scans
  3. scene.start_processing
  4. scene.wait_processing_complete
  5. scene.target_based_reg
  6. scene.cloud_based_reg
  7. scene.export_data_report
  8. scene.export_rcs
  9. scene.export_eshare
  10. qc_gate_check (human QC gate)

3) Implementation plan
- Create MCP client library with JSON schemas for each action (as in MCP_SCENE_API_V1).
- Implement a small orchestrator that sequences actions with QC gates.
- Use idempotent design: re-run stage idempotently; store state in /exports/qc_state.json per project.
- Logging: standardized logs to /logs/scene/<project_id>/_log.txt
- Error handling: stage_fail triggers a pause and alert to human QC gate.
- Human QC gates
  - Gate 1: After import_scans; Gate 2: After wait_processing_complete; Gate 3: After exports; Gate 4: After QC checks

4) docs
- Keep MCP API doc and Automation plan in docs/
- Provide a sample run.json and run_sequence.json for reference.

5) Commit notes
- Branch: scout_dev
- Message: "MR: FARO Scene MCP v1 + automation plan" 

6) Morning-ready next 5 commands for Jerry
- git checkout scout_dev
- git pull origin scout_dev
- git status
- ls -la docs/
- cat docs/MCP_SCENE_API_V1.md
