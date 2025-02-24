clear

# Test if folder BookSwap exists. If not, create it
If ((Test-Path "~\Documents\BookSwap") -eq $false)
{
    New-Item -ItemType Directory -Path "~\Documents" -Name BookSwap
}

# Check if Names.txt or <date>_Swap.txt exists. If not, display error and exit
If ((Test-Path "~\Documents\BookSwap\*.txt") -eq $false)
{
    Write-Host "No TXT file exists in $HOME\Documents\BookSwap. Please create a TXT file with names." -ForegroundColor Cyan
    break 
}

# Get-Filename
Function Get-FileName($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

# Exort location variables
$exportcsv = (Get-Date -f "MM-dd-yy") + "_Swap.csv"
$exportCSVFull = "~\Documents\BookSwap\" + $exportcsv
$exporttxt = (Get-Date -f "MM-dd-yy") + "_Swap.txt"
$exportTXTFull = "~\Documents\BookSwap\" + $exporttxt

# Get list of names from static list
$pairedlist = $null
$OldSwap = $null
$StaticList = Get-Content ~\Documents\BookSwap\Names.txt

# Do you have an old Swap file
Write-host ""
$Caption = "`n`nDo you have an old Book Swap CSV file?`n";
$Message = "";
$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Yes";
$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No","No";
$Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No);
$Answer = $host.ui.PromptForChoice($Caption,$Message,$Choices,0)
Switch ($Answer)
	{
	0 # Yes
		{
		    $initialDirectory = "~\Documents"
            $CSVfile = Get-FileName -initialDirectory "$initialDirectory"
            $fileinfo = Get-Item $CSVfile
            # Confirm correct directory
            if(($fileinfo).DirectoryName -ne "$HOME\Documents\BookSwap"){
                Write-Host "Please use $HOME\Documents\BookSwap"
                Break
            }
            # Confirm correct CSV
            if($fileinfo.Name -like "*swap*.csv"){
                $OldSwap = Import-Csv $CSVfile
                $OldSwap = $OldSwap.name2
            }

		}
	1 # No
		{
		    Write-host "Generating swap file based on Names.txt"
		}
	}

# Scramble list
if($OldSwap -eq $null){ # Generate swap file based on names.txt
    $i = 0
    do{
        $readersPair = $StaticList[1..($StaticList.count-1)] + $StaticList[0]
        $i++
    }until($i -eq ($StaticList).Count - 1)
}
elseif($OldSwap -ne $null){ # Use old swap CSV
    $i = 0
    do{
        $readersPair = $OldSwap[1..($OldSwap.count-1)] + $OldSwap[0]
        $i++
    }until($i -eq ($StaticList).Count - 1)
}


# Match old list with new list
$r = 0
$date = Get-Date
foreach($reader in $StaticList){
    $name1 = $StaticList[$r]
    $name2 = $readersPair[$r]
    $paired = @(
        [pscustomobject]@{Name1="$name1";Name2="$name2"}
    )
    $pairedlist += $paired
    $r++
}

$pairedlist | Export-Csv $exportCSVFull

<## Export custom object as text file
$pairedlist |
	ft -AutoSize * |
	out-string |
	%{$_.Trim().Split("`n")} | 
	%{$_.Trim()} | Out-File $exportTXTFull
#>