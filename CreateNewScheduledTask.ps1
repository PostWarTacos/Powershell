#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                               Create New Scheduled Task to Initiate Miner                                         #
#                                             Trigger: Idle PC                                                      #
#                                Contact Matthew Wurtz if you need any help                                         #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#Requires -RunAsAdministrator

#Change the name of your scheduled task
$Name = 'Idle Miner'

#Set to the file path where your .bat file is. Do NOT delete the SINGLE or DOUBLE quotes!!
$Action = New-ScheduledTaskAction -Execute '"[FILE PATH HERE]"'

#Conitions for initiating your scheduled task. Change IdleDuration to equal the amount of Idle time that will initiate you scheduled task. Format: HH:MM:SS
$Settings = New-ScheduledTaskSettingsSet -RunOnlyIfIdle -IdleDuration 00:10:00 -IdleWaitTimeout 00:00:00 -MultipleInstances IgnoreNew -RunOnlyIfNetworkAvailable -ExecutionTimeLimit 00:00:00 -WakeToRun

#DO NOT CHANGE THESE TWO LINES
$Trigger = (Get-CimClass -ClassName 'MSFT_TaskIdleTrigger' -Namespace 'Root/Microsoft/Windows/TaskScheduler')
Register-ScheduledTask $Name -Action $Action -Settings $Settings -Trigger $Trigger -TaskPath \Microsoft