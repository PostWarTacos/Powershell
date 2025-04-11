#---------------------------------Create Coding Directory---------------------------------#

If ( $(whoami) -match "wurtzmt" ){
    $user = "C:\users\wurtzmt"
} 
Else {
    $user = [System.Environment]::GetFolderPath("UserProfile")
}

If ( -not ( Test-Path "$user\Documents\Coding" )){
    mkdir "$user\Documents\Coding"
}

#---------------------------------Linux-like Commands---------------------------------#

# grep
function grep($regex, $dir) {
    if ( $dir ) {
            Get-ChildItem $dir | select-string $regex
            return
    }
    $input | select-string $regex
}

# find-file
function find-file($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
            $place_path = $_.directory
            Write-Output "${place_path}\${_}"
    }
}

#---------------------------------Import PSModules---------------------------------#

If ( Test-Path $clonePath\Modules ){
    $modules = Get-ChildItem $clonePath\Modules
    foreach ( $module in $modules ){
        Import-Module $module.fullname
    }
}

#---------------------------------PSReadLineOptions---------------------------------#

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

#---------------------------------Transcript---------------------------------#

If ( -not ( Test-Path "$user\Documents\Coding\PowerShell\Transcripts" )){
	mkdir "$user\Documents\Coding\PowerShell\Transcripts"
}

Start-Transcript -OutputDirectory "$user\Documents\Coding\PowerShell\Transcripts" -NoClobber -IncludeInvocationHeader | Out-Null
