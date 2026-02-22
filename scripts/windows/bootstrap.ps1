param(
  [string]$Root = "E:\Eclipse VD Dropbox\EclipseVD\POINTCLOUD\TESTING ENV"
)

$ErrorActionPreference = "Stop"

$paths = @(
  "$Root\incoming_raw",
  "$Root\working",
  "$Root\outputs",
  "$Root\logs",
  "$Root\control_csv"
)

foreach ($p in $paths) {
  if (!(Test-Path $p)) {
    New-Item -ItemType Directory -Path $p | Out-Null
  }
}

Write-Host "[OK] Folder contract created under: $Root"

$envDir = Join-Path $PSScriptRoot "..\..\config"
if (!(Test-Path $envDir)) { New-Item -ItemType Directory -Path $envDir | Out-Null }

$envFile = Join-Path $envDir "local.env"
@"
TEST_ROOT=$Root
SCENE_PATH=C:\Program Files\FARO\SCENE\SCENE.exe
SDK_ROOT=C:\Program Files\FARO\FARO LS
"@ | Set-Content -Path $envFile -Encoding UTF8

Write-Host "[OK] Wrote config file: $envFile"
Write-Host "Next: run .\scripts\windows\faro_probe.ps1"
