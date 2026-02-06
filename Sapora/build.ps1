# Build script for Sapora (Windows PowerShell)
# - Produces two EXEs: SaporaClient.exe, SaporaServer.exe
# - Creates dist\Sapora.zip containing those two files

$ErrorActionPreference = 'Stop'

# Deactivate conda if active to avoid interference with venv
if ($env:CONDA_DEFAULT_ENV) {
  Write-Host "Deactivating conda environment..." -ForegroundColor Yellow
  try {
    conda deactivate 2>$null
  } catch {
    # Conda might not be available in PowerShell, that's okay
  }
}

function Ensure-Tool($name) {
  Write-Host "Checking for $name..." -ForegroundColor Cyan
  $null = Get-Command $name -ErrorAction SilentlyContinue
  if (-not $?) { throw "Required tool '$name' not found in PATH." }
}

# Move to repository root (script directory)
Set-Location -Path $PSScriptRoot

# Remove Mark-of-the-Web from extracted files (common when running from Downloads)
try {
  Get-ChildItem -LiteralPath $PSScriptRoot -Recurse -Force -File | ForEach-Object {
    try { Unblock-File -LiteralPath $_.FullName -ErrorAction SilentlyContinue } catch {}
  }
} catch {}

# Verify basic tools
Ensure-Tool python
Ensure-Tool pip

# Create and use local virtual environment
$venvDir = Join-Path $PSScriptRoot '.venv'
$venvPy  = Join-Path $venvDir 'Scripts\python.exe'
$venvPip = Join-Path $venvDir 'Scripts\pip.exe'
if (-not (Test-Path $venvPy)) {
  Write-Host "Creating virtual environment in .venv..." -ForegroundColor Cyan
  & python -m venv $venvDir
}
Write-Host "Upgrading pip in venv..." -ForegroundColor Cyan
$env:PIP_DISABLE_PIP_VERSION_CHECK = '1'
$env:PIP_NO_CACHE_DIR = '1'
# Do pip upgrade explicitly to avoid argument splitting issues
& $venvPy -m pip install --upgrade pip

function Invoke-PipInstall {
  param()
  $Packages = @($args)
  $max=5
  for ($i=1; $i -le $max; $i++) {
    & $venvPy -m pip install @Packages
    if ($LASTEXITCODE -eq 0) { return }
    Start-Sleep -Seconds ([Math]::Min(5,$i*2))
  }
  throw "pip install failed: $($Packages -join ' ')"
}

# Install project requirements into the venv
$rootReq = Join-Path $PSScriptRoot 'requirements.txt'
if (Test-Path $rootReq) {
  Write-Host "Installing requirements.txt into venv..." -ForegroundColor Cyan
  Invoke-PipInstall '-r', $rootReq, '--prefer-binary'
}
$clientReq = Join-Path $PSScriptRoot 'client\downloads\requirements.txt'
if (Test-Path $clientReq) {
  Write-Host "Installing client/downloads/requirements.txt into venv..." -ForegroundColor Cyan
  Invoke-PipInstall '-r', $clientReq, '--prefer-binary'
}

# Ensure PyInstaller in venv
Write-Host "Ensuring PyInstaller in venv..." -ForegroundColor Cyan
$hasPyInstaller = $false
try {
  & $venvPy -c "import PyInstaller" 2>$null
  if ($LASTEXITCODE -eq 0) { $hasPyInstaller = $true }
} catch {
  $hasPyInstaller = $false
}
if (-not $hasPyInstaller) {
  Invoke-PipInstall 'pyinstaller'
}

Write-Host "Ensuring PyQt6 in venv..." -ForegroundColor Cyan
$hasPyQt6 = $false
try {
  & $venvPy -c "import PyQt6" 2>$null
  if ($LASTEXITCODE -eq 0) { $hasPyQt6 = $true }
} catch {
  $hasPyQt6 = $false
}
if (-not $hasPyQt6) {
  Invoke-PipInstall 'PyQt6>=6.5','--prefer-binary'
}

# Paths
$clientEntry = Join-Path $PSScriptRoot 'client\main_ui.py'
$serverEntry = Join-Path $PSScriptRoot 'server\server_main.py'
$styleQss    = Join-Path $PSScriptRoot 'client\style.qss'
$distDir     = Join-Path $PSScriptRoot 'dist'
$zipPath     = Join-Path $distDir 'Sapora.zip'

# Best-effort stop previously running EXEs to release file locks
Write-Host "Ensuring no previous Sapora EXEs are running..." -ForegroundColor Cyan
Get-Process -Name 'SaporaClient' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name 'SaporaServer' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

function Remove-PathSafe([string]$path) {
  if (Test-Path $path) {
    for ($i=0; $i -lt 3; $i++) {
      try {
        Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
        return
      } catch {
        Start-Sleep -Milliseconds 300
      }
    }
    # As last resort, clear contents
    try {
      Get-ChildItem -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    } catch {}
  }
}

# Pre-clean previous artifacts
Write-Host "Cleaning previous build artifacts..." -ForegroundColor Cyan
Remove-PathSafe (Join-Path $PSScriptRoot 'build\SaporaClient')
Remove-PathSafe (Join-Path $PSScriptRoot 'build\SaporaServer')
Remove-PathSafe (Join-Path $PSScriptRoot 'SaporaClient.spec')
Remove-PathSafe (Join-Path $PSScriptRoot 'SaporaServer.spec')

# Build Client (GUI)
Write-Host "Building SaporaClient.exe..." -ForegroundColor Cyan
$clientArgs = @(
  '--noconfirm','--clean','--onefile','--noconsole',
  '--name','SaporaClient',
  '--hidden-import','PyQt6.sip',
  '--exclude-module','PyQt5',
  '--exclude-module','PySide6',
  '--exclude-module','PySide2'
)
if (Test-Path $styleQss) { $clientArgs += @('--add-data', "$styleQss;.") }
$clientArgs += $clientEntry

& $venvPy -m PyInstaller @clientArgs
if ($LASTEXITCODE -ne 0) { throw "Client build failed." }

# Build Server (Console)
Write-Host "Building SaporaServer.exe..." -ForegroundColor Cyan
$serverArgs = @(
  '--noconfirm','--clean','--onefile',
  '--name','SaporaServer',
  '--exclude-module','PyQt5',
  '--exclude-module','PySide6',
  '--exclude-module','PySide2',
  $serverEntry
)
& $venvPy -m PyInstaller @serverArgs
if ($LASTEXITCODE -ne 0) { throw "Server build failed." }

# Finalize build outputs (no ZIP packaging)
Write-Host "Finalizing build outputs (no ZIP)..." -ForegroundColor Cyan
$clientExe = Join-Path $distDir 'SaporaClient.exe'
$serverExe = Join-Path $distDir 'SaporaServer.exe'
$readme    = Join-Path $PSScriptRoot 'README_RUN.txt'
$startAll  = Join-Path $PSScriptRoot 'Start_Sapora_All.bat'

if (-not (Test-Path $clientExe)) { throw "Missing $clientExe" }
if (-not (Test-Path $serverExe)) { throw "Missing $serverExe" }

# Copy launcher and README into dist if they exist
$extras = @()
foreach ($f in @($readme,$startAll)) { if (Test-Path $f) { $extras += $f } }
if ($extras.Count -gt 0) {
  Write-Host "Copying launcher/README into dist..." -ForegroundColor Cyan
  Copy-Item -Force -Path $extras -Destination $distDir
}

$distAll = @(
  $clientExe,
  $serverExe,
  (Join-Path $distDir 'Start_Sapora_All.bat'),
  (Join-Path $distDir 'README_RUN.txt')
) | Where-Object { Test-Path $_ }

Write-Host "Build complete. The following files are in 'dist':" -ForegroundColor Green
$distAll | ForEach-Object { Write-Host " - $_" }
