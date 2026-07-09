@echo off
title Windows 11 Upgrade Helper

net session >nul 2>&1

if %errorlevel% neq 0 (
    echo.
    echo Requesting Administrator permissions...
    echo.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -WorkingDirectory '%~dp0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

:Menu
cls
echo.
echo Windows 11 Upgrade Helper
echo =========================
echo.
echo Choose an option:
echo.
echo [1] Check this PC only
echo [2] Open official Microsoft Windows 11 ISO download page
echo [3] Download ISO from a direct Microsoft ISO link, mount it, then ask to start upgrade
echo [4] Mount existing downloaded ISO, then ask to start upgrade
echo [5] Exit
echo.
echo [1] Check this PC only
echo [2] Open official Microsoft Windows 11 ISO download page
echo [3] Download ISO from a direct Microsoft ISO link
echo [4] Exit
echo.

choice /c 1234 /n /m "Select option 1, 2, 3, or 4: "

if errorlevel 4 goto Exit
if errorlevel 3 goto DownloadISO
if errorlevel 2 goto OpenIsoPage
if errorlevel 1 goto CheckOnly

choice /c 12345 /n /m "Select option 1, 2, 3, 4, or 5: "

if errorlevel 5 goto Exit
if errorlevel 4 goto MountISO
if errorlevel 3 goto DownloadISO
if errorlevel 2 goto OpenIsoPage
if errorlevel 1 goto CheckOnly

:CheckOnly
cls
echo.
echo Running CheckOnly mode...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Upgrade-Win11-22H2-to-Latest.ps1" -Mode CheckOnly
goto End

:OpenIsoPage
cls
echo.
echo Opening official Microsoft Windows 11 ISO download page...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Upgrade-Win11-22H2-to-Latest.ps1" -Mode OpenIsoPage
goto End

:DownloadISO
cls
echo.
echo Download ISO from direct Microsoft ISO link
echo =========================================
echo.
echo First open the Microsoft Windows 11 download page.
echo Select the ISO option and language.
echo Then copy the generated direct ISO download link.
echo.
echo Leave this blank to open the Microsoft download page instead.
echo.

set "ISOURL="
set /p "ISOURL=ISO URL: "

echo.
echo Downloading ISO...
echo After download, the script will mount the ISO.
echo Then it will ask if you want to start the upgrade.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Upgrade-Win11-22H2-to-Latest.ps1" -Mode DownloadISO -IsoUrl "%ISOURL%" -MountAfterDownload -PromptToStartUpgrade
goto End

:MountISO
cls
echo.
echo Mount existing ISO
echo ==================
echo.
echo Default ISO path:
echo C:\Win11-ISO\Windows11.iso
echo.
echo Press ENTER to use the default path, or paste a different ISO path.
echo.

set "CUSTOMISOPATH="
set /p "CUSTOMISOPATH=ISO path: "

if "%CUSTOMISOPATH%"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Upgrade-Win11-22H2-to-Latest.ps1" -Mode MountISO -PromptToStartUpgrade
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Upgrade-Win11-22H2-to-Latest.ps1" -Mode MountISO -IsoPath "%CUSTOMISOPATH%" -PromptToStartUpgrade
)

goto End

:End
echo.
echo Done.
echo.
pause
goto Menu

:Exit
echo.
echo Exiting.
echo.
exit /b
