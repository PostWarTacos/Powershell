function Test-DirsMatch {
    param (
        [Parameter(Mandatory)][string]$PathA,
        [Parameter(Mandatory)][string]$PathB,
        [ValidateSet("MD5","SHA1","SHA256")][string]$Algorithm = "SHA256"
    )

    $zipA = New-TemporaryFile
    $zipB = New-TemporaryFile

    try {
        Compress-Archive -Path "$PathA\*" -DestinationPath $zipA.FullName -Force
        Compress-Archive -Path "$PathB\*" -DestinationPath $zipB.FullName -Force

        $hashA = Get-FileHash -Path $zipA.FullName -Algorithm $Algorithm
        $hashB = Get-FileHash -Path $zipB.FullName -Algorithm $Algorithm

        return ($hashA.Hash -eq $hashB.Hash)
    }
    finally {
        Remove-Item $zipA.FullName, $zipB.FullName -Force -ErrorAction SilentlyContinue
    }
}
