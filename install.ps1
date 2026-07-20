# SlashGuard installer — Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/slashguard/slashguard/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = "slashguard/slashguard"
$InstallDir = Join-Path $env:LOCALAPPDATA "SlashGuard"
$BinDir = Join-Path $InstallDir "bin"
$PacksDir = Join-Path $InstallDir "packs"

# --- Detect architecture ---
# Windows on ARM runs x64 binaries via emulation — always use amd64
$Arch = "amd64"

$Platform = "windows-$Arch"
$ZipName = "slashguard-$Platform.zip"
$Url = "https://github.com/$Repo/releases/latest/download/$ZipName"

Write-Host "SlashGuard installer"
Write-Host "  Platform: $Platform"
Write-Host "  Install:  $InstallDir"
Write-Host ""

# --- Download ---
$TmpDir = Join-Path $env:TEMP "sg-install-$(Get-Random)"
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null
$ZipPath = Join-Path $TmpDir $ZipName

try {
    Write-Host "Downloading $ZipName..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
} catch {
    Write-Error "Download failed: $_"
    exit 1
}

# --- Extract ---
Write-Host "Extracting..."
$ExtractDir = Join-Path $TmpDir "sg"
Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir -Force

# --- Install ---
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
New-Item -ItemType Directory -Path $PacksDir -Force | Out-Null

Copy-Item (Join-Path $ExtractDir "bin\sg.exe") (Join-Path $BinDir "sg.exe") -Force

# Packs
Get-ChildItem (Join-Path $ExtractDir "packs\*.sgpack") -ErrorAction SilentlyContinue |
    ForEach-Object { Copy-Item $_.FullName $PacksDir -Force }

# Custom packs: only on first install
$CustomDir = Join-Path $PacksDir "custom"
if (-not (Test-Path $CustomDir)) {
    $SrcCustom = Join-Path $ExtractDir "packs\custom"
    if (Test-Path $SrcCustom) {
        Copy-Item $SrcCustom $CustomDir -Recurse -Force
    }
}

# Rules: copy to install dir so they survive temp cleanup
$RulesDir = Join-Path $InstallDir "rules"
New-Item -ItemType Directory -Path $RulesDir -Force | Out-Null
Copy-Item (Join-Path $ExtractDir "rules\*") $RulesDir -Recurse -Force

# --- PATH ---
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*SlashGuard*") {
    [Environment]::SetEnvironmentVariable("Path", "$BinDir;$UserPath", "User")
    $env:Path = "$BinDir;$env:Path"
    Write-Host "  Added $BinDir to user PATH"
}

# --- Verify ---
try {
    $Version = & (Join-Path $BinDir "sg.exe") --version 2>&1
} catch {
    $Version = "unknown"
}

Write-Host ""
Write-Host "SlashGuard $Version installed to $BinDir\sg.exe"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Configure MCP in your IDE (Cursor/Claude Code/Windsurf)"
Write-Host "  2. Activate license: sg license activate <your-key>"
Write-Host "  3. Restart your IDE"
Write-Host ""
Write-Host "Rule files are in: $RulesDir\"
Write-Host "Copy the ones for your IDE to your project's rules directory."

# --- Cleanup ---
Remove-Item $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
