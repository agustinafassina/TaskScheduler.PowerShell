#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Removes a scheduled task created by Register-Task.ps1.

.EXAMPLE
    .\Unregister-Task.ps1 -TaskName "Agus-task"
#>
[CmdletBinding()]
param(
    [string]$TaskName = "Agus-task"
)

$ErrorActionPreference = 'Stop'

if (-not (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) {
    Write-Host "Task '$TaskName' does not exist. Nothing to remove."
    exit 0
}

try {
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Task '$TaskName' successfully removed."
}
catch {
    Write-Error "Failed to remove task '$TaskName': $($_.Exception.Message)"
    exit 1
}
