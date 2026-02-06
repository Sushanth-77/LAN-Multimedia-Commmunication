@echo off
setlocal
cd /d "%~dp0"

REM Deactivate conda if active to avoid interference
if defined CONDA_DEFAULT_ENV (
  echo Deactivating conda environment...
  call conda deactivate 2>nul
)

set "LOG=%~dp0Start_Sapora_All.log"
echo [%DATE% %TIME%] ===== Launcher started (no auto-run) ===== > "%LOG%"

if not exist "%~dp0dist" (
  mkdir "%~dp0dist"
  echo [%DATE% %TIME%] Created dist folder. >> "%LOG%"
)

if exist "%~dp0dist\SaporaServer.exe" if exist "%~dp0dist\SaporaClient.exe" (
  echo ========================================
  echo   EXEs found. Starting Sapora...
  echo ========================================
  echo [%DATE% %TIME%] EXEs present. Starting server and client. >> "%LOG%"
  start "SaporaServer" "%~dp0dist\SaporaServer.exe"
  start "SaporaClient" "%~dp0dist\SaporaClient.exe"
  goto :done
)

echo [%DATE% %TIME%] EXEs not found. Attempting auto-build... >> "%LOG%"
echo ----- BEGIN BUILD OUTPUT ----- >> "%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1" >> "%LOG%" 2>&1
echo ----- END BUILD OUTPUT ----- >> "%LOG%"
if exist "%~dp0dist\SaporaServer.exe" if exist "%~dp0dist\SaporaClient.exe" (
  echo [%DATE% %TIME%] Auto-build succeeded. Starting Sapora. >> "%LOG%"
  start "SaporaServer" "%~dp0dist\SaporaServer.exe"
  start "SaporaClient" "%~dp0dist\SaporaClient.exe"
  goto :done
)
echo [%DATE% %TIME%] Auto-build did not produce EXEs. >> "%LOG%"
echo Auto-build failed. See log at: "%LOG%"
start notepad.exe "%LOG%"

:done
echo [%DATE% %TIME%] ===== Launcher finished ===== >> "%LOG%"
endlocal
