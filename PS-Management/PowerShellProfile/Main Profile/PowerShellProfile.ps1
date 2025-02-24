#
# Create coding directory
#
If ( whoami -like "*wurtzmt*" ){
    $user = "C:\users\wurtzmt"
}
Else {
    $user = $env:USERPROFILE
}

If ( -not ( Test-Path "$user\Documents\Coding" )){
    mkdir "$user\Documents\Coding"
}


#
# PowerShell Profile Auto Git Sync
#
$repoURL = "https://github.com/PostWarTacos/PowerShell.git"
$clonePath = "$user\Documents\Coding\Powershell"

function Sync-GitProfile {
    if ( -not ( Test-Path "$clonePath\.git" )) {
        Write-Host "Initializing Git Repository..."
        Set-Location $clonePath
        git init
        git remote add origin $repoURL
    }

    Set-Location $clonePath
    git pull origin main
    git add .
    git commit -m "Auto-sync PowerShell Profile on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    git push origin main
}

# Run Sync-GitProfile automatically when PowerShell starts
Sync-GitProfile

#
# Main Profile
#

# Test if machine is a server. Don't run these commands if it is
# Product type 1 = Workstation. 2 = Domain controller. 3 = non-DC server.
if (( Get-WmiObject -class win32_OperatingSystem ).ProductType -eq 1 ) {
    # Download configs and apply locally
	# oh-my-posh
    If ( gcm oh-my-posh ){
		Invoke-WebRequest "https://raw.githubusercontent.com/PostWarTacos/Powershell/refs/heads/main/PowerShell%20Profile/uew.json"`
			-OutFile "$env:USERPROFILE\Documents\Coding\PowerShell\PowerShellProfile\uew.json"
		oh-my-posh init pwsh --config "$env:USERPROFILE\Documents\Coding\PowerShell\PowerShellProfile\uew.json" | Invoke-Expression
	}
	
    # WinFetch
    if ( gcm WinFetch ){
		Invoke-WebRequest "https://raw.githubusercontent.com/PostWarTacos/Powershell/refs/heads/main/PowerShell%20Profile/WinFetch/CustomConfig.ps1"`
			-OutFile "$env:USERPROFILE\.config\winfetch\Config.ps1"
		winfetch -configpath "$env:USERPROFILE\.config\winfetch\Config.ps1"
		winfetch
	}
	
    # Terminal Icons
    Import-Module -Name Terminal-Icons

    # Import settings.json file for Windows Terminal
    if ( Test-Path %LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState ) {
        Invoke-WebRequest "https://raw.githubusercontent.com/PostWarTacos/Powershell/refs/heads/main/PowerShell%20Profile/Win%20Terminal%20Settings/settings.json"`
            -OutFile "%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    }
}

#
# Linux-like Commands
#

# grep
function grep($regex, $dir) {
    if ( $dir ) {
            ls $dir | select-string $regex
            return
    }
    $input | select-string $regex
}

# find-file
function find-file($name) {
    ls -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | foreach {
            $place_path = $_.directory
            echo "${place_path}\${_}"
    }
}

# Searching for commands with up/down arrow is really handy.  The
# option "moves to end" is useful if you want the cursor at the end
# of the line while cycling through history like it does w/o searching,
# without that option, the cursor will remain at the position it was
# when you used up arrow, which can be useful if you forget the exact
# string you started the search on.
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# This key handler shows the entire or filtered history using Out-GridView. The
# typed text is used as the substring pattern for filtering. A selected command
# is inserted to the command line without invoking. Multiple command selection
# is supported, e.g. selected by Ctrl + Click.
# As another example, the module 'F7History' does something similar but uses the
# console GUI instead of Out-GridView. Details about this module can be found at
# PowerShell Gallery: https://www.powershellgallery.com/packages/F7History.
Set-PSReadLineKeyHandler -Key F7 `
                         -BriefDescription History `
                         -LongDescription 'Show command history' `
                         -ScriptBlock {
    $pattern = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
    if ($pattern)
    {
        $pattern = [regex]::Escape($pattern)
    }

    $history = [System.Collections.ArrayList]@(
        $last = ''
        $lines = ''
        foreach ( $line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath ))
        {
            if ($line.EndsWith('`'))
            {
                $line = $line.Substring( 0, $line.Length - 1 )
                $lines = if ( $lines )
                {
                    "$lines`n$line"
                }
                else
                {
                    $line
                }
                continue
            }

            if ( $lines )
            {
                $line = "$lines`n$line"
                $lines = ''
            }

            if (( $line -cne $last ) -and ( !$pattern -or ( $line -match $pattern )))
            {
                $last = $line
                $line
            }
        }
    )
    $history.Reverse()

    $command = $history | Out-GridView -Title History -PassThru
    if ( $command )
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
    }
}

# `ForwardChar` accepts the entire suggestion text when the cursor is at the end of the line.
# This custom binding makes `RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.
Set-PSReadLineKeyHandler -Key RightArrow `
                         -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
                         -LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
                         -ScriptBlock {
    param( $key, $arg )

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState( [ref]$line, [ref]$cursor )

    if ( $cursor -lt $line.Length ) {
        [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar( $key, $arg )
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord( $key, $arg )
    }
}


#
# Transcript
#
If ( -not ( Test-Path "$user\Documents\Coding\PowerShell\Transcripts" )){
	mkdir "$user\Documents\Coding\PowerShell\Transcripts"
}

Start-Transcript -OutputDirectory "$user\Documents\Coding\PowerShell\Transcripts" -NoClobber -IncludeInvocationHeader
