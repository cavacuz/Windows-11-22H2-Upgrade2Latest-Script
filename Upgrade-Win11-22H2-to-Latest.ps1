#requires -Version 5.1

<#
.SYNOPSIS
    Windows 11 Upgrade Helper for devices stuck on older feature updates, especially 22H2.

.DESCRIPTION
    This script helps users check the current Windows version, open the official Microsoft
    Windows 11 ISO download page, download a Microsoft ISO from a direct ISO URL, and mount
    the ISO after download.

    It does not bypass TPM, Secure Boot, CPU, or Microsoft safeguard holds.

.MODES
    CheckOnly    - Checks Windows version, admin status, build, edition, and disk space.
    OpenIsoPage  - Opens the official Microsoft Windows 11 download page.
    DownloadISO  - Downloads a Windows 11 ISO from a direct Microsoft ISO URL.
    RepairWU     - Planned mode for future Windows Update repair steps.
#>

param(
    [ValidateSet("CheckOnly", "OpenIsoPage", "DownloadISO", "RepairWU")]
    [string]$Mode = "CheckOnly",

    [string]$IsoUrl = "",

    [string]$IsoDirectory = "C:\Win11-ISO",

    [switch]$MountAfterDownload
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
        [ConsoleColor]$Color = "White"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"

    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

function Test-IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)

    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-WindowsInfo {
    $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

    $displayVersion = $reg.DisplayVersion

    if ([string]::IsNullOrWhiteSpace($displayVersion)) {
        $displayVersion = $reg.ReleaseId
    }

    [PSCustomObject]@{
        ProductName    = $reg.ProductName
        DisplayVersion = $displayVersion
        CurrentBuild   = $reg.CurrentBuild
        UBR            = $reg.UBR
        EditionID      = $reg.EditionID
    }
}

function Get-SystemDriveFreeSpace {
    $driveLetter = $env:SystemDrive.TrimEnd(":")
    $drive = Get-PSDrive -Name $driveLetter

    [PSCustomObject]@{
        Drive  = "${driveLetter}:"
        FreeGB = [math]::Round($drive.Free / 1GB, 2)
    }
}

function Open-Windows11IsoPage {
    $downloadPage = "https://www.microsoft.com/software-download/windows11"

    Write-Log "Opening official Microsoft Windows 11 download page..." "Cyan"
    Write-Log "Use the section named: Download Windows 11 Disk Image ISO for x64 devices." "Yellow"
    Write-Log "After Microsoft generates the ISO link, copy it if you want this script to download it." "Yellow"

    Start-Process $downloadPage
}

function Mount-WindowsIso {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )

    Write-Log "Mounting ISO..." "Cyan"

    $diskImage = Mount-DiskImage -ImagePath $ImagePath -PassThru -ErrorAction Stop

    Start-Sleep -Seconds 3

    $volume = $null

    try {
        $volume = $diskImage |
            Get-Volume -ErrorAction SilentlyContinue |
            Where-Object { $_.DriveLetter } |
            Select-Object -First 1
    }
    catch {
        $volume = $null
    }

    if (-not $volume) {
        try {
            $volume = Get-DiskImage -ImagePath $ImagePath |
                Get-Disk |
                Get-Partition |
                Get-Volume |
                Where-Object { $_.DriveLetter } |
                Select-Object -First 1
        }
        catch {
            $volume = $null
        }
    }

    if ($volume -and $volume.DriveLetter) {
        $driveLetter = $volume.DriveLetter
        $setupPath = "${driveLetter}:\setup.exe"

        Write-Log "ISO mounted as drive ${driveLetter}:" "Green"

        if (Test-Path $setupPath) {
            Write-Log "Windows Setup found: $setupPath" "Green"
            Write-Log "Recommended upgrade command:" "Cyan"
            Write-Log "$setupPath /auto upgrade /dynamicupdate enable /eula accept" "White"
        }
        else {
            Write-Log "WARNING: ISO mounted, but setup.exe was not found at $setupPath" "Yellow"
        }
    }
    else {
        Write-Log "WARNING: ISO was mounted, but no drive letter was detected." "Yellow"
    }
}

function Download-Windows11Iso {
    param(
        [string]$Url,
        [string]$DestinationDirectory,
        [switch]$Mount
    )

    if ([string]::IsNullOrWhiteSpace($Url)) {
        Write-Log "No ISO URL was provided." "Yellow"
        Write-Log "Opening the official Microsoft download page instead." "Yellow"

        Open-Windows11IsoPage
        return
    }

    try {
        $uri = [System.Uri]$Url
    }
    catch {
        throw "Invalid ISO URL."
    }

    if ($uri.Scheme -ne "https") {
        throw "ISO URL must start with https://"
    }

    if ($uri.Host.ToLowerInvariant() -notmatch '(^|\.)microsoft\.com$') {
        throw "For safety, the ISO URL must be from a microsoft.com domain."
    }

    if (!(Test-Path $DestinationDirectory)) {
        New-Item -Path $DestinationDirectory -ItemType Directory -Force | Out-Null
    }

    $destination = Join-Path $DestinationDirectory "Windows11.iso"

    if (Test-Path $destination) {
        Write-Log "Existing ISO found at $destination" "Yellow"
        Write-Log "Removing existing ISO before downloading a fresh copy..." "Yellow"

        Remove-Item -Path $destination -Force
    }

    Write-Log "Starting Windows 11 ISO download..." "Cyan"
    Write-Log "Source: $Url" "Gray"
    Write-Log "Destination: $destination" "White"

    $bitsJob = $null

    try {
        Import-Module BitsTransfer -ErrorAction Stop

        $bitsJob = Start-BitsTransfer `
            -Source $Url `
            -Destination $destination `
            -DisplayName "Windows 11 ISO Download" `
            -Description "Downloading Windows 11 ISO from Microsoft" `
            -Priority Foreground `
            -Asynchronous `
            -ErrorAction Stop

        while ($true) {
            $bitsJob = Get-BitsTransfer -Id $bitsJob.Id -ErrorAction Stop

            if ($bitsJob.BytesTotal -gt 0) {
                $percent = [math]::Round(($bitsJob.BytesTransferred / $bitsJob.BytesTotal) * 100, 1)
                $transferredGB = [math]::Round($bitsJob.BytesTransferred / 1GB, 2)
                $totalGB = [math]::Round($bitsJob.BytesTotal / 1GB, 2)

                Write-Progress `
                    -Activity "Downloading Windows 11 ISO" `
                    -Status "$percent% complete - $transferredGB GB of $totalGB GB" `
                    -PercentComplete $percent
            }
            else {
                Write-Progress `
                    -Activity "Downloading Windows 11 ISO" `
                    -Status "Preparing download..." `
                    -PercentComplete 0
            }

            if ($bitsJob.JobState -eq "Transferred") {
                Complete-BitsTransfer -BitsJob $bitsJob
                break
            }

            if ($bitsJob.JobState -in @("Error", "TransientError", "Cancelled", "Suspended")) {
                throw "BITS download stopped with state: $($bitsJob.JobState)"
            }

            Start-Sleep -Seconds 3
        }

        Write-Progress -Activity "Downloading Windows 11 ISO" -Completed
    }
    catch {
        Write-Progress -Activity "Downloading Windows 11 ISO" -Completed

        if ($bitsJob) {
            try {
                Remove-BitsTransfer -BitsJob $bitsJob -Confirm:$false -ErrorAction SilentlyContinue
            }
            catch {
                # Ignore cleanup errors
            }
        }

        Write-Log "BITS download failed or is unavailable." "Yellow"
        Write-Log "Reason: $($_.Exception.Message)" "Yellow"
        Write-Log "Falling back to Invoke-WebRequest..." "Yellow"

        Invoke-WebRequest `
            -Uri $Url `
            -OutFile $destination `
            -UseBasicParsing
    }

    if (!(Test-Path $destination)) {
        throw "ISO download failed. File was not created."
    }

    $isoSizeGB = [math]::Round((Get-Item $destination).Length / 1GB, 2)

    Write-Log "ISO download completed." "Green"
    Write-Log "ISO path: $destination" "Cyan"
    Write-Log "ISO size: $isoSizeGB GB" "Cyan"

    if ($isoSizeGB -lt 4) {
        Write-Log "WARNING: ISO file looks smaller than expected. The download may be incomplete." "Yellow"
    }

    if ($Mount) {
        Mount-WindowsIso -ImagePath $destination
    }
    else {
        Write-Log "MountAfterDownload was not selected. ISO was downloaded but not mounted." "Yellow"
    }
}

try {
    Write-Log "Windows 11 Upgrade Helper started." "Cyan"
    Write-Log "Mode: $Mode" "Cyan"
    Write-Log "Log file: $LogFile" "Gray"

    $isAdmin = Test-IsAdmin

    if (!$isAdmin -and $Mode -ne "OpenIsoPage") {
        Write-Log "ERROR: Please run this script as Administrator." "Red"
        exit 1
    }

    if ($isAdmin) {
        Write-Log "Administrator check passed." "Green"
    }
    else {
        Write-Log "Administrator rights not detected. Continuing because OpenIsoPage mode does not require elevation." "Yellow"
    }

    if ($Mode -ne "OpenIsoPage") {
        $winInfo = Get-WindowsInfo

        Write-Log "Detected Windows installation:" "Cyan"
        Write-Log "Product name: $($winInfo.ProductName)" "White"
        Write-Log "Display version: $($winInfo.DisplayVersion)" "White"
        Write-Log "Build: $($winInfo.CurrentBuild).$($winInfo.UBR)" "White"
        Write-Log "Edition: $($winInfo.EditionID)" "White"

        if ($winInfo.ProductName -notlike "*Windows 11*") {
            Write-Log "WARNING: This device does not appear to be running Windows 11." "Yellow"
        }

        if ($winInfo.DisplayVersion -eq "22H2") {
            Write-Log "This device is running Windows 11 22H2." "Yellow"
        }
        else {
            Write-Log "This device is not detected as Windows 11 22H2." "Yellow"
        }

        $spaceInfo = Get-SystemDriveFreeSpace

        Write-Log "Free space on $($spaceInfo.Drive) $($spaceInfo.FreeGB) GB" "Cyan"

        if ($Mode -eq "DownloadISO" -and $spaceInfo.FreeGB -lt 40) {
            Write-Log "WARNING: Less than 40 GB free. ISO download plus feature upgrade may fail." "Yellow"
        }
        elseif ($spaceInfo.FreeGB -lt 30) {
            Write-Log "WARNING: Less than 30 GB free. Windows feature upgrades may fail." "Yellow"
        }
        else {
            Write-Log "Disk space check passed." "Green"
        }
    }

    switch ($Mode) {
        "CheckOnly" {
            Write-Log "CheckOnly complete. No system changes were made." "Green"
        }

        "OpenIsoPage" {
            Open-Windows11IsoPage
            Write-Log "ISO download page opened. No system changes were made." "Green"
        }

        "DownloadISO" {
            Download-Windows11Iso `
                -Url $IsoUrl `
                -DestinationDirectory $IsoDirectory `
                -Mount:$MountAfterDownload
        }

        "RepairWU" {
            Write-Log "RepairWU mode is planned but not implemented yet." "Yellow"
            Write-Log "No repair actions were performed." "Yellow"
        }
    }

    Write-Log "Windows 11 Upgrade Helper finished." "Green"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)" "Red"
    Write-Log "Windows 11 Upgrade Helper stopped because of an error." "Red"
    exit 1
}
