[CmdletBinding()]
param()
$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path) | Out-Null
Set-Location ..

Write-Host "[*] Verifying Node.js..."
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "[*] Installing Node via winget..."
        winget install -e --id OpenJS.NodeJS.LTS -h
    } else {
        Write-Host "Node not found and winget unavailable. Install Node LTS manually, then rerun."
        exit 1
    }
}

Write-Host "[*] Installing npm deps..."
npm ci 2>$null
if ($LASTEXITCODE -ne 0) { npm install }

New-Item -ItemType Directory -Force -Path data, logs | Out-Null

Write-Host "[*] Bootstrap complete. Start with: node .\src\runner.js"
