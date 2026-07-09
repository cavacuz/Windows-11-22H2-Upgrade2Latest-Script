# Windows 11 Upgrade Helper

A safe helper script for Windows 11 devices that are stuck on older feature updates, especially Windows 11 **22H2**, when Windows Update says the device cannot be updated.

This project is designed to help with:

* Checking the current Windows version
* Confirming the script is running as Administrator
* Checking free disk space
* Logging upgrade-preparation information
* Preparing the device for a safe in-place upgrade
* Guiding the user toward the official Windows 11 ISO or Installation Assistant upgrade path

> This tool does **not** bypass TPM, Secure Boot, CPU, or Microsoft safeguard holds by default.

---

## Why this exists

Some Windows 11 22H2 devices may stop receiving normal feature update offers through Windows Update or may show messages saying the version cannot be updated.

In many cases, the safest next step is not forcing Windows Update, but preparing the system and then using an official Windows 11 in-place upgrade method, such as:

* Windows 11 Installation Assistant
* Official Windows 11 ISO
* `setup.exe` from mounted installation media

This helper is intended to make that process easier and more transparent.

---

## Files

| File                               | Purpose                       |
| ---------------------------------- | ----------------------------- |
| `Upgrade-Win11-22H2-to-Latest.ps1` | Main PowerShell helper script |
| `Run-Upgrade-Helper.cmd`           | Simple launcher for users     |
| `README.md`                        | Project documentation         |

---

## Current features

The current version supports a safe check-only mode.

### `CheckOnly` mode

This mode makes no system changes.

It checks:

* Administrator privileges
* Windows product name
* Windows display version
* Build number
* Edition
* Free disk space on the system drive

A log file is created here:

```text
C:\ProgramData\Win11-Upgrade-Helper\upgrade-helper.log
```

---

## How to use

### Option 1: Use the CMD launcher

Right-click:

```text
Run-Upgrade-Helper.cmd
```

Then choose:

```text
Run as administrator
```

This runs the helper in `CheckOnly` mode.

---

### Option 2: Run from PowerShell

Open PowerShell as Administrator and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Upgrade-Win11-22H2-to-Latest.ps1 -Mode CheckOnly
```

---

## Example output

```text
[2026-07-09 10:30:00] Windows 11 Upgrade Helper started.
[2026-07-09 10:30:00] Mode: CheckOnly
[2026-07-09 10:30:00] Log file: C:\ProgramData\Win11-Upgrade-Helper\upgrade-helper.log
[2026-07-09 10:30:01] Administrator check passed.
[2026-07-09 10:30:01] Detected Windows installation:
[2026-07-09 10:30:01] Product name: Windows 11 Pro
[2026-07-09 10:30:01] Display version: 22H2
[2026-07-09 10:30:01] Build: 22621.xxxx
[2026-07-09 10:30:01] Edition: Professional
[2026-07-09 10:30:01] Free space on C:: 85.25 GB
[2026-07-09 10:30:01] Disk space check passed.
[2026-07-09 10:30:01] Step 1 complete. No system changes were made.
```

---

## Recommended upgrade path

After running the check-only mode, the recommended upgrade method is an official in-place upgrade.

Mount the latest Windows 11 ISO, then run:

```powershell
D:\setup.exe /auto upgrade /dynamicupdate enable /eula accept
```

Replace `D:` with the drive letter of the mounted ISO.

---

## Important safety notes

This project is intended for legitimate Windows upgrade preparation and troubleshooting.

It does not intentionally bypass:

* TPM requirements
* Secure Boot requirements
* CPU compatibility checks
* Microsoft safeguard holds
* Known compatibility blocks

Bypassing compatibility blocks may cause upgrade failures, driver issues, rollback loops, or an unstable Windows installation.

Always back up important files before attempting a feature upgrade.

---

## Planned features

Future versions may include:

* Windows Update component reset mode
* DISM health repair
* SFC system file check
* ISO detection
* Guided in-place upgrade launcher
* Progress messages for each repair step
* Better error handling and exit codes
* Optional reboot prompt

---

## Modes

| Mode        | Description                                                  | Makes changes? |
| ----------- | ------------------------------------------------------------ | -------------- |
| `CheckOnly` | Checks version, admin status, build, edition, and disk space | No             |
| `RepairWU`  | Planned mode for Windows Update repair steps                 | Yes, planned   |

---

## Requirements

* Windows 11
* Administrator rights
* PowerShell 5.1 or newer
* At least 30 GB free disk space recommended
* Official Windows 11 ISO or Installation Assistant for the final upgrade step

---

## Disclaimer

Use this script at your own risk.

The author is not responsible for data loss, failed upgrades, unsupported configurations, or damage caused by misuse. Always test in a controlled environment before using this on production machines.

This project is not affiliated with Microsoft.

---

## License

Add your preferred license here.

For example:

```text
MIT License
```

---

## Contributing

Pull requests and suggestions are welcome.

Good contributions include:

* Safer checks
* Better logging
* Clearer progress messages
* Improved compatibility detection
* Better documentation
* Tested upgrade scenarios

Please avoid adding unsafe bypass logic by default.
