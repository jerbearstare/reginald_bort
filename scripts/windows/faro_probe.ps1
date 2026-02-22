$ErrorActionPreference = "Continue"

$sceneCandidates = @(
  "C:\Program Files\FARO\SCENE\SCENE.exe",
  "C:\Program Files\FARO\SCENE 2022\SCENE.exe"
)

$scenePath = $sceneCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($null -eq $scenePath) {
  Write-Host "[FAIL] SCENE.exe not found in expected locations."
  exit 2
}

Write-Host "[OK] Scene found: $scenePath"

$sdkRoot = "C:\Program Files\FARO\FARO LS"
if (Test-Path $sdkRoot) {
  Write-Host "[OK] SDK root exists: $sdkRoot"
} else {
  Write-Host "[WARN] SDK root missing at: $sdkRoot"
}

Write-Host "[INFO] Attempting Scene launch test..."
try {
  $p = Start-Process -FilePath $scenePath -PassThru
  Start-Sleep -Seconds 8
  if (!$p.HasExited) {
    Write-Host "[OK] Scene launched (PID: $($p.Id))."
    Stop-Process -Id $p.Id -Force
    Write-Host "[OK] Scene launch probe complete."
    exit 0
  } else {
    Write-Host "[WARN] Scene exited quickly with code: $($p.ExitCode)"
    exit 1
  }
} catch {
  Write-Host "[FAIL] Scene launch error: $($_.Exception.Message)"
  exit 3
}
