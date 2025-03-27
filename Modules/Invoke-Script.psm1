function Invoke-Script(){
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$ComputerName,
        
        [Parameter(Mandatory)]
        [String]$FilePath
    )

    $session = New-PSSession -ComputerName $ComputerName

    # Execute it remotely
    Invoke-Command -Session $session -FilePath $FilePath

    # Clean up session
    Remove-PSSession $session
}

Export-ModuleMember Invoke-Script