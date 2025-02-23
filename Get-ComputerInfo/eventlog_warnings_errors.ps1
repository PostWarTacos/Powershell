<#
Write a script that will pull the newest 100 Warnings or Errors from every eventlog.
Export the values to an interactive GUI within Powershell. Don't forget to include the Logname for each entry. Hint: PSObject
#>

$logs = (Get-EventLog *).Log
$warnings = Foreach($log in $logs){
    $entries = Get-EventLog -Newest 100 -LogName $log -After "3/9/2021 10:00:00"
    $i = 0
    foreach($entry in $entries){
        $i = $i + 1
        $OutputObj  = New-Object -Type PSObject
        $OutputObj | Add-Member -MemberType NoteProperty -Name Number -Value $i
        $OutputObj | Add-Member -MemberType NoteProperty -Name LogName -Value $log
        $OutputObj | Add-Member -MemberType NoteProperty -Name TimeGenerated -Value $entry.TimeGenerated
        $OutputObj | Add-Member -MemberType NoteProperty -Name EntryType -Value $entry.EntryType
        $OutputObj | Add-Member -MemberType NoteProperty -Name Message -Value $entry.Message
        $OutputObj
    }
}
$warnings | Out-GridView