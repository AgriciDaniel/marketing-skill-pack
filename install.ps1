# =============================================================================
# Marketing Skill Pack — Windows Installer
# https://github.com/AgriciDaniel/marketing-skill-pack
#
# Run in PowerShell (as normal user, no admin required):
#   irm https://raw.githubusercontent.com/AgriciDaniel/marketing-skill-pack/main/install.ps1 | iex
#
# This script locates Git Bash (or WSL bash) and delegates to install.sh.
# If neither is found, it prints clear instructions.
# =============================================================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  AI Marketing Hub -- Marketing Skill Pack" -ForegroundColor White
Write-Host "  Windows Installer" -ForegroundColor White
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# ── Locate bash ───────────────────────────────────────────────────────────────
$bashExe = $null

# Common Git for Windows installation paths
$gitBashCandidates = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "$env:ProgramFiles\Git\usr\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe",
    "$env:USERPROFILE\AppData\Local\Programs\Git\bin\bash.exe"
)

foreach ($path in $gitBashCandidates) {
    if (Test-Path $path) {
        $bashExe = $path
        Write-Host "[+] Found Git Bash: $path" -ForegroundColor Green
        break
    }
}

# Fall back to bash on PATH (covers WSL and other setups)
if (-not $bashExe) {
    $bashOnPath = Get-Command "bash" -ErrorAction SilentlyContinue
    if ($bashOnPath) {
        $bashExe = $bashOnPath.Source
        Write-Host "[+] Found bash on PATH: $bashExe" -ForegroundColor Green
    }
}

# ── Run installer via bash ────────────────────────────────────────────────────
if ($bashExe) {
    $installUrl = "https://raw.githubusercontent.com/AgriciDaniel/marketing-skill-pack/main/install.sh"
    $tempScript = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "msp-install-$([System.Guid]::NewGuid().ToString('N')).sh")

    Write-Host "[.] Downloading installer ..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $installUrl -OutFile $tempScript -UseBasicParsing
        Write-Host "[+] Running installer via bash ..." -ForegroundColor Green
        Write-Host ""

        # Convert Windows path to Unix path for Git Bash
        # e.g. C:\Users\... -> /c/Users/...
        $unixPath = $tempScript -replace '\\', '/'
        $unixPath = $unixPath -replace '^([A-Za-z]):', { '/' + $matches[1].ToLower() }

        & $bashExe $unixPath
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            Write-Host ""
            Write-Host "[-] Installer exited with code $exitCode. See errors above." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "[-] Failed to download installer: $_" -ForegroundColor Red
    }
    finally {
        if (Test-Path $tempScript) { Remove-Item $tempScript -Force }
    }
}
else {
    # ── No bash found — print instructions ───────────────────────────────────
    Write-Host "[-] Bash not found on this system." -ForegroundColor Red
    Write-Host ""
    Write-Host "To run the Marketing Skill Pack installer on Windows, you need bash." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1 (Recommended) -- Git for Windows (includes Git Bash):" -ForegroundColor White
    Write-Host "  1. Download and install: https://git-scm.com/download/win"
    Write-Host "  2. Open 'Git Bash' from the Start menu"
    Write-Host "  3. Run:"
    Write-Host "       curl -fsSL https://raw.githubusercontent.com/AgriciDaniel/marketing-skill-pack/main/install.sh | bash" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option 2 -- WSL (Windows Subsystem for Linux):" -ForegroundColor White
    Write-Host "  1. Install WSL: https://learn.microsoft.com/windows/wsl/install"
    Write-Host "  2. Open your WSL terminal and run:"
    Write-Host "       curl -fsSL https://raw.githubusercontent.com/AgriciDaniel/marketing-skill-pack/main/install.sh | bash" -ForegroundColor Cyan
    Write-Host ""
}
