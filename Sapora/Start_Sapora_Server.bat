@echo off
setlocal
cd /d "%~dp0"

REM Deactivate conda if active to avoid interference
if defined CONDA_DEFAULT_ENV (
  echo Deactivating conda environment...
  call conda deactivate 2>nul
)

REM Prefer EXE in dist or current folder, otherwise fallback to Python
if exist "%~dp0dist\SaporaServer.exe" (
  echo Starting Sapora Server (EXE)...
  start "Sapora Server" "%~dp0dist\SaporaServer.exe"
  goto :eof
)
if exist "%~dp0SaporaServer.exe" (
  echo Starting Sapora Server (EXE)...
  start "Sapora Server" "%~dp0SaporaServer.exe"
  goto :eof
)

REM Use venv Python if available, otherwise fallback to system Python
if exist "%~dp0.venv\Scripts\python.exe" (
  echo Starting Sapora Server (venv Python)...
  start "Sapora Server" "%~dp0.venv\Scripts\python.exe" server\server_main.py
) else (
  echo Starting Sapora Server (system Python)...
  start "Sapora Server" cmd /c "py server\server_main.py & echo. & echo Press any key to close this window... & pause >nul"
)

endlocal
