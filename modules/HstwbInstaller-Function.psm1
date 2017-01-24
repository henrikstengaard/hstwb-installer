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

# calculate md5 hash
function CalculateMd5($path)
{
	$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	return [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($path))).ToLower().Replace('-', '')
}


# get file hashes
function GetFileHashes($path)
{
    $adfFiles = Get-ChildItem -Path $path

    $fileHashes = @()

    foreach ($adfFile in $adfFiles)
    {
        $md5Hash = (CalculateMd5 $adfFile.FullName)
        $fileHashes += @{ "File" = $adfFile.FullName; "Md5Hash" = $md5Hash }
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


# export
export-modulemember -function ReadZipEntryTextFile
export-modulemember -function CalculateMd5
export-modulemember -function GetFileHashes
export-modulemember -function FindMatchingFileHashes
export-modulemember -function ReadString
export-modulemember -function ReadAdfDiskName
export-modulemember -function FindMatchingWorkbenchAdfs