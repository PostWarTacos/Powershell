Function Get-FolderPath {
    Add-Type -AssemblyName System.Windows.Forms
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    $FolderBrowser.Description = "Select a folder"
    
    if ($FolderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $FolderBrowser.SelectedPath
    }
    return $null  # Return null if no folder is selected
}

Get-FolderPath