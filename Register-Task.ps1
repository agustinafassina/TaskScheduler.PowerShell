#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Registers a scheduled task that runs an executable at system startup.

.DESCRIPTION
    Creates a Task Scheduler task that runs as NT AUTHORITY\SYSTEM with the highest
    privileges, starting a configurable number of minutes after Windows boots.
    If a task with the same name already exists, it is replaced.

.EXAMPLE
    .\Register-Task.ps1 -ExecutablePath "C:\Apps\test.exe"

.EXAMPLE
    .\Register-Task.ps1 -TaskName "MyApp" -ExecutablePath "C:\Apps\test.exe" -Argument "-batchmode" -DelayMinutes 10 -RunNow
#>
[CmdletBinding()]
param(
    [string]$TaskName = "Agus-task",

    [Parameter(Mandatory)]
    [string]$ExecutablePath,

    [string]$Argument = "-batchmode",

    [ValidateRange(0, 1440)]
    [int]$DelayMinutes = 5,

    # Run the task only when a network connection is available
    [switch]$RequireNetwork,

    # Start the task immediately after registering it
    [switch]$RunNow
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
    throw "Executable not found: '$ExecutablePath'"
}

try {
    $actionParams = @{ Execute = $ExecutablePath }
    if ($Argument) { $actionParams.Argument = $Argument }
    $action = New-ScheduledTaskAction @actionParams

    $trigger = New-ScheduledTaskTrigger -AtStartup
    if ($DelayMinutes -gt 0) {
        $trigger.Delay = "PT$($DelayMinutes)M"   # ISO 8601 duration, e.g. PT5M
    }

    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $settings.RunOnlyIfNetworkAvailable = [bool]$RequireNetwork

    $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal

    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Write-Host "Task '$TaskName' already exists. Replacing it..."
    }
    Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force | Out-Null

    Write-Host "Task '$TaskName' successfully scheduled (runs at startup, delay: $DelayMinutes min)."

    if ($RunNow) {
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "Task '$TaskName' started."
    }
}
catch {
    Write-Error "Failed to schedule task '$TaskName': $($_.Exception.Message)"
    exit 1
}
