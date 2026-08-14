@echo off
setlocal
set OUTPUT_DIR=Output
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build.ps1"
REM Open the most recently built archive (newest zip in the output dir), if present.
for /f "delims=" %%F in ('dir /b /o-d "%OUTPUT_DIR%\Foragers_*.zip" 2^>nul') do (
    start "" "%~dp0%OUTPUT_DIR%\%%F"
    goto :done
)
echo No build archive found in %OUTPUT_DIR%.
:done
endlocal
