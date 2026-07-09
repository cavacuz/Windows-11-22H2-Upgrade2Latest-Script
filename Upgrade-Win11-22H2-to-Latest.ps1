# Upgrade-Win11-22H2-to-Latest.ps1
# Safe helper for Windows 11 22H2 devices blocked by Windows Update

param(
    [ValidateSet("CheckOnly", "RepairWU")]
    [string]$Mode = "CheckOnly"
)

$ErrorActionPreference = "Stop"

$LogDir = "C:\ProgramData\Win11-Upgrade-Helper"
$LogFile = Join-Path $LogDir "upgrade-helper.log"

if (!(Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Color = "White"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"

    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $line
}

function Test-IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-WindowsInfo {
    $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

    [PSCustomObject]@{
        ProductName    = $reg.ProductName
        DisplayVersion = $reg.DisplayVersion
        CurrentBuild   = $reg.CurrentBuild
        UBR            = $reg.UBR
        EditionID      = $reg.EditionID
    }
}

Write-Log "Windows 11 Upgrade Helper started." "Cyan"
Write-Log "Mode: $Mode" "Cyan"
Write-Log "Log file: $LogFile" "Gray"

if (!(Test-IsAdmin)) {
    Write-Log "ERROR: Please run this script as Administrator." "Red"
    exit 1
}

Write-Log "Administrator check passed." "Green"

$winInfo = Get-WindowsInfo

Write-Log "Detected Windows installation:" "Cyan"
Write-Log "Product name: $($winInfo.ProductName)" "White"
Write-Log "Display version: $($winInfo.DisplayVersion)" "White"
Write-Log "Build: $($winInfo.CurrentBuild).$($winInfo.UBR)" "White"
Write-Log "Edition: $($winInfo.EditionID)" "White"

if ($winInfo.DisplayVersion -eq "22H2") {
    Write-Log "This device is running Windows 11 22H2." "Yellow"
}
else {
    Write-Log "This device is not detected as Windows 11 22H2. Continuing check only." "Yellow"
}

$systemDrive = $env:SystemDrive
$drive = Get-PSDrive -Name $systemDrive.TrimEnd(":")
$freeGB = [math]::Round($drive.Free / 1GB, 2)

Write-Log "Free space on ${systemDrive}: $freeGB GB" "Cyan"

if ($freeGB -lt 30) {
    Write-Log "WARNING: Less than 30 GB free. Windows feature upgrades may fail." "Yellow"
}
else {
    Write-Log "Disk space check passed." "Green"
}

Write-Log "Step 1 complete. No system changes were made." "Green"
