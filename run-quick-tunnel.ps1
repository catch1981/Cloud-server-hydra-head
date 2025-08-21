[CmdletBinding()]
param()
$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path) | Out-Null
Set-Location ..
$port = $env:PORT
if (-not $port) { $port = 3000 }

$bin = Join-Path (Get-Location) "bin"
New-Item -ItemType Directory -Force -Path $bin | Out-Null

function Get-Arch {
  $a = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
  if ($a -match "64") { return "amd64" } else { return "386" }
}

$cf = Join-Path $bin "cloudflared.exe"
if (-not (Test-Path $cf)) {
  Write-Host "[*] Downloading cloudflared..."
  $arch = Get-Arch
  $url = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-$arch.exe"
  Invoke-WebRequest -Uri $url -OutFile $cf
}

Write-Host "[*] Starting quick tunnel to http://localhost:$port ..."
& $cf tunnel --url "http://localhost:$port"
