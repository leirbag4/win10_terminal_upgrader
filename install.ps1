#Requires -Version 5.1
<#
.SYNOPSIS
    Instala Windows Terminal y sus dependencias en Windows 10 (sin Store ni Winget)
    y lo configura como terminal predeterminada del sistema.
#>

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$prevProgress = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

$tempDir = Join-Path $env:TEMP "win10_terminal_upgrader_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    Write-Host "[1/4] Descargando e instalando Microsoft.VCLibs.140.00.UWPDesktop (x64)..." -ForegroundColor Cyan
    $vcLibsPath = Join-Path $tempDir "Microsoft.VCLibs.x64.14.00.Desktop.appx"
    Invoke-WebRequest -Uri "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile $vcLibsPath
    try {
        Add-AppxPackage -Path $vcLibsPath
    } catch {
        Write-Host "      VCLibs ya presente o version superior instalada, continuando..." -ForegroundColor DarkGray
    }

    Write-Host "[2/4] Descargando e instalando Microsoft.UI.Xaml.2.8 desde NuGet..." -ForegroundColor Cyan
    $xamlZipPath = Join-Path $tempDir "xaml.zip"
    $xamlExtractPath = Join-Path $tempDir "xaml_temp"
    Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.7" -OutFile $xamlZipPath
    Expand-Archive -Path $xamlZipPath -DestinationPath $xamlExtractPath -Force
    $xamlAppxPath = Join-Path $xamlExtractPath "tools\AppX\x64\Release\Microsoft.UI.Xaml.2.8.appx"
    try {
        Add-AppxPackage -Path $xamlAppxPath
    } catch {
        Write-Host "      UI.Xaml 2.8 ya presente o version superior instalada, continuando..." -ForegroundColor DarkGray
    }

    Write-Host "[3/4] Obteniendo la ultima version de Windows Terminal desde GitHub..." -ForegroundColor Cyan
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/terminal/releases/latest" -Headers @{ "User-Agent" = "win10-terminal-upgrader" }
    $asset = $release.assets | Where-Object { $_.name -like "*.msixbundle" } | Select-Object -First 1

    if (-not $asset) {
        throw "No se encontro el archivo .msixbundle en el ultimo release de microsoft/terminal."
    }

    Write-Host "      Descargando $($asset.name)..." -ForegroundColor DarkGray
    $msixPath = Join-Path $tempDir $asset.name
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $msixPath
    Add-AppxPackage -Path $msixPath

    Write-Host "[4/4] Configurando Windows Terminal como terminal predeterminada..." -ForegroundColor Cyan
    $startupKey = "HKCU:\Console\%%Startup"
    if (-not (Test-Path $startupKey)) {
        New-Item -Path $startupKey -Force | Out-Null
    }
    Set-ItemProperty -Path $startupKey -Name "DelegationConsole" -Value "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}" -Type String
    Set-ItemProperty -Path $startupKey -Name "DelegationTerminal" -Value "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}" -Type String

    Write-Host "`nListo! Windows Terminal ($($release.tag_name)) instalado y configurado por defecto." -ForegroundColor Green
    Write-Host "Nota: Si estabas usando Tiny10 o una build antigua de Win10, la opcion predeterminada requiere Windows 10 22H2 (build 19045+)." -ForegroundColor Yellow
}
catch {
    Write-Host "`nError durante la instalacion: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    $ProgressPreference = $prevProgress
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
