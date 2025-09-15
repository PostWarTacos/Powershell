function Add-NKAGComputer {

    <#
    .SYNOPSIS
        Add computer to Active Directory

    .DESCRIPTION
        Add computer to Active Directory that fits within the unit naming
        convention. This is determined using a regex string.

    .PARAMETER ComputerName
        Name of the computer to add to Active Directory
        
    .PARAMETER Building
        Name of the building where the computer exists

    .PARAMETER Room
        Number of the room where the computer exists

    .PARAMETER Unit
        Unit where the computer exists. This will update the o attribute
        on the computer account

    .EXAMPLE
        Add-NKAGComputer -ComputerName NKAGL-CF0001 -Building '1' -Room '1' -Unit '189 CF'
       
    .INPUTS
        System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidatePattern("^nkag[ltw]-[acefjlmors1][adefgimoprswx9][cghnostx0]\d{3}$")]
        [ValidateNotNullOrEmpty()]
        [Alias('computer', 'workstation', 'cn')]
        [string[]] $ComputerName,

        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Building,

        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Room,

        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [ValidateSet('154 TRS', '154 WF', '189 AW', '189 CES', '189 FM',
                     '189 FSS', '189 LRS', '189 MDG', '189 MSG', '189 MXG', 
                     '189 OG', '189 SC', '189 SFS', 'AR ANG', 'AR STHQ')]
        [string] $Unit
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        $centralPath = 'OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
        $groupToAddToDomain = "CN=GLS_Little Rock ANG_CFP-CSA,OU=Little Rock ANG Security Groups,OU=Little Rock ANG,$centralPath"
    }# begin

    process {
        foreach ($computer in $ComputerName) {
            $distinguishedName = "CN=$($computer.ToUpper()),OU=Little Rock ANG Computers,OU=Little Rock ANG,$centralPath"

            $props = @{DistinguishedName = $distinguishedName
                        Location = "BLDG: $Building; RM: $Room"
                        AccountDisabled = $false
                        AccountThatCanAddComputerToDomain = $groupToAddToDomain
                        L = 'Little Rock ANG'
                        O = $Unit}

            if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on target `"$computer`"",
                                        "Are you sure you want to add $computer`?",
                                        "Adding Computer")) {
                Write-Verbose "Adding $computer to Little Rock ANG Computers OU"
                Add-DRAComputer @draProps -Properties $props -Verbose:$false | Out-Null
            }# if shouldProcess
        }# foreach computer
    }# process
}# function

function Add-NKAGGroup {

    <#
    .SYNOPSIS
       Add group to Active Directory

    .DESCRIPTION
       Add group to Active Directory that fits within the AFNet naming
       convention. This is determined using the AFNet naming convention TO.

    .PARAMETER GroupName
        Name of the group to add to Active Directory

    .PARAMETER Unit
        Unit where the group exists. This will be added to the name of
        the group
        
    .PARAMETER OfficeSymbol
        Office symbol in the unit where the group exists. This parameter
        is optional

    .PARAMETER GroupPurpose
        Purpose of the group. This will be added to the name of the group

    .PARAMETER Description
        Description of the group. This will be added to the description
        field of the group in Active Directory

    .EXAMPLE
       Add-NKAGGroup -GroupName '189CF_TESTGROUP' -Description 'Test Group'

    .EXAMPLE
       Add-NKAGGroup -GroupName '189CF.SCOO_TESTGROUP'
       
    .EXAMPLE
       Add-NKAGGroup -Unit '189 CF' -OfficeSymbol 'SCOO' -GroupPurpose 'TESTGROUP'
       
    .INPUTS
       System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string[]] $GroupName,

        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName,
                   ParameterSetName = 'Purpose')]
        [ValidateSet('189 AMXS','189 AW', '189 CES', '189 CF', '189 CPTF',
                     '189 FSS', '189 LRS', '189 MDG', '189 MXG', 
                     '189 MXS', '189 OG', '189 OSS', '189 SFS')]
        [string] $Unit,

        [Parameter(ValueFromPipelineByPropertyName,
                   ParameterSetName = 'Purpose')]
        [ValidateNotNullOrEmpty()]
        [string] $OfficeSymbol,

        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName,
                   ParameterSetName = 'Purpose')]
        [ValidateNotNullOrEmpty()]
        [string] $GroupPurpose,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Description
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        if ($PSCmdlet.ParameterSetName -eq 'Purpose') {
            if ($PSBoundParameters.ContainsKey('OfficeSymbol')) {
                $GroupName = "$($Unit.Replace(' ','')).$OfficeSymbol`_$GroupPurpose"
            }
            else {
                $GroupName = "$($Unit.Replace(' ',''))`_$GroupPurpose"
            }
        }# if parameterSetName
    }# begin

    process {
        foreach ($group in $GroupName) {
            $centralPath = 'OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
            $distinguishedName = "CN=$group,OU=Little Rock ANG Security Groups,OU=Little Rock ANG,$centralPath"

            if ($PSBoundParameters.ContainsKey('Description')) {
                $props = @{DistinguishedName = $distinguishedName
                            Description = $Description}
            }
            else {
                $props = @{DistinguishedName = $distinguishedName}
            }

            if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on target `"$group`"",
                                        "Are you sure you want to add $group`?",
                                        "Adding Group")) {
                Write-Verbose "Adding $group to Little Rock ANG Security Groups OU"
                Add-DRAGroup @draProps -GroupType Security -GroupScope Global -Properties $props -Verbose:$false | Out-Null
            }# if shouldProcess
        }# foreach group
    }# process
}# function

function Remove-NKAGComputer {

    <#
    .SYNOPSIS
        Remove computer from Active Directory

    .DESCRIPTION
        Remove computer from Active Directory that fits within the unit naming
        convention. This is determined using a regex string.

    .PARAMETER ComputerName
        Name of the computer to remove from Active Directory

    .EXAMPLE
        Remove-NKAGComputer -ComputerName 'NKAGL-CF0001'
       
    .INPUTS
        System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidatePattern("^nkag[ltw]-")]
        [ValidateNotNullOrEmpty()]
        [Alias('computer', 'workstation', 'cn')]
        [string[]] $ComputerName
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        $centralPath = 'OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
    }# begin

    process {
        foreach ($computer in $ComputerName) {
            try {
                $distinguishedName = "CN=$computer,OU=Little Rock ANG Computers,OU=Little Rock ANG,$centralPath"
        
                if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on target `"$computer`"",
                                            "Are you sure you want to remove $computer`?",
                                            "Removing Computer")) {
                    Write-Verbose "Removing $computer from Little Rock ANG Computers OU"
                    Remove-DRAComputer @draProps -Identifier $distinguishedName -Verbose:$false -ErrorAction Stop -Force | Out-Null
                }# if shouldProcess
            }
            catch {
                Write-Warning "ComputerName: $computer doesn't exist"
            }# try catch
        }# foreach computer
    }# process
}# function

function Remove-NKAGGroup {

    <#
    .SYNOPSIS
        Remove group from Active Directory

    .DESCRIPTION
        Remove group from Active Directory that fits within the AFNet naming
        convention. This is determined using the AFNet naming convention TO.
    
    .PARAMETER GroupName
        Name of the group to remove from Active Directory

    .EXAMPLE
        Remove-NKAGGroup -GroupName '189CF_TESTGROUP'
       
    .INPUTS
        System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $GroupName
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        $centralPath = 'OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
    }# begin

    process {
        foreach ($group in $GroupName) {
            try {
                $distinguishedName = "CN=$group,OU=Little Rock ANG Security Groups,OU=Little Rock ANG,$centralPath"
        
                if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on target `"$group`"",
                                            "Are you sure you want to remove $group`?",
                                            'Removing Group')) {
                 Write-Verbose "Removing $group from Little Rock ANG Security Groups OU"
                 Remove-DRAGroup @draProps -Identifier $distinguishedName -Verbose:$false -ErrorAction Stop -Force | Out-Null
                }# if shouldProcess
            }
            catch [System.Management.Automation.PSInvalidOperationException] {
                Write-Warning "GroupName: $group doesn't exist"
            }# try catch
        }# foreach computer
    }# process
}# function

function Get-NKAGGroupMembers {

    <#
    .SYNOPSIS
       Get group members from a group in Active Directory

    .DESCRIPTION
       Get group members from a group in Active Directory. It outputs group
       names for groups or GigIDs for users.

    .PARAMETER GroupName
        Name of the group to get members from. Pulls from members
        tab of the group in Active Directory

    .EXAMPLE
       Get-NKAGGroupMembers -GroupName '189CF_TESTGROUP'

    .INPUTS
       System.String
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $GroupName
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        $centralPath = 'OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
    }# begin

    process {
        foreach ($group in $GroupName) {
            try {
                $distinguishedName = "CN=$group,OU=Little Rock ANG Security Groups,OU=Little Rock ANG,$centralPath"

                Write-Verbose "Finding members in '$group' from Little Rock ANG Security Groups OU"
                Get-DRAGroupMembers @draProps -Identifier $distinguishedName -Verbose:$false -ErrorAction Stop | 
                    Select-Object -ExpandProperty Items | Select-Object -Property @{n='GroupMembers'; e={$_.samAccountName}}
            }
            catch [System.Management.Automation.PSInvalidOperationException] {
                Write-Warning "GroupName: '$group' doesn't exist"
            }# try catch
        }# foreach group
    }# process
}# function

function Get-NKAGGroupMemberOf {

    <#
    .SYNOPSIS
        Get members of a group in Active Directory

    .DESCRIPTION
        Get members of a group in Active Directory based on the class
        of the members. If group class is chosen the members will 
        only contain groups.
    
    .PARAMETER GroupName
        Name of the group to get members from. Pulls from the members
        of tab of the group in Active Directory

    .PARAMETER Class
        Class type for the group member in the member of tab.

    .EXAMPLE
        Get-NKAGGroupMemberOf -GroupName '189CF_TESTGROUP' -Class Group

    .INPUTS
        System.String
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $GroupName,

        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [ValidateSet('Computer', 'Contact',
                     'Group', 'User')]
        [string] $Class
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }
    }# begin

    process {
        foreach ($group in $GroupName) {
            try {
                Write-Verbose "Finding members in '$group' from Little Rock ANG Security Groups OU"
                Get-DRAGroupMembership @draProps -Identifier $group -IdentifierClass $Class -Verbose:$false -ErrorAction Stop | 
                    Select-Object -ExpandProperty Items | Select-Object -Property @{n='GroupMemberOf'; e={$_.samAccountName}}
            }
            catch [System.Management.Automation.PSInvalidOperationException] {
                Write-Warning "GroupName: '$group' doesn't exist or no members exist with Class: '$Class'"
            }# try catch
        }# foreach computer
    }# process
}# function

function Restore-NKAGComputer {
    
    <#
    .SYNOPSIS
        Restore computer from Active Directory recycle bin

    .DESCRIPTION
        Restore computer from Active Directory recycle bin that has 
        been recently deleted

    .PARAMETER ComputerName
        Name of the computer to restore from Active Directory
        recycle bin

    .EXAMPLE
        Restore-NKAGComputer -ComputerName 'NKAGL-CF0001'

    .INPUTS
        System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidatePattern("^nkag[ltw]-\d{3}$")]
        [ValidateNotNullOrEmpty()]
        [string] $ComputerName
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }
    }# begin

    process {
        try {
            if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on target `"$ComputerName`"",
                                        "Are you sure you want to restore $ComputerName`?",
                                        "Restoring Computer")) {
                Write-Verbose "Restoring $ComputerName from Active Directory recycle bin"
                Restore-DRAComputer @draProps -Identifier $ComputerName -Verbose:$false -ErrorAction Stop | Out-Null
            }# if shouldProcess
        }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Write-Warning "ComputerName: '$ComputerName' doesn't exist in the Recycle Bin"
        }# try catch
    }# process
}# function

function Restore-NKAGGroup {
    
    <#
    .SYNOPSIS
       Restore group from Active Directory recycle bin

    .DESCRIPTION
       Restore group from Active Directory recycle bin that has 
       been recently deleted
    
    .PARAMETER ComputerName
        Name of the group to restore from Active Directory
        recycle bin

    .EXAMPLE
       Restore-NKAGGroup -GroupName 'TESTGROUP'

    .INPUTS
       System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $GroupName
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }
    }# begin

    process {
        try {
            if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on target `"$GroupName`"",
                                        "Are you sure you want to restore $GroupName`?",
                                        "Restoring Group")) {
                Write-Verbose "Restoring $GroupName from Active Directory recycle bin"
                Restore-DRAComputer @draProps -Identifier $GroupName -Verbose:$false -ErrorAction Stop | Out-Null
            }# if shouldProcess
        }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Write-Warning "GroupName: '$GroupName' doesn't exist in the Recycle Bin"
        }# try catch
    }# process
}# function

function Restore-NKAGUser {
        
    <#
    .SYNOPSIS
        Restore user from Active Directory recycle bin

    .DESCRIPTION
        Restore user from Active Directory recycle bin that has 
        been recently deleted
    
    .PARAMETER Edipi
        Edipi of the user to restore from Active Directory
        recycle bin

    .EXAMPLE
        Restore-NKAGUser -Edipi '1234567890'

    .INPUTS
        System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Edipi
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        $searchBase = 'OU=Little Rock ANG,OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
    }# begin

    process {
        try {
            $user = Get-ADUser -Filter "employeeID -eq '$Edipi'" -SearchBase $searchBase -ErrorAction Stop

            if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on target `"$Edipi`"",
                                        "Are you sure you want to restore $Edipi`?",
                                        "Restoring User")) {
                Write-Verbose "Restoring $Edipi from Active Directory recycle bin"
                Restore-DRAUser @draProps -Identifier $user.Name -Verbose:$false -ErrorAction Stop | Out-Null
            }# if shouldProcess
        }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Write-Warning "User: '$Edipi' doesn't exist in the Recycle Bin"
        }# try catch
    }# process
}# function

function Set-NKAGComputer {
    
    <#
    .SYNOPSIS
        Modify computer account in Active Directory

    .DESCRIPTION
        Modify o attribute for computer account in Active Directory.

    .PARAMETER ComputerName
        Computer to modify in Active Directory

    .PARAMETER Unit
        Unit where the computer exists. This will update the o attribute
        on the computer account
    
    .EXAMPLE
        Set-NKAGComputer -ComputerName 'NKAGL-CF0001' -Unit '189 CF'

    .INPUTS
        System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ComputerName,

        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [ValidateSet('189 AMXS','189 ASOS', '189 CES', '189 CF', '189 CPTF',
                     '189 FSS', '189 FW', '189 LRS', '189 MDG', '189 MXG', 
                     '189 MXO', '189 MXS', '189 OG', '189 OSS', '189 SFS', 
                     '190 FS', '224 COS', '226 RANS', '302 AEG')]
        [string] $Unit
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        $props = @{'O' = $Unit}
    }# begin

    process {
        try {
            if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on target `"$ComputerName`"",
                                        "Are you sure you want to modify $ComputerName`?",
                                        "Modifying Computer")) {
                Write-Verbose "Modifying computer: '$ComputerName'"
                Set-DRAComputer @draProps -Identifier $ComputerName -Properties $props -Verbose:$false -ErrorAction Stop | Out-Null
            }# if shouldProcess
        }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Write-Warning "User: '$Edipi' doesn't exist."
        }# try catch
    }# process
}# function

function Set-NKAGUser {
    
    <#
    .SYNOPSIS
        Modify user account in Active Directory

    .DESCRIPTION
        Modify o attribute, provision, or deprovision user
        account in Active Directory.

    .PARAMETER Edipi
        Edipi of the user to modify from Active Directory

    .PARAMETER Unit
        Unit where the user exists. This will update the o attribute
        on the user account

    .PARAMETER Deprovision
        Switch to deprovision account. This moves user account
        from unit OU to the People OU

    .PARAMETER Provision
        Switch to provision account. This moves user account from
        People OU to the unit OU

    .EXAMPLE
        Set-NKAGUser -Edipi '1234567890' -Unit '189 CF'
    
    .EXAMPLE
        Set-NKAGUser -Edipi '1234567890' -Unit '189 CF' -Provision
    
    .EXAMPLE
        Set-NKAGUser -Edipi '1234567890' -Unit '189 CF' -Deprovision

    .INPUTS
        System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Edipi,

        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [ValidateSet('189 AMXS','189 ASOS', '189 CES', '189 CF', '189 CPTF',
                     '189 FSS', '189 FW', '189 LRS', '189 MDG', '189 MXG', 
                     '189 MXO', '189 MXS', '189 OG', '189 OSS', '189 SFS', 
                     '190 FS', '224 COS', '226 RANS', '302 AEG')]
        [string] $Unit,

        [Parameter(ParameterSetName = 'Deprovision')]
        [switch] $Deprovision,

        [Parameter(ParameterSetName = 'Provision')]
        [switch] $Provision
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        $searchBaseBases = 'OU=Little Rock ANG,OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
        $searchBasePeople = 'OU=People,OU=AFDS,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'

        $props = @{'O' = $Unit}

        if ($PSBoundParameters.ContainsKey('Deprovision')) {
            $verbose = "Deprovisioning $Edipi from the Base OU"
            $user = Get-ADUser -Filter "employeeID -eq '$Edipi'" -SearchBase $searchBaseBases -ErrorAction Stop
            $props.Add('draVA-SubOperation', 'De-Provision User')
        }
        elseif ($PSBoundParameters.ContainsKey('Provision')) {
            $verbose = "Provisioning $Edipi from the People OU"
            $user = Get-ADUser -Filter "employeeID -eq '$Edipi'" -SearchBase $searchBasePeople -ErrorAction Stop
            $props.Add('draVA-SubOperation', 'User Account Without Mailbox')
            $props.Add('Company', 'USAF')
            $props.Add('Department', 'ANG')
            $props.Add('ExtensionAttribute5', '1')
            $props.Add('L', 'Little Rock ANG')
        }
        else {
            $verbose = "Modifying User: '$Edipi' from Active Directory"
        }
    }# begin

    process {
        try {
            if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on target `"$Edipi`"",
                                        "Are you sure you want to modify $Edipi`?",
                                        "Modifying User")) {
                Write-Verbose "$verbose"
                Set-DRAUser @draProps -Identifier $user.Name -Properties $props -Verbose:$false -ErrorAction Stop | Out-Null
            }# if shouldProcess
        }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Write-Warning "User: '$Edipi' doesn't exist."
        }# try catch
    }# process
}# function

function Enable-NKAGUser {
        
    <#
    .SYNOPSIS
        Enable user account in Active Directory

    .DESCRIPTION
        Enable user account in Active Directory

    .PARAMETER Edipi
        Edipi of the user to enable in Active Directory

    .EXAMPLE
        Enable-NKAGUser -Edipi '1234567890'

    .INPUTS
        System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Edipi
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        $searchBase = 'OU=Little Rock ANG,OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
    }# begin

    process {
        try {
            $user = Get-ADUser -Filter "employeeID -eq '$Edipi'" -SearchBase $searchBase -ErrorAction Stop

            if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on target `"$Edipi`"",
                                        "Are you sure you want to enable $Edipi`?",
                                        "Enabling User")) {
                Write-Verbose "Enabling $Edipi in Little Rock ANG Users OU"
                Enable-DRAUser @draProps -Identifier $user.Name -Verbose:$false -ErrorAction Stop | Out-Null
            }# if shouldProcess
        }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Write-Warning "User: '$Edipi' doesn't exist"
        }# try catch
    }# process
}# function

function Disable-NKAGUser {
            
    <#
    .SYNOPSIS
        Disable user account in Active Directory

    .DESCRIPTION
        Disable user account in Active Directory

    .PARAMETER Edipi
        Edipi of the user to disable in Active Directory

    .EXAMPLE
        Disable-NKAGUser -Edipi '1234567890'

    .INPUTS
        System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Edipi
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        $searchBase = 'OU=Little Rock ANG,OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
    }# begin

    process {
        try {
            $user = Get-ADUser -Filter "employeeID -eq '$Edipi'" -SearchBase $searchBase -ErrorAction Stop

            if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on target `"$Edipi`"",
                                        "Are you sure you want to disable $Edipi`?",
                                        "Disabling User")) {
                Write-Verbose "Disabling $Edipi in Little Rock ANG Users OU"
                Disable-DRAUser @draProps -Identifier $user.Name -Verbose:$false -Confirm:$false -Force -ErrorAction Stop | Out-Null
            }# if shouldProcess
        }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Write-Warning "User: '$Edipi' doesn't exist"
        }# try catch
    }# process
}# function

function Add-NKAGGroupMembers {
                
    <#
    .SYNOPSIS
        Add members to group in Active Directory

    .DESCRIPTION
        Add group, computer, or user accounts to a group
        in Active Directory

    .PARAMETER GroupName
        Group to add members to in Active Directory
    
    .PARAMETER ComputerName
        Computer to add to group in Active Directory
    
    .PARAMETER Group
        Group to add to group in Active Directory
    
    .PARAMETER Edipi
        Edipi of the user to add to group in Active Directory

    .EXAMPLE
        Add-NKAGGroupMembers -GroupName '189CF_TESTGROUP' -ComputerName 'NKAGL-CF0001'

    .EXAMPLE
        Add-NKAGGroupMembers -GroupName '189CF_TESTGROUP' -Edipi '1234567890', '0987654321' -Group '189CF_TESTGROUP1'

    .INPUTS
        System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $GroupName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $ComputerName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Group,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Edipi
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        $searchBase = 'OU=Little Rock ANG,OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
    }# begin

    process {
        try {
            $users = foreach ($id in $edipi) {(Get-ADUser -Filter "employeeID -eq '$id'" -SearchBase $searchBase).Name}

            if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on member",
                                        "Are you sure you want to add member(s) to group: '$GroupName'`?",
                                        'Adding member')) {
                Write-Verbose "Adding member(s) to group: '$GroupName'"
                Add-DRAGroupMembers @draProps -Identifier $GroupName -Computers $ComputerName -Groups $Group -Users $users | Out-Null
            }# if shouldProcess
        }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Write-Warning "Member doesn't exist"
        }# try catch
    }# process
}# function

function Remove-NKAGGroupMembers {
            
    <#
    .SYNOPSIS
        Remove members from group in Active Directory

    .DESCRIPTION
        Remove group, computer, or user accounts from a group
        in Active Directory

    .PARAMETER GroupName
        Group to remove members from in Active Directory
    
    .PARAMETER ComputerName
        Computer to remove from group in Active Directory
    
    .PARAMETER Group
        Group to remove from group in Active Directory
    
    .PARAMETER Edipi
        Edipi of the user to remove from group in Active Directory

    .EXAMPLE
        Remove-NKAGGroupMembers -GroupName '189CF_TESTGROUP' -ComputerName 'NKAGL-CF0001'

    .EXAMPLE
        Remove-NKAGGroupMembers -GroupName '189CF_TESTGROUP' -Edipi '1234567890', '0987654321' -Group '189CF_TESTGROUP1'

    .INPUTS
        System.String
    #>

    [cmdletbinding(SupportsShouldProcess,
                   ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $GroupName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $ComputerName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Group,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Edipi
    )

    begin {
        $draProps = @{
            DRARestPort = '8755'
            DRARestServer = 'prpx-ra-001v'
            DRAHostPort = '11192'
            DRAHostServer = 'prpx-ra-001v'
            Domain = 'area52.afnoapps.usaf.mil'
        }

        $searchBase = 'OU=Little Rock ANG,OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
    }# begin

    process {
        try {
            $users = foreach ($id in $edipi) {(Get-ADUser -Filter "employeeID -eq '$id'" -SearchBase $searchBase).Name}

            if ($PSCmdlet.ShouldProcess("Performing the operation `"$($MyInvocation.MyCommand)`" on member",
                                        "Are you sure you want to remove the member(s) from group: '$GroupName'`?",
                                        'Removing member')) {
                Write-Verbose "Removing member(s) from group: '$GroupName'"
                Remove-DRAGroupMembers @draProps -Identifier $GroupName -Computers $ComputerName -Groups $Group -Users $users -Force | Out-Null
            }# if shouldProcess
        }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Write-Warning "Member doesn't exist"
        }# try catch
    }# process
}# function

Export-ModuleMember -Function @('Add-NKAGComputer'
                                'Add-NKAGGroup'
                                'Remove-NKAGComputer'
                                'Remove-NKAGGroup'
                                'Get-NKAGGroupMembers'
                                'Get-NKAGGroupMemberOf'
                                'Restore-NKAGComputer'
                                'Restore-NKAGGroup'
                                'Restore-NKAGUser'
                                'Set-NKAGComputer'
                                'Set-NKAGUser'
                                'Enable-NKAGUser'
                                'Disable-NKAGUser'
                                'Add-NKAGGroupMembers'
                                'Remove-NKAGGroupMembers')