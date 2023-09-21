#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                               Display Logs For Scheduled Task to Initiate Miner                                   #
#                                                                                                                   #
#                                Contact Matthew Wurtz if you need any help                                         #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#Change AddDays(-1) to the desired amount of time you would like to show. Use decimals to show hours (Ex: use -.5 for 12 hours). 
#Change Message -like [NAME OF YOUR SCHEDULED TASK HERE] (do NOT delete quotes or asterisks) to search for the Name of your .bat file that initiates your Miner.exe. 

Get-WinEvent -LogName Microsoft-Windows-TaskScheduler/Operational |
    ?{$_.TimeCreated -ge [datetime]::Now.AddDays(-1) -and $_.Message -like "*Idle Miner*" -and ($_.Id -eq 101 -or $_.Id -eq 203 -or $_.Id -eq 108 -or $_.Id -eq 110 -or $_.Id -eq 111 -or $_.Id -eq 322 -or $_.Id -eq 328 -or $_.Id -eq 330)} |
    Select TimeCreated,TaskDisplayName,Id

Write-Host
pause

<#
Here are all task related event ids

100	Task Started
101	Task Start Failed
102	Task completed
103	Action start failed
106	Task registered
107	Task triggered on scheduler
108	Task triggered on event
110	Task triggered by user
111	Task terminated
118	Task triggered by computer startup
119	Task triggered on logon
129	Created Task Process
135	Launch condition not met, machine not idle
140	Task registration updated
141	Task registration deleted
142	Task disabled
200	Action started
201	Action completed
203	Action failed to start
301	Task engine properly shut down
310	Task Engine started
311	Task Engine failed to start
314	Task Engine idle
317	Task Engine started
318	Task engine properly shut down
319	Task Engine received message to start task
322	Launch request ignored, instance already running
328	Task stopping due to computer not idle
329	Task stopping due to timeout reached
330	Task stopping due to user request
332	Launch condition not met, user not logged-on
400	Service started
411	Service signaled time change
700	Compatibility module started

#>