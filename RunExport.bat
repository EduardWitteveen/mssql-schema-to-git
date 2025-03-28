@echo off
echo RunExport.bat Versie 1.1
echo -----------------------

REM Deel 1: Start het installatie-/configuratiescript met elevated privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Niet als administrator uitgevoerd. Vraag om elevated privileges...
    powershell -Command "Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0InstallatieTooling.ps1\"' -Verb RunAs"
    pause
) else (
    echo Installatie script wordt als administrator uitgevoerd...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0InstallatieTooling.ps1"
)

REM Deel 2: Start het exportscript als jouw eigen gebruiker (niet elevated)
echo Nu starten we het exportscript als jouw eigen gebruiker...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0ExportData.ps1"
pause
