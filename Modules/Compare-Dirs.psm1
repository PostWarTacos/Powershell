Function Compare-Dirs() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )   

    function Copy-LatestFile{
        Param( $file1, $file2, [switch]$whatif )
        $file1Date = get-Item $file1 | foreach-Object{$_.LastWriteTimeUTC}
        $file2Date = get-Item $file2 | foreach-Object{$_.LastWriteTimeUTC}
        if( $file1Date -gt $file2Date ) {
            Write-Host "$file1 is Newer... Copying..."
            if( $whatif ){
                Copy-Item -path $file1 -dest $file2 -force -whatif
            }
            else{
                Copy-Item -path $file1 -dest $file2 -force
            }
        }
        else {
            Write-Host "$file2 is Newer... Copying..."
            if( $whatif ){
                Copy-Item -path $file2 -dest $file1 -force -whatif
            }
            else{
                Copy-Item -path $file2 -dest $file1 -force
            }
        }
        Write-Host
    }

    # Getting folders and Files
    $srcFolders = Get-ChildItem $source -Recurse -Force -Directory
    $destFolders = Get-ChildItem $destination -Recurse -Force -Directory

    $srcFiles = Get-ChildItem $source -Recurse -Force File
    $destFiles = Get-ChildItem $destination -Recurse -Force -File

    # Checking for Folders that are in Source, but not in Destination
    foreach( $folder in $srcFolders ) {
        $srcFolderPath = $source -replace "\\","\\" -replace "\:","\:"
        $destFolderPath = $folder.Fullname -replace $srcFolderPath,$destination
        if( -not ( test-path $destFolderPath )) {
            Write-Host "Folder $destFolderPath Missing. Creating it!"
            new-Item $destFolderPath -type Directory | out-Null
        }
    }

    # Checking for Folders that are in Destinatino, but not in Source
    foreach( $folder in $destFolders ) {
        $destFolderPath = $destination -replace "\\","\\" -replace "\:","\:"
        $srcFolderPath = $folder.Fullname -replace $destFolderPath,$source
        if( -not ( test-path $srcFolderPath )) {
            Write-Host "Folder $srcFolderPath Missing. Creating it!"
            new-Item $srcFolderPath -type Directory | out-Null
        }
    }

    # Checking for Files that are in the Source, but not in Destination
    foreach( $entry in $srcFiles ) {
        $srcFullName = $entry.fullname
        $srcName = $entry.Name
        $srcFilePath = $source -replace "\\","\\" -replace "\:","\:"
        $destFullName = $srcFullName -replace $srcFilePath,$destination
        if( test-Path $destFullName ) {
            $srcMD5 = Get-FileHash $srcFullName -Algorithm MD5
            $destMD5 = Get-FileHash $destFullName -Algorithm MD5
            If( Compare-Object $srcMD5 $destMD5 ) {
                Write-Host "The Files MD5's are Different... Checking Write
                Dates"
                Write-Host $srcMD5
                Write-Host $destMD5
                Copy-LatestFile $srcFullName $destFullName
            }
        }
        else {
            Write-Host "$destFullName Missing... Copying from $srcFullName"
            copy-Item -path $srcFullName -dest $destFullName -force
        }
    }

    # Checking for Files that are in the Destinatino, but not in Source
    foreach($entry in $destFiles)
    {
        $destFullName = $entry.fullname
        $destName = $entry.Name
        $destFilePath = $destination -replace "\\","\\" -replace "\:","\:"
        $srcFullName = $destFullName -replace $destFilePath,$source
        if( -not ( test-Path $srcFullName ))
        {
            Write-Host "$srcFullName Missing... Copying from $destFullName"
            copy-Item -path $desFullName -dest $srcFullName -force
        }
    }
}