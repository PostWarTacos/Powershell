<#
Find possibly malicious scheduled tasks. Hint: Exclude tasks that are most likely to be trusted
#>

Get-ScheduledTask | select Taskpath,TaskName,State,Author,Date,Description,Triggers | ?{$_.Author -notlike "Microsoft*"} | Out-GridView