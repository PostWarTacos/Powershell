function Measure-CommandClean {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [scriptblock]$ScriptToTest
    )

    # Set up a temporary working directory (auto-cleaned later)
    $tempRoot = Join-Path $env:TEMP "TestRun_$([guid]::NewGuid())"
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    try {
        Push-Location $tempRoot

        $result = Measure-Command {
            & $ScriptToTest
        }

        Pop-Location

        Write-Host "Elapsed time: $($result.TotalSeconds) seconds"
        return $result
    }
    finally {
        Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember Measure-CommandClean