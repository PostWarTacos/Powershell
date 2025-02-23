Set-Variable -Name "PatchShare" -Value "\\189aw-fs-02\GLOBAL\NCC\TCNOs\_test"
Set-Variable -Name "BaseOrganizationalUnit" -Value "OU=Little Rock ANG,OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL"

Set-Variable -Name "InitialHostsDirectory" -Value "$env:USERPROFILE\Desktop"
Set-Variable -Name "Patches" -Value (Get-ChildItem -Path "$PatchShare" -Directory)
Set-Variable -Name "CurrentRootPath" -Value (Split-Path -Parent $($MyInvocation.MyCommand.Path))
Set-Variable -Name "JobMonitorFrequency" -Value 200

Function Get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

Function Start-PatchJob {
    #Select file for hosts
    IF ($RadioButton11.Checked -eq $true) {
        IF ((new-object -ComObject wscript.shell).Popup("Plese select your hosts file.",0,"Done",0x1) -eq 2) {
            BuildScriptGUI
            Set-Variable -Name "Continue" -Value $false -Scope Script; Return
        }
        $HostFile = Get-FileName -initialDirectory "$InitialHostsDirectory"
        Set-Variable -Name "HostNames" -Value (Get-Content -Path "$HostFile") -Scope Script
    }
    
    #Query ADUC for hosts
    IF ($RadioButton12.Checked -eq $true) {
        Import-Module -Name ActiveDirectory
        Set-Variable -Name "HostNames" -Value ((Get-ADComputer -Filter * -SearchBase $BaseOrganizationalUnit).Name | Where { $_ -notmatch "CNF:" }) -Scope Script
    }
    
    #Direct Input of hosts
    IF ($RadioButton13.Checked -eq $true) {
        (new-object -ComObject wscript.shell).Popup("Feature not yet implemented",0,"Done")
        BuildScriptGUI
        Set-Variable -Name "Continue" -Value $false -Scope Script; Return
    }

    #Count Hosts
    Set-Variable -Name "HostCount" -Value (($HostNames).Count)

    If ( $HostCount -eq 0 ) {
        (new-object -ComObject wscript.shell).Popup("No Hosts Found to Patch.",0,"Done")
        BuildScriptGUI
        Set-Variable -Name "Continue" -Value $false -Scope Script; Return
    } ELSE {
        IF ((new-object -ComObject wscript.shell).Popup("Going to push patch to $HostCount host(s).",0,"Done",0x1) -eq 2) {
            BuildScriptGUI
            Set-Variable -Name "Continue" -Value $false -Scope Script; Return
        }
    }

    #Set Selected Patch
    IF ($DropDownBox1.SelectedItem -eq $null) {
        (new-object -ComObject wscript.shell).Popup("You did not select a valid Patch",0,"Done")
        BuildScriptGUI
        Return
    } ELSE {
        $host.ui.RawUI.WindowTitle = "$($DropDownBox1.SelectedItem)"
        Set-Variable -Name "PatchPath" -Value "$PatchShare\$($DropDownBox1.SelectedItem)" -Scope Script
    }

    #Set Max Connections
    IF ($DropDownBox2.SelectedItem -eq $null) {
        Set-Variable -Name "MaxConnections" -Value 10 -Scope Script
    } ELSE {
        Set-Variable -Name "MaxConnections" -Value ($DropDownBox2.SelectedItem) -Scope Script
    }

    #Set Job Timeout
    IF ($DropDownBox3.SelectedItem -eq $null) {
        IF ((new-object -ComObject wscript.shell).Popup("Job timeout not selected. Setting Defaults:`n`tJob Timeout = 180 Minutes`n`tJob Behavior = Monitored",0,"Done",0x1) -eq 2) {
            BuildScriptGUI
            Return
        }
        Set-Variable -Name "MaxJobAge" -Value 180 -Scope Script
    } ELSE {
        Set-Variable -Name "MaxJobAge" -Value ($DropDownBox3.SelectedItem) -Scope Script
    }

    #Test for Log Folder.
    IF ( ! ( Test-Path "$env:USERPROFILE\Desktop\00-Finished-Computers" ) ) {
        New-Item -Path "$env:USERPROFILE\Desktop\00-Finished-Computers" -ItemType directory
    }

    #Function for fast ping.
    Function Ping-Check {
        trap {$false; continue}
        $Timeout = 500
        $Object = New-Object system.Net.NetworkInformation.Ping
        (($Object.Send("$HostName", $Timeout)).Status -eq 'Success')
    }

    Set-Variable -Name "PatchedHostList" -Value ((Get-ChildItem -Path "$env:USERPROFILE\Desktop\00-Finished-Computers").Name) -Scope Script

    #Set script block to wait
    IF ($RadioButton21.Checked -eq $true) {
        $JobScriptBlock = {
            param($HostName,$PatchPath)
            Write-host -Object "HostName is $HostName"
            Write-host -Object "PatchPath is $PatchPath"
        }
    }

    #Set script block to NOT wait
    IF ($RadioButton22.Checked -eq $true) {
        $JobScriptBlock = {
            param($HostName,$PatchPath)
            Write-host -Object "HostName is $HostName"
            Write-host -Object "PatchPath is $PatchPath"
        }
    }

    #Set Tracking Vars to 0
    $AlreadyPatched = 0
    $NoICMPReply = 0
    $StartedPatching = 0
    $Count = 0

    Foreach ($HostName in $HostNames) {
        $Count += 1
        Write-Progress -Activity "Patching" -Status "Please Wait..." -PercentComplete ($Count/$HostCount*100)
        $HostUniqueID = "$(Get-Date -Format s) - $HostName"
        IF ($HostName -in $PatchedHostList) {
            Write-Host -Object "$HostUniqueID has already been patched" -ForegroundColor Green
            $AlreadyPatched ++
        } ELSE {
            IF (Ping-Check) {
		        While ( (Get-Job -State Running).count -ge $MaxConnections ) {
			        Start-Sleep -Milliseconds $JobMonitorFrequency
			    }
                    
                    Copy-Item -Path $PatchPath -Destination "\\$Hostname\C$\Program Files (x86)\temp" -recurse -Force
                    $Patch = Get-FileName "\\$Hostname\C$\Program Files (x86)\temp"
                    $command = 'cmd.exe /c ' + $Patch + ' /s'
                    $process = [WMICLASS] "\\$HostName\ROOT\CIMV2:win32_process"
                    $process.Create($command)

		        Start-Job -ScriptBlock $JobScriptBlock -Name $HostUniqueID -ArgumentList $HostName,$PatchPath | Out-Null
		        Write-Host -Object "$HostUniqueID has begun being patched in the background"
                $StartedPatching ++
            } ELSE {
                Write-Host -Object "$HostUniqueID has failed to reply to ICMP request." -ForegroundColor Yellow
                $NoICMPReply ++
                }
            $RunningJobs = Get-Job -State Running
            IF ($RunningJobs.count -gt 0) {
                $StopJobsBefore = (Get-Date).AddMinutes(-$MaxJobAge)
                $RunningJobs.Name | ForEach-Object -Process {
                    IF ($StopJobsBefore -gt (($_ -split " - ")[0])) {
                        Stop-Job -Name $_
                        Write-Host -Object "Stopped patching of $(($_ -split " - ")[1]) due to taking too long." -ForegroundColor Red
                    }
                }
            }
        }
    }
    Write-Progress -Activity "Patching" -Completed

    $RemainingJobs = (Get-Job -State Running).Count

    While ( (Get-Job -State Running).count -gt 0 ) {
        $RunningJobs = Get-Job -State Running
        $StopJobsBefore = (Get-Date).AddMinutes(-$MaxJobAge)
        Write-Progress -Activity "Waiting for $RemainingJobs jobs to complete" -Status "$($RunningJobs.count) jobs remaining." -PercentComplete (($RemainingJobs-($RunningJobs.count))/$RemainingJobs*100)
        $RunningJobs.Name | ForEach-Object -Process {
            IF ($StopJobsBefore -gt (($_ -split " - ")[0])) {
                Stop-Job -Name $_
                Write-Host -Object "Stopped patching of $(($_ -split " - ")[1]) due to taking too long." -ForegroundColor Red
            }
        }
        Start-Sleep -Seconds 1
    }

    Write-Progress -Activity "Waiting for $RemainingJobs jobs to complete" -Completed

    Write-Host -Object "$AlreadyPatched - Hosts were already logged in the log folder."
    Write-Host -Object "$NoICMPReply - Hosts did not ping and were skipped."
    Write-Host -Object "$StartedPatching - Hosts were attempted to be patched during this session."
}

Function BuildScriptGUI {
    #Start Load Assembly###########
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    #End Load Assembly#############

    #Start Form####################
    $Form = New-Object System.Windows.Forms.Form
    #Set-Variable -Name "Form" -Value (New-Object System.Windows.Forms.Form) -Scope Script
    $Form.Size = New-Object System.Drawing.Size(380,240)
    $Form.Text = "Powershell GUI Patch Script."
    #End Form######################

    #Start Dropboxs################
    $DropDownBox1 = New-Object System.Windows.Forms.ComboBox
    $DropDownBox1.Location = New-Object System.Drawing.Size(20,20)
    $DropDownBox1.Size = New-Object System.Drawing.Size(150,20)
    $DropDownBox1.text = "Select Patch to Push."
    #$DropDownBox1.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $DropDownBox1.DropDownHeight = 200
    $DropDownBox1.Items.AddRange($Patches.BaseName)
    $Form.Controls.Add($DropDownBox1)

    $DropDownBox2List=@(1,2,5,10,15,20,25,40,60)
    $DropDownBox2 = New-Object System.Windows.Forms.ComboBox
    $DropDownBox2.Location = New-Object System.Drawing.Size(20,60)
    $DropDownBox2.Size = New-Object System.Drawing.Size(150,20)
    $DropDownBox2.Text = "Select Max Connections."
    #$DropDownBox2.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $DropDownBox2.DropDownHeight = 200
    $DropDownBox2.Items.AddRange($DropDownBox2List)
    $Form.Controls.Add($DropDownBox2)

    $DropDownBox3List=@(1,2,5,15,30,60,90,120,180)
    $DropDownBox3 = New-Object System.Windows.Forms.ComboBox
    $DropDownBox3.Location = New-Object System.Drawing.Size(20,100)
    $DropDownBox3.Size = New-Object System.Drawing.Size(150,20)
    $DropDownBox3.Text = "Select Job Timeout (Min)"
    #$DropDownBox3.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $DropDownBox3.DropDownHeight = 200
    $DropDownBox3.Items.AddRange($DropDownBox3List)
    $DropDownBox3.add_SelectedIndexChanged({
        $groupBox2.Enabled = $true
    })
    $Form.Controls.Add($DropDownBox3)
    #End Dropboxs##################

    #Start Group Boxes#############
    $groupBox1 = New-Object System.Windows.Forms.GroupBox
    $groupBox1.Location = New-Object System.Drawing.Size(190,10)
    $groupBox1.size = New-Object System.Drawing.Size(150,100)
    $groupBox1.text = "Source of Hosts:"
    $Form.Controls.Add($groupBox1)

    $groupBox2 = New-Object System.Windows.Forms.GroupBox
    $groupBox2.Location = New-Object System.Drawing.Size(190,115)
    $groupBox2.size = New-Object System.Drawing.Size(150,75)
    $groupBox2.text = "Disconnect remote tasks at"
    $groupBox2.Enabled = $false
    $Form.Controls.Add($groupBox2)
    #End Group Boxes###############

    #Start Radio Buttons###########
    $RadioButton11 = New-Object System.Windows.Forms.RadioButton
    $RadioButton11.Location = new-object System.Drawing.Point(15,15)
    $RadioButton11.size = New-Object System.Drawing.Size(120,20)
    $RadioButton11.Checked = $true
    $RadioButton11.Text = "Use Hosts.txt"
    $groupBox1.Controls.Add($RadioButton11)

    $RadioButton12 = New-Object System.Windows.Forms.RadioButton
    $RadioButton12.Location = new-object System.Drawing.Point(15,45)
    $RadioButton12.size = New-Object System.Drawing.Size(120,20)
    $RadioButton12.Text = "Use ADUC"
    $groupBox1.Controls.Add($RadioButton12)

    $RadioButton13 = New-Object System.Windows.Forms.RadioButton
    $RadioButton13.Location = new-object System.Drawing.Point(15,75)
    $RadioButton13.size = New-Object System.Drawing.Size(120,20)
    $RadioButton13.Text = "Prompt for Input"
    $groupBox1.Controls.Add($RadioButton13)

    $RadioButton21 = New-Object System.Windows.Forms.RadioButton
    $RadioButton21.Location = new-object System.Drawing.Point(15,15)
    $RadioButton21.size = New-Object System.Drawing.Size(125,20)
    $RadioButton21.Checked = $true
    $RadioButton21.Text = "Finish. Monitored."
    $groupBox2.Controls.Add($RadioButton21)

    $RadioButton22 = New-Object System.Windows.Forms.RadioButton
    $RadioButton22.Location = new-object System.Drawing.Point(15,45)
    $RadioButton22.size = New-Object System.Drawing.Size(125,20)
    $RadioButton22.Text = "Start. Unattended."
    $groupBox2.Controls.Add($RadioButton22)
    #End Radio Buttons#############

    #Start Buttons#################
    $Button = New-Object System.Windows.Forms.Button
    $Button.Location = New-Object System.Drawing.Size(20,140)
    $Button.Size = New-Object System.Drawing.Size(150,40)
    $Button.Text = "Begin Patching"
    $Button.Add_Click({
        $Form.Dispose()
        Start-PatchJob})
    $Form.Controls.Add($Button)
    #End Buttons###################

    $Form.Add_Shown({$Form.Activate()})
    #[void] $Form.ShowDialog()
    $Form.ShowDialog()
}

BuildScriptGUI