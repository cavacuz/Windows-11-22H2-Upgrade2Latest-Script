@echo off
title Windows 11 Upgrade Helper

echo.
echo Windows 11 Upgrade Helper
echo =========================
echo.
echo This will run the helper in CheckOnly mode first.
echo No system changes will be made.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Upgrade-Win11-22H2-to-Latest.ps1" -Mode CheckOnly

echo.
echo Done.
pause
