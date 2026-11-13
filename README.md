# Win10 Terminal Upgrader

Automated PowerShell installer for **Windows Terminal** on stripped, unattended, or fresh **Windows 10** installations (such as Tiny10 or LTSC) where the Microsoft Store and `winget` are unavailable.

## What It Does

1. **Installs `Microsoft.VCLibs.140.00.UWPDesktop` (x64)** directly from Microsoft's servers.
2. **Downloads and installs `Microsoft.UI.Xaml.2.8`** from NuGet.
3. **Fetches and installs the latest `.msixbundle`** release of Windows Terminal from the official [microsoft/terminal](https://github.com/microsoft/terminal) repository.
4. **Sets Windows Terminal as the default terminal** in Windows 10 (`HKCU\Console\%%Startup`).
5. **Cleans up** all temporary installer files automatically.

## Quick Usage (One-Liner)

Open **PowerShell** and run:

```powershell
irm [https://raw.githubusercontent.com/leirbag4/win10_terminal_upgrader/main/install.ps1](https://raw.githubusercontent.com/leirbag4/win10_terminal_upgrader/main/install.ps1) | iex
