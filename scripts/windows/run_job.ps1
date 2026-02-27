param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPath,

    # Optional resume job id (re-enter a pending job instead of creating a new one)
    [string]$JobId,

    # Use this switch to continue past the early human gate
    [switch]$ApproveDataClean,

    # Use this switch to continue past final QC gate
    [switch]$ApproveFinalQC
)

$ErrorActionPreference = "Stop"

# ---------- Helpers ----------
function Write-StageStatus {
    param(
        [string]$Stage,
        [string]$Result = "ok",
        [string]$ReasonCode = "",
        [hashtable]$Extra = @{}
    )

    $status.stage = $Stage
    $status.result = $Result
    $status.reason_code = $ReasonCode
    $status.updated_at = (Get-Date).ToString("s")

    foreach ($k in $Extra.Keys) {
        $status[$k] = $Extra[$k]
    }

    $json = $status | ConvertTo-Json -Depth 10
    $tmpPath = "$statusPath.tmp"
    $written = $false
    for ($i = 0; $i -lt 12; $i++) {
        try {
            Set-Content -Path $tmpPath -Value $json -Encoding UTF8 -ErrorAction Stop
            Move-Item -Path $tmpPath -Destination $statusPath -Force -ErrorAction Stop
            $written = $true
            break
        } catch {
            Start-Sleep -Milliseconds 300
        }
    }
    if (-not $written) {
        throw "Could not write status file after retries: $statusPath"
    }

    Write-Host "[STATUS] $Stage ($Result)"
}

function Fail-And-Exit {
    param(
        [string]$Stage,
        [string]$ReasonCode,
        [string]$Message
    )
    Write-StageStatus -Stage $Stage -Result "fail" -ReasonCode $ReasonCode -Extra @{ message = $Message; completed_at = (Get-Date).ToString("s") }
    Write-Error $Message
    exit 1
}

# ---------- Validate inputs ----------
if (-not (Test-Path $ZipPath)) {
    throw "ZipPath not found: $ZipPath"
}
if ([IO.Path]::GetExtension($ZipPath).ToLower() -ne ".zip") {
    throw "ZipPath must be a .zip file: $ZipPath"
}

# Prefix rule only: YY-CC-PPP-CLIENT-##-## (suffix flexible)
$zipName = [IO.Path]::GetFileName($ZipPath)
$baseName = [IO.Path]::GetFileNameWithoutExtension($zipName)
$prefixRegex = '^(?<prefix>\d{2}-\d{2}-\d{3}-[A-Za-z0-9]+-\d{2}-\d{2})(?:-.+)?$'
$match = [regex]::Match($baseName, $prefixRegex)
if (-not $match.Success) {
    throw "Invalid zip naming prefix. Expected YY-CC-PPP-CLIENT-##-## (suffix optional). File: $zipName"
}
$jobPrefix = $match.Groups["prefix"].Value

# ---------- Load paths config ----------
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$configPath = Join-Path $repoRoot "config\pipeline_paths.json"
if (-not (Test-Path $configPath)) {
    throw "Missing config file: $configPath"
}

$cfg = Get-Content $configPath -Raw | ConvertFrom-Json

# Expected keys in pipeline_paths.json:
# ingest_root, working_root, output_root, log_root, scene_project_root(optional)
$workingRoot = $cfg.working_root
$outputRoot  = $cfg.output_root
$logRoot     = $cfg.log_root
$sceneProjectRoot = $cfg.scene_project_root

if (-not $workingRoot -or -not $outputRoot -or -not $logRoot) {
    throw "pipeline_paths.json must define working_root, output_root, log_root"
}
if (-not $sceneProjectRoot) {
    # safe fallback so project stage can still run
    $sceneProjectRoot = Join-Path $outputRoot "scene_projects"
}

# ---------- Job scaffold ----------
if (-not $JobId -or [string]::IsNullOrWhiteSpace($JobId)) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $jobId = "$jobPrefix-$timestamp"
} else {
    $jobId = $JobId
}

$workDir = Join-Path $workingRoot $jobId
$jobLogDir = Join-Path $logRoot $jobId
$jobOutDir = Join-Path $outputRoot $jobId
$sceneProjectDir = Join-Path $sceneProjectRoot $jobId

New-Item -ItemType Directory -Force -Path $workDir         | Out-Null
New-Item -ItemType Directory -Force -Path $jobLogDir       | Out-Null
New-Item -ItemType Directory -Force -Path $jobOutDir       | Out-Null
New-Item -ItemType Directory -Force -Path $sceneProjectDir | Out-Null

$statusPath = Join-Path $jobLogDir "status.json"

$status = @{
    started_at = (Get-Date).ToString("s")
    updated_at = (Get-Date).ToString("s")
    stage = "job_created"
    result = "ok"
    reason_code = ""
    job_id = $jobId
    zip_path = $ZipPath
    zip_name = $zipName
    work_dir = $workDir
    log_dir = $jobLogDir
    output_dir = $jobOutDir
    scene_project_dir = $sceneProjectDir
    checkpoints = @()
}

$status | ConvertTo-Json -Depth 10 | Set-Content -Path $statusPath -Encoding UTF8

if ($PSBoundParameters.ContainsKey('JobId')) {
    Write-Host "[OK] Job resumed: $jobId"
} else {
    Write-Host "[OK] Job created: $jobId"
}
Write-Host "[OK] Work dir: $workDir"
Write-Host "[OK] Log dir : $jobLogDir"

# ---------- Stage 1: project_creation (real folder + marker) ----------
$projectReadme = Join-Path $sceneProjectDir "PROJECT_CREATE_IN_SCENE.txt"
@"
Reginald Project Creation Gate

Job ID: $jobId
Scene project directory: $sceneProjectDir

Action required:
1) Open FARO SCENE
2) Create a NEW project for this job inside this directory
3) Save the project in this folder

Verification:
- Any Scene project file in this folder (*.lsproj, *.flsproj, *.fws)
"@ | Set-Content -Path $projectReadme -Encoding UTF8

$existingProjectFiles = @()
$existingProjectFiles += Get-ChildItem -Path $sceneProjectDir -File -Filter *.lsproj -Recurse -ErrorAction SilentlyContinue
$existingProjectFiles += Get-ChildItem -Path $sceneProjectDir -File -Filter *.flsproj -Recurse -ErrorAction SilentlyContinue
$existingProjectFiles += Get-ChildItem -Path $sceneProjectDir -File -Filter *.fws -Recurse -ErrorAction SilentlyContinue
if ($existingProjectFiles.Count -gt 0) {
    Write-StageStatus -Stage "project_creation_done" -Extra @{ scene_project_file = $existingProjectFiles[0].FullName }
    $status.checkpoints += "project_creation_done"
} else {
    Write-StageStatus -Stage "project_creation_pending" -Result "pending_validation" -ReasonCode "awaiting_scene_project_create" -Extra @{ project_instruction = $projectReadme }
    Write-Host "[HUMAN CHECKPOINT] Create/save Scene project in: $sceneProjectDir"
    Write-Host "[HUMAN CHECKPOINT] Then rerun with -JobId $jobId to continue this same job."
    exit 0
}

# ---------- Stage 2: processing_data (extract + manifest) ----------
try {
    $extractDir = Join-Path $workDir "extracted"
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
    Expand-Archive -Path $ZipPath -DestinationPath $extractDir -Force

    $extractedFiles = Get-ChildItem -Path $extractDir -Recurse -File -ErrorAction SilentlyContinue
    if (-not $extractedFiles -or $extractedFiles.Count -eq 0) {
        Fail-And-Exit -Stage "processing_data_done" -ReasonCode "extract_empty" -Message "Extraction completed but no files were found in $extractDir"
    }

    $topFolders = Get-ChildItem -Path $extractDir -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    $extSample = $extractedFiles |
        Group-Object Extension |
        Sort-Object Count -Descending |
        Select-Object -First 12 |
        ForEach-Object { @{ extension = ($_.Name); count = $_.Count } }

    $manifestPath = Join-Path $jobOutDir "processing_manifest.json"
    $manifest = @{
        job_id = $jobId
        created_at = (Get-Date).ToString("s")
        zip_path = $ZipPath
        extract_dir = $extractDir
        file_count = $extractedFiles.Count
        total_bytes = ($extractedFiles | Measure-Object Length -Sum).Sum
        top_level_folders = @($topFolders)
        extension_summary = @($extSample)
    }
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding UTF8

    Write-StageStatus -Stage "processing_data_done" -Extra @{ extracted_to = $extractDir; processing_manifest = $manifestPath; extracted_file_count = $extractedFiles.Count }
    $status.checkpoints += "processing_data_done"
}
catch {
    Fail-And-Exit -Stage "processing_data_done" -ReasonCode "zip_extract_failed" -Message $_.Exception.Message
}

# ---------- Stage 3: data_clean_stub ----------
# TODO: remove yellow spheres logic goes here
Write-StageStatus -Stage "data_clean_stub_done"
$status.checkpoints += "data_clean_stub_done"

# ---------- Stage 4: pending_validation_data_clean ----------
Write-StageStatus -Stage "pending_validation_data_clean" -Result "pending_validation" -ReasonCode "awaiting_human_data_clean_check"

if (-not $ApproveDataClean) {
    Write-Host "[HUMAN CHECKPOINT] Data-clean validation required. Re-run with -ApproveDataClean to continue."
    exit 0
}

# ---------- Stage 5: pre_reg_stub ----------
# TODO: load scans into RAM / pre-reg prep
Write-StageStatus -Stage "pre_reg_stub_done"
$status.checkpoints += "pre_reg_stub_done"

# ---------- Stage 6: registration_stub ----------
# Optional: call faro_probe as lightweight placeholder for now
try {
    $probeScript = Join-Path $repoRoot "scripts\windows\faro_probe.ps1"
    if (Test-Path $probeScript) {
        & $probeScript
    }
}
catch {
    # probe fail should fail registration stub for now
    Fail-And-Exit -Stage "registration_stub_done" -ReasonCode "faro_probe_failed" -Message $_.Exception.Message
}

Write-StageStatus -Stage "registration_stub_done"
$status.checkpoints += "registration_stub_done"

# ---------- Stage 7: export_data_report ----------
# TODO: produce data report artifact
$reportPath = Join-Path $jobOutDir "data_report_stub.txt"
"Data report placeholder for $jobId - $(Get-Date -Format s)" | Set-Content $reportPath -Encoding UTF8
Write-StageStatus -Stage "export_data_report_done" -Extra @{ data_report = $reportPath }
$status.checkpoints += "export_data_report_done"

# ---------- Stage 8: ml_qc_stub_pending ----------
Write-StageStatus -Stage "ml_qc_stub_pending" -Result "pending" -ReasonCode "ml_qc_not_enabled"
$status.checkpoints += "ml_qc_stub_pending"

# ---------- Stage 9: pending_validation_final_qc ----------
Write-StageStatus -Stage "pending_validation_final_qc" -Result "pending_validation" -ReasonCode "awaiting_human_final_qc"

if (-not $ApproveFinalQC) {
    Write-Host "[HUMAN CHECKPOINT] Final QC validation required. Re-run with -ApproveDataClean -ApproveFinalQC to continue."
    exit 0
}

# ---------- Stage 10: re_reg_loop_active (stub) ----------
# TODO: real loop logic (if fail criteria, branch back to registration)
Write-StageStatus -Stage "re_reg_loop_active" -Extra @{ loop_mode = "stub_no_iterations" }
$status.checkpoints += "re_reg_loop_active"

# ---------- Stage 11: post_process_done ----------
# TODO: post-processing logic
Write-StageStatus -Stage "post_process_done"
$status.checkpoints += "post_process_done"

# ---------- Stage 12: export_rcs_done ----------
# TODO: real RCS export
$rcsStub = Join-Path $jobOutDir "export_rcs_stub.txt"
"RCS export placeholder for $jobId" | Set-Content $rcsStub -Encoding UTF8
Write-StageStatus -Stage "export_rcs_done" -Extra @{ rcs_artifact = $rcsStub }
$status.checkpoints += "export_rcs_done"

# ---------- Stage 13: export_eshare_done ----------
# TODO: real eShare export
$eshareStub = Join-Path $jobOutDir "export_eshare_stub.txt"
"eShare export placeholder for $jobId" | Set-Content $eshareStub -Encoding UTF8
Write-StageStatus -Stage "export_eshare_done" -Extra @{ eshare_artifact = $eshareStub }
$status.checkpoints += "export_eshare_done"

# ---------- Complete ----------
Write-StageStatus -Stage "job_complete" -Result "ok" -Extra @{ completed_at = (Get-Date).ToString("s"); checkpoints = $status.checkpoints }
Write-Host "[OK] Job complete: $jobId"
Write-Host "[OK] Status file: $statusPath"
