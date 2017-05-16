# HstWB Installer Data Module
# ---------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-05-05
#
# A powershell module for HstWB Installer with data functions.


Add-Type -AssemblyName System.IO.Compression.FileSystem


# read zip entry text file
function ReadZipEntryTextFile($zipFile, $entryName)
{
    # open zip archive
    $zipArchive = [System.IO.Compression.ZipFile]::Open($zipFile,"Read")
    $zipArchiveEntry = $zipArchive.Entries | Where-Object { $_.FullName -match $entryName } | Select-Object -First 1

    # return null, if zip archive entry doesn't exist
    if (!$zipArchiveEntry)
    {
        $zipArchive.Dispose()
        return $null
    }

    # open zip archive entry stream
    $entryStream = $zipArchiveEntry.Open()
    $streamReader = New-Object System.IO.StreamReader($entryStream)

    # read text from stream
    $text = $streamReader.ReadToEnd()

    # close streams
    $streamReader.Close()
    $streamReader.Dispose()

    # close zip archive
    $zipArchive.Dispose()
    
    return $text
}


# zip file contains
function ZipFileContains($zipFile, $pattern)
{
    # open zip archive
    $zipArchive = [System.IO.Compression.ZipFile]::Open($zipFile,"Read")
    
    # get zip archive entries matching pattern
    $matchingZipArchiveEntries = @()
    $matchingZipArchiveEntries += $zipArchive.Entries | Where-Object { $_.FullName -match $pattern }

    # close zip archive
    $zipArchive.Dispose()

    return $matchingZipArchiveEntries.Count -gt 0
}


# extract files from zip file
function ExtractFilesFromZipFile($zipFile, $pattern, $outputDir)
{
    # open zip archive
    $zipArchive = [System.IO.Compression.ZipFile]::Open($zipFile,"Read")
    
    # get zip archive entries matching pattern
    $matchingZipArchiveEntries = @()
    $matchingZipArchiveEntries += $zipArchive.Entries | Where-Object { $_.FullName -match $pattern }

    # extract matching zip archive entries
    foreach($zipArchiveEntry in $matchingZipArchiveEntries)
    {
        # get output file
        $outputFile = Join-Path $outputDir -ChildPath $zipArchiveEntry.FullName

        # get output file parent dir
        $outputFileParentDir = Split-Path $outputFile -Parent

        # create entry directory, if it doesn't exist
        if (!(Test-Path $outputFileParentDir))
        {
            mkdir $outputFileParentDir | Out-Null
        }

        # open zip archive entry stream
        $zipArchiveEntryStream = $zipArchiveEntry.Open()

        # open file stream and write from entry stream
        $outputFileStream = New-Object System.IO.FileStream($outputFile, 'Create')
        $zipArchiveEntryStream.CopyTo($outputFileStream)

        # close streams
        $outputFileStream.Close()
        $outputFileStream.Dispose()
        $zipArchiveEntryStream.Close()
        $zipArchiveEntryStream.Dispose()
    }

    # close zip archive
    $zipArchive.Dispose()
}


# calculate md5 hash from file
function CalculateMd5FromFile($file)
{
	$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	return [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($file))).ToLower().Replace('-', '')
}


# calculate md5 hash from text
function CalculateMd5FromText($text)
{
    $encoding = [system.Text.Encoding]::UTF8
	$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	return [System.BitConverter]::ToString($md5.ComputeHash($encoding.GetBytes($text))).ToLower().Replace('-', '')
}


# get file hashes
function GetFileHashes($path)
{
    $files = Get-ChildItem -Path $path | Where-Object { ! $_.PSIsContainer }

    $fileHashes = @()

    foreach ($file in $files)
    {
        $md5Hash = CalculateMd5FromFile $file.FullName

        $fileHashes += @{ "File" = $file.FullName; "Md5Hash" = $md5Hash }
    }

    return $fileHashes
}


# find matching file hashes
function FindMatchingFileHashes($hashes, $path)
{
    # get file hashes from path
    $fileHashes = GetFileHashes $path

    # index file hashes
    $fileHashesIndex = @{}
    $fileHashes | % { $fileHashesIndex.Set_Item($_.Md5Hash, $_.File) }

    # find files with matching hashes
    foreach($hash in $hashes)
    {
        if ($fileHashesIndex.ContainsKey($hash.Md5Hash))
        {
            $hash | Add-Member -MemberType NoteProperty -Name 'File' -Value ($fileHashesIndex.Get_Item($hash.Md5Hash)) -Force
        }
    }
}


# read string from bytes
function ReadString($bytes, $offset, $length)
{
	$stringBytes = New-Object 'byte[]' $length 
	[Array]::Copy($bytes, $offset, $stringBytes, 0, $length)
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
	return $iso88591.GetString($stringBytes)
}


# read adf disk name
function ReadAdfDiskName($bytes)
{
    # read disk name from offset 0x6E1B0
    $diskNameOffset = 0x6E1B0
    $diskNameLength = $bytes[$diskNameOffset]

    ReadString $bytes ($diskNameOffset + 1) $diskNameLength
}


# find matching workbench adfs
function FindMatchingWorkbenchAdfs($hashes, $path)
{
    $adfFiles = Get-ChildItem -Path $path -filter *.adf

    $validWorkbenchAdfFiles = @()

    foreach ($adfFile in $adfFiles)
    {
        # read adf bytes
        $adfBytes = [System.IO.File]::ReadAllBytes($adfFile.FullName)

        if ($adfBytes.Count -eq 901120)
        {
            $diskName = ReadAdfDiskName $adfBytes
            $validWorkbenchAdfFiles += @{ "DiskName" = $diskName; "File" = $adfFile.FullName }
        }
    }


    # find files with matching disk names
    foreach($hash in ($hashes | Where { $_.DiskName -ne '' -and !$_.File }))
    {
        $workbenchAdfFile = $validWorkbenchAdfFiles | Where { $_.DiskName -eq $hash.DiskName } | Select-Object -First 1

        if (!$workbenchAdfFile)
        {
            continue
        }

        $hash | Add-Member -MemberType NoteProperty -Name 'File' -Value $workbenchAdfFile.File -Force
    }
}


# find workbench adf set hashes
function FindWorkbenchAdfSetHashes($settings, $workbenchAdfHashesFile)
{
    # read workbench adf hashes
    $workbenchAdfHashes = @()
    $workbenchAdfHashes += (Import-Csv -Delimiter ';' $workbenchAdfHashesFile)


    # find files with hashes matching workbench adf hashes
    FindMatchingFileHashes $workbenchAdfHashes $settings.Workbench.WorkbenchAdfPath


    # find files with disk names matching workbench adf hashes
    FindMatchingWorkbenchAdfs $workbenchAdfHashes $settings.Workbench.WorkbenchAdfPath


    # get workbench adf set hashes
    $workbenchAdfSetHashes = $workbenchAdfHashes | Where { $_.Set -eq $settings.Workbench.WorkbenchAdfSet }


    # fail, if workbench adf set hashes is empty 
    if ($workbenchAdfSetHashes.Count -eq 0)
    {
        Fail ("Workbench adf set '" + $settings.Workbench.WorkbenchAdfSet + "' doesn't exist!")
    }
    
    return $workbenchAdfSetHashes
}


# find kickstart rom set hashes
function FindKickstartRomSetHashes($settings, $kickstartRomHashesFile)
{
    # read kickstart rom hashes
    $kickstartRomHashes = @()
    $kickstartRomHashes += (Import-Csv -Delimiter ';' $kickstartRomHashesFile)


    # find files with hashes matching kickstart rom hashes
    FindMatchingFileHashes $kickstartRomHashes $settings.Kickstart.KickstartRomPath


    # get kickstart rom set hashes
    $kickstartRomSetHashes = $kickstartRomHashes | Where { $_.Set -eq $settings.Kickstart.KickstartRomSet }


    # fail, if kickstart rom set hashes is empty 
    if ($kickstartRomSetHashes.Count -eq 0)
    {
        Fail ("Kickstart rom set '" + $settings.Kickstart.KickstartRomSet + "' doesn't exist!")
    }


    return $kickstartRomSetHashes
}