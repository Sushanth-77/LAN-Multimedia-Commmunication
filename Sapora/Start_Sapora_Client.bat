@echo off
setlocal
cd /d "%~dp0"

REM Deactivate conda if active to avoid interference
if defined CONDA_DEFAULT_ENV (
  echo Deactivating conda environment...
  call conda deactivate 2>nul
)

REM Prefer EXE in dist or current folder, otherwise fallback to Python
if exist "%~dp0dist\SaporaClient.exe" (
  echo Starting Sapora Client (EXE)...
  start "Sapora Client" "%~dp0dist\SaporaClient.exe"
  goto :eof
)
if exist "%~dp0SaporaClient.exe" (
  echo Starting Sapora Client (EXE)...
  start "Sapora Client" "%~dp0SaporaClient.exe"
  goto :eof
)

REM Use venv Python if available, otherwise fallback to system Python
if exist "%~dp0.venv\Scripts\python.exe" (
  echo Starting Sapora Client (venv Python)...
  start "Sapora Client" "%~dp0.venv\Scripts\python.exe" client\main_ui.py
) else (
  echo Starting Sapora Client (system Python)...
  start "Sapora Client" cmd /c "py client\main_ui.py & echo. & echo Press any key to close this window... & pause >nul"
)

endlocal
