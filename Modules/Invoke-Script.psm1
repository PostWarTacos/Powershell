function Invoke-Script(){
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $computerName,
        
        [Parameter(Mandatory)]
        [String]
        $filePath
    )

    $session = New-PSSession -ComputerName $computerName

    # Execute it remotely
    Invoke-Command -Session $session -FilePath $filePath

    # Clean up session
    Remove-PSSession $session
}