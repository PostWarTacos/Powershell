function Test-DirsMatch {
    param (
        [Parameter(Mandatory)]
        [string]$PathA,

        [Parameter(Mandatory)]
        [string]$PathB,
        
        [ValidateSet("MD5","SHA1","SHA256")][string]$Algorithm = "SHA256"
    )

    $zipA = [System.IO.Path]::ChangeExtension((New-TemporaryFile).FullName, ".zip")
    $zipB = [System.IO.Path]::ChangeExtension((New-TemporaryFile).FullName, ".zip")

    try {
        Compress-Archive -Path "$PathA\*" -DestinationPath $zipA -Force -Verbose
        Compress-Archive -Path "$PathB\*" -DestinationPath $zipB -Force -Verbose

        $hashA = Get-FileHash -Path $zipA -Algorithm $Algorithm
        $hashB = Get-FileHash -Path $zipB -Algorithm $Algorithm

        return ( $hashA.Hash -eq $hashB.Hash )
    }
    finally {
        Remove-Item $zipA, $zipB -Force -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember Test-DirsMatch