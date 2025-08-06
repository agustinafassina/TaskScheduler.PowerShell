$taskName = "Agus-task"
$executablePath = 'C:\...............\test.exe'
$argument = "-batchmode"

$action = New-ScheduledTaskAction -Execute $executablePath -Argument $argument

$trigger = New-ScheduledTaskTrigger -AtStartup

# 5 minutes
if ($PSVersionTable.PSVersion.Major -eq 4) {
    $trigger.RandomDelay = New-TimeSpan -Minutes 5
} else {
    $trigger.Delay = "PT5M"
}

$settings = New-ScheduledTaskSettingsSet
$settings.RunOnlyIfNetworkAvailable = $false # Change to true if you want the task to run only when the network is available
$settings.AllowDemandStart = $true
$settings.StartWhenAvailable = $true
$settings.WakeToRun = $true # Wake the computer to run this task

$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Create the scheduled task object
$task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal

# Register the scheduled task
Register-ScheduledTask -TaskName $taskName -InputObject $task

# Initialize the task last run time
Start-ScheduledTask -TaskName $taskName

Write-Host "task '$taskName' successfully scheduled."