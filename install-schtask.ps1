[CmdletBinding()]
param(
  [string]$TaskName = "HydraNode",
  [string]$User = "$env:USERNAME"
)
$ErrorActionPreference = "Stop"
$AppDir = (Resolve-Path "..").Path
$Node = (Get-Command node).Source
$Action = New-ScheduledTaskAction -Execute $Node -Argument "`"$AppDir\src\runner.js`"" -WorkingDirectory $AppDir
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 9999 -RestartInterval (New-TimeSpan -Minutes 1)

try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
} catch {}
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -User $User -RunLevel Highest
Start-ScheduledTask -TaskName $TaskName
Write-Host "[*] Scheduled Task installed and started: $TaskName"
