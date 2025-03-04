$taskName = "Check-SCCMHealthTask"  # Replace with the actual task name

Get-WinEvent -FilterXml "<QueryList><Query Id='0' Path='Microsoft-Windows-TaskScheduler/Operational'><Select Path='Microsoft-Windows-TaskScheduler/Operational'>*[EventData/Data[@Name='TaskName']='$taskName']</Select></Query></QueryList>"
