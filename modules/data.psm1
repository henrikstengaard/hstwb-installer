# HstWB Installer Data Module
# ---------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2019-03-13
#
# A powershell module for HstWB Installer with data functions.


Add-Type -AssemblyName System.IO.Compression.FileSystem


# $nodes = @()
# $nodes += @{ 'Name'= 'package1'; 'Dependencies' = @() }
# $nodes += @{ 'Name'= 'package2'; 'Dependencies' = @() }
# $nodes += @{ 'Name'= 'package3'; 'Dependencies' = @('package1') }
# $nodes += @{ 'Name'= 'package4'; 'Dependencies' = @('package1') }
# $nodes += @{ 'Name'= 'package5'; 'Dependencies' = @('package3') }


# # package1
# # - package3
# #   - package5
# # - package4
# # package2

# TopologicalSort $nodes


# topological sort
function TopologicalSort {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $nodes
    )

    $nodesIndex = @{}
    $nodesDependencyIndex = @{}
    $currentNodes = New-Object -TypeName System.Collections.Generic.Stack[object]

    for($i = $nodes.Count - 1; $i -ge 0; $i--)
    {
        $node = $nodes[$i]

        if (!$nodesIndex.ContainsKey($node.Name))
        {
            $nodesIndex.Set_Item($node.Name, $node)
        }
        else
        {
            throw ("'{0}' is duplicate" -f $node.Name)    
        }

        if ($node.Dependencies.Count -eq 0)
        {
            [void]$currentNodes.Push($node.Name)
            continue
        }

        foreach($nodeDependency in $node.Dependencies)
        {
            if ($nodesDependencyIndex.ContainsKey($nodeDependency))
            {
                $nodeDependencies = $nodesDependencyIndex.Get_Item($nodeDependency)
            }
            else
            {
                $nodeDependencies = @()
            }

            if ($nodeDependencies.Contains($node.Name))
            {
                continue
            }

            $nodeDependencies += $node.Name
            $nodesDependencyIndex.Set_Item($nodeDependency, $nodeDependencies)
        }
    }

    # throw error, if node dependency doesn't exist or circular dependency detected between nodes
    foreach($node in $nodesIndex.keys)
    {
        foreach($nodeDependency in $nodesIndex[$node].Dependencies)
        {
            if (!$nodesIndex.ContainsKey($nodeDependency))
            {
                throw ("'{0}' dependency '{1}' doesn't exist" -f $node, $nodeDependency)
            }
            else
            {
                if ($nodesIndex[$nodeDependency].Contains($node))
                {
                    throw ("Circular dependency between '{0}' and '{1}'" -f $node, $nodeDependency)
                }
            }
        }
    }

    $topologicallySortedNodes = New-Object System.Collections.ArrayList

    while($currentNodes.Count -gt 0)
    {
        $node = $currentNodes.Pop()

        [void]$topologicallySortedNodes.Add($node)

        if ($nodesDependencyIndex.ContainsKey($node))
        {
            $nodesDependencyIndex[$node] | ForEach-Object { [void]$currentNodes.Push($_) }
        }
    }

    return $topologicallySortedNodes
}


# topological sort v2
function TopologicalSortV2 {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$nodes
    )

    $nodeDependenciesIndex = @{}
    $currentNodes = New-Object -TypeName System.Collections.Generic.Stack[object]

    foreach($node in ($nodes.keys | Sort-Object @{expression={$nodes[$_].SortOrder};Ascending=$false}))
    {
        if ($nodes[$node].Dependencies.Count -eq 0)
        {
            [void]$currentNodes.Push($_)
            continue
        }

        foreach($nodeDependency in $nodes[$node].Dependencies)
        {
            if (!$nodes.ContainsKey($nodeDependency))
            {
                throw ("'{0}' dependency '{1}' doesn't exist" -f $node, $nodeDependency)
            }
            else
            {
                if ($nodes[$nodeDependency].Dependencies.Contains($node))
                {
                    throw ("Circular dependency between '{0}' and '{1}'" -f $node, $nodeDependency)
                }
            }

            if ($nodeDependenciesIndex.ContainsKey($nodeDependency))
            {
                $nodeDependencies = $nodeDependenciesIndex.Get_Item($nodeDependency)
            }
            else
            {
                $nodeDependencies = @()
            }

            if ($nodeDependencies.Contains($node))
            {
                continue
            }

            $nodeDependencies += $node
            $nodeDependenciesIndex.Set_Item($nodeDependency, $nodeDependencies)
        }
    }

    foreach($node in $currentNodes)
    {
        Write-Host $node
    }

    $topologicallySortedNodes = New-Object System.Collections.ArrayList

    while($currentNodes.Count -gt 0)
    {
        $node = $currentNodes.Pop()

        [void]$topologicallySortedNodes.Add($node)

        if ($nodeDependenciesIndex.ContainsKey($node))
        {
            $nodeDependenciesIndex[$node] | ForEach-Object { [void]$currentNodes.Push($_) }
        }
    }

    return $topologicallySortedNodes
}


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
    try
    {
        $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
        return [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($file))).ToLower().Replace('-', '')
    }
    catch
    {
        throw ('Failed to read MD5 from file ''{0}'': {1}' -f $file, $_.ErrorDetails.Message)
    }
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
    $fileHashes = @()

    if (!$path -or !(Test-Path -Path $path))
    {
        return $fileHashes
    }

    $files = Get-ChildItem -Path $path | Where-Object { ! $_.PSIsContainer }

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
        $file = $null
        if ($fileHashesIndex.ContainsKey($hash.Md5Hash))
        {
            $file = $fileHashesIndex.Get_Item($hash.Md5Hash)
        }

        $hash | Add-Member -MemberType NoteProperty -Name 'File' -Value $file -Force
        $hash | Add-Member -MemberType NoteProperty -Name 'MatchType' -Value 'MD5' -Force
        $hash | Add-Member -MemberType NoteProperty -Name 'MatchRank' -Value '1' -Force
    }
}


function ReadBytes($bytes, $offset, $length)
{
	$newBytes = New-Object 'byte[]' $length
	[Array]::Copy($bytes, $offset, $newBytes, 0, $length)
	return $newBytes
}

# read string from bytes
function ReadString($bytes, $offset, $length)
{
    $stringBytes = ReadBytes $bytes $offset $length
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
	return $iso88591.GetString($stringBytes)
}


# read adf volume name
function ReadAdfVolumeName($bytes)
{
    # read volume name from offset 0x6E1B0
    $volumeNameOffset = 0x6E1B0
    $volumeNameLength = $bytes[$volumeNameOffset]

    ReadString $bytes ($volumeNameOffset + 1) $volumeNameLength
}


# find matching amiga os adfs
function FindMatchingAmigaOsEntriesByAdfVolumeName($amigaOsEntries, $dir)
{
    $adfFiles = Get-ChildItem -Path $dir -filter *.adf

    $validAdfFiles = @()

    foreach ($adfFile in $adfFiles)
    {
        # read adf bytes
        $adfBytes = [System.IO.File]::ReadAllBytes($adfFile.FullName)

        if ($adfBytes.Count -ne 901120)
        {
            continue
        }

        $magicBytes = ReadBytes $adfBytes 0 4

        # DOS1
        if ($magicBytes[0] -ne 68 -and $magicBytes[1] -ne 79 -and $magicBytes[2] -ne 83 -and $magicBytes[3] -ne 1)
        {
            continue
        }
    
        $volumeName = ReadAdfVolumeName $adfBytes
        $validAdfFiles += @{ "VolumeName" = $volumeName; "File" = $adfFile.FullName }
    }

    # find matching amiga os entries by volume name, which doesn't already have a file defined
    foreach($amigaOsEntry in ($amigaOsEntries | Where-Object { $_.VolumeName -ne '' -and !$_.File }))
    {
        $matchingAmigaOsAdfFile = $validAdfFiles | Where-Object { $_.VolumeName -eq $amigaOsEntry.VolumeName } | Select-Object -First 1

        $amigaOsAdfFile = $null 

        if ($matchingAmigaOsAdfFile)
        {
            $amigaOsAdfFile = $matchingAmigaOsAdfFile.File
        }

        $amigaOsEntry | Add-Member -MemberType NoteProperty -Name 'File' -Value $amigaOsAdfFile -Force
        $amigaOsEntry | Add-Member -MemberType NoteProperty -Name 'MatchType' -Value 'VolumeName' -Force
        $amigaOsEntry | Add-Member -MemberType NoteProperty -Name 'MatchRank' -Value '2' -Force
    }
}

function FindMatchingAmigaOsEntriesByFileName($amigaOsEntries, $dir)
{
    $files = Get-ChildItem -Path $dir -Recurse

    # find matching amiga os entries by filename, which doesn't already have a file defined
    foreach($amigaOsEntry in ($amigaOsEntries | Where-Object { $_.Filename -ne '' -and !$_.File }))
    {
        $matchingFile = $files | Where-Object { $_.Name -eq $amigaOsEntry.Filename } | Select-Object -First 1

        if (!$matchingFile)
        {
            continue
        }

        $amigaOsEntry | Add-Member -MemberType NoteProperty -Name 'File' -Value $matchingFile.FullName -Force
        $amigaOsEntry | Add-Member -MemberType NoteProperty -Name 'MatchType' -Value 'FileName' -Force
        $amigaOsEntry | Add-Member -MemberType NoteProperty -Name 'MatchRank' -Value '3' -Force
    }
}


# find amiga os files
function FindAmigaOsFiles($hstwb)
{
    # reset amiga os dir, if it doesn't exist
    if (!$hstwb.Settings.AmigaOs.AmigaOsDir -or !(Test-Path -Path $hstwb.Settings.AmigaOs.AmigaOsDir))
    {
        $hstwb.Settings.AmigaOs.AmigaOsDir = ''
        return
    }

    # find files with hashes matching workbench adf hashes
    FindMatchingFileHashes $hstwb.AmigaOsSets $hstwb.Settings.AmigaOs.AmigaOsDir
    
    # find matching amiga os entries by adf volume name
    FindMatchingAmigaOsEntriesByAdfVolumeName $hstwb.AmigaOsSets $hstwb.Settings.AmigaOs.AmigaOsDir

    # find matching amiga os entries by filename
    FindMatchingAmigaOsEntriesByFileName $hstwb.AmigaOsSets $hstwb.Settings.AmigaOs.AmigaOsDir
}


# find kickstart roms
function FindKickstartRoms($hstwb)
{
    # reset kickstart rom dir, if it doesn't exist
    if (!$hstwb.Settings.Kickstart.KickstartRomDir -or !(Test-Path -Path $hstwb.Settings.Kickstart.KickstartRomDir))
    {
        $hstwb.Settings.Kickstart.KickstartRomDir = ''
    }

    # find files with hashes matching kickstart rom hashes
    FindMatchingFileHashes $hstwb.KickstartRomHashes $hstwb.Settings.Kickstart.KickstartRomDir
}


# find best matching kickstart rom set
function FindBestMatchingKickstartRomSet($hstwb)
{
    # find kickstart roms
    FindKickstartRoms $hstwb

    # get kickstart rom sets
    $kickstartRomSets = @()
    $kickstartRomSets += $hstwb.KickstartRomHashes | Sort-Object @{expression={$_.Priority};Ascending=$false} | ForEach-Object { $_.Set } | Get-Unique
        
    # count matching kickstart rom hashes for each set
    $kickstartRomSetCount = @{}
    foreach($kickstartRomSet in $kickstartRomSets)
    {
        $kickstartRomSetFiles = @()
        $kickstartRomSetFiles += $hstwb.KickstartRomHashes | Where-Object { $_.Set -eq $kickstartRomSet -and $_.File }
        $kickstartRomSetCount.Set_Item($kickstartRomSet, $kickstartRomSetFiles.Count)
    }

    # get new kickstart rom set, which has highest number of matching kickstart rom hashes
    return $kickstartRomSets | Sort-Object @{expression={$kickstartRomSetCount.Get_Item($_)};Ascending=$false} | Select-Object -First 1    
}


# find best matching amiga os adf set
function FindBestMatchingAmigaOsSet($hstwb)
{
    # find amiga os files
    FindAmigaOsFiles $hstwb

    # get workbench rom sets
    $workbenchAdfSets = @()
    $workbenchAdfSets += $hstwb.AmigaOsSets | Sort-Object @{expression={$_.Priority};Ascending=$false} | ForEach-Object { $_.Set } | Get-Unique

    # count matching workbench adf hashes for each set
    $workbenchAdfSetCount = @{}
    foreach($workbenchAdfSet in $workbenchAdfSets)
    {
        $workbenchAdfSetFiles = @()
        $workbenchAdfSetFiles += $hstwb.AmigaOsSets | Where-Object { $_.Set -eq $workbenchAdfSet -and $_.File }
        $workbenchAdfSetCount.Set_Item($workbenchAdfSet, $workbenchAdfSetFiles.Count)
    }

    # get new workbench adf set, which has highest number of matching workbench adf hashes
    return $workbenchAdfSets | Where-Object { $workbenchAdfSetCount.Get_Item($_) -gt 0 } | Sort-Object @{expression={$workbenchAdfSetCount.Get_Item($_)};Ascending=$false} | Select-Object -First 1
}

# validate amiga os set
function ValidateAmigaOsSet($hstwb, $amigaOsSetName)
{
    $amigaOsSetEntriesIndex = @{}
    $hstwb.AmigaOsSets | `
        Where-Object { $_.Set -eq $amigaOsSetName } | `
        ForEach-Object { 
            if (!$amigaOsSetEntriesIndex.ContainsKey($_.Name.ToLower()) -or !$amigaOsSetEntriesIndex[$_.Name.ToLower()].File) { 
                $amigaOsSetEntriesIndex[$_.Name.ToLower()] = $_
            }
        }

    $present = ($amigaOsSetEntriesIndex.Values | Where-Object { $_.Required -eq 'True' -and $_.File }).Count
    $required = ($amigaOsSetEntriesIndex.Values | Where-Object { $_.Required -eq 'True' }).Count
    $total = $amigaOsSetEntriesIndex.Values.Count

    return @{
        'Present' = $present;
        'Required' = $required;
        'Total' = $total
    }
}

function FormatAmigaOsSetInfo($amigaOsSetName, $required, $present, $total)
{
    $color = $null
    if ($present -gt 0)
    {
        $color = if ($present -ge $required) { 'Green' } else { 'Yellow' }
    }

    return @{
        'Text' = ("'{0}' ({1}/{2})" -f $amigaOsSetName, $present, $total);
        'Color' = $color
    }
}

function UiAmigaOsSetInfo($hstwb, $amigaOsSetName)
{
    $result = ValidateAmigaOsSet $hstwb $amigaOsSetName
    $hstwb.UI.AmigaOs.AmigaOsSetInfo = FormatAmigaOsSetInfo $amigaOsSetName $result.Required $result.Present $result.Total
}

# update amiga os entries
function UpdateAmigaOsEntries($hstwb)
{
    # fail
    if (!(Test-Path -Path $hstwb.Paths.AmigaOsSetsFile))
    {
        throw ("Amiga OS entries file '{0}' doesn't exist" -f $hstwb.Paths.AmigaOsSetsFile)
    }

    # set empty amiga os entries
    $hstwb.AmigaOsSets = @()

    # set amiga os entries empty, if installer mode is set to install or build self install
    if ($hstwb.Settings.Installer.Mode -notmatch "^(Install|BuildSelfInstall)$")
    {
        return
    }

    # read amiga os entries
    $amigaOsEntries = @()
    $amigaOsEntries += Import-Csv -Delimiter ';' $hstwb.Paths.AmigaOsSetsFile | Where-Object { $_.Name -and $_.Name -ne '' }

    # add priority to sets based on their order
    $set = ''
    $priority = 0
    foreach ($amigaOsEntry in $amigaOsEntries)
    {
        if ($set -ne $amigaOsEntry.Set)
        {
            $priority++
            $set = $amigaOsEntry.Set
        }

        $amigaOsEntry | Add-Member -MemberType NoteProperty -Name 'Priority' -Value $priority
    }

    $hstwb.AmigaOsSets = $amigaOsEntries
}

# sort packages to install
function SortPackageNames($hstwb)
{
    $packageIndex = 0
    $packageNodes = @()
    foreach ($package in ($hstwb.Packages.Values | Sort-Object @{expression={$_.Name};Ascending=$true}))
    {
        # get priority, if it exists. otherwise use default priority 9999
        $priority = if ($package.Priority) { [Int32]$package.Priority } else { 9999 }

        $packageIndex++
        $packageNodes += @{ 'Name'= $package.Name; 'Index' = $packageIndex; 'Dependencies' = $package.Dependencies.Name; 'Priority' = $priority }
    }

    $packageNamesSorted = @()

    # topologically sort packages, if any packages are present
    if ($packageNodes.Count -gt 0)
    {
        # sort packages by priority and name
        $packagesSorted = @()
        $packagesSorted += $packageNodes | Sort-Object @{expression={$_.Priority};Ascending=$true}, @{expression={$_.Index};Ascending=$true}

        # topologically sort packages and add package names sorted
        TopologicalSort $packagesSorted | ForEach-Object { $packageNamesSorted += $_ }
    }

    return $packageNamesSorted
}


# get all package dependencies
function GetDependencyPackageNames($hstwb, $package)
{
    $dependencyPackageNames = @()

    if (!$package.Dependencies)
    {
        return $dependencyPackageNames
    }

    foreach($dependencyPackageName in $package.Dependencies.Name)
    {
        $dependencyPackage = $hstwb.Packages[$dependencyPackageName.ToLower()]

        if (!$dependencyPackage)
        {
            continue
        }

        $dependencyPackageNames += GetDependencyPackageNames $hstwb $dependencyPackage
        $dependencyPackageNames += $dependencyPackage.Name
    }

    return $dependencyPackageNames
}

function BuildInstallLog($hstwb)
{
    $osVersion = Get-CimInstance Win32_OperatingSystem | Select-Object Caption | ForEach-Object { $_.Caption }
    $osArchitecture = Get-CimInstance Win32_OperatingSystem | Select-Object OSArchitecture | ForEach-Object { $_.OSArchitecture }
    $buildNumber = Get-CimInstance Win32_OperatingSystem | Select-Object BuildNumber | ForEach-Object { $_.BuildNumber }
    $powershellVersion = Get-Host | Select-Object Version | ForEach-Object { $_.Version }

    $installLogLines = New-Object System.Collections.Generic.List[System.Object]
    $installLogLines.Add('HstWB Installer')
    $installLogLines.Add('---------------')
    $installLogLines.Add('Author: Henrik Noerfjand Stengaard')
    $installLogLines.Add('Date: {0}' -f (Get-Date -format "yyyy-MM-dd HH:mm:ss"))
    $installLogLines.Add('')
    $installLogLines.Add('System')
    $installLogLines.Add(("- OS: '{0} {1} ({2})'" -f $osVersion, $osArchitecture, $buildNumber))
    $installLogLines.Add("- Powershell: '{0}'" -f $powershellVersion)
    $installLogLines.Add("- HstWB Installer: 'v{0}'" -f $hstwb.Version)
    $installLogLines.Add('')
    $installLogLines.Add('Settings')
    $installLogLines.Add("- Settings File: '{0}'" -f $hstwb.Paths.SettingsFile)
    $installLogLines.Add("- Assigns File: '{0}'" -f $hstwb.Paths.AssignsFile)
    $installLogLines.Add('Image')
    $installLogLines.Add("- Image Dir: '{0}'" -f $hstwb.Settings.Image.ImageDir)
    $installLogLines.Add('Amiga OS')
    $installLogLines.Add("- Install Amiga OS: '{0}'" -f $hstwb.Settings.AmigaOs.InstallAmigaOs)
    $installLogLines.Add("- Amiga OS dir: '{0}'" -f $hstwb.Settings.AmigaOs.AmigaOsDir)
    
    $amigaOsSet = @() 
    $amigaOsSetFiles = @()
    if ($hstwb.Settings.AmigaOs.AmigaOsSet -notmatch '^$')
    {
        $amigaOsSet += $hstwb.AmigaOsSets | Where-Object { $_.Set -eq $hstwb.Settings.AmigaOs.AmigaOsSet }
        $amigaOsSetFiles += $amigaOsSet | Where-Object { $_.File }
    }

    $installLogLines.Add(("- Amiga OS set: '{0}' ({1}/{2})" -f $hstwb.Settings.AmigaOs.AmigaOsSet, $amigaOsSetFiles.Count, $workbenchAdfSetHashes.Count))

    for ($i = 0; $i -lt $amigaOsSetFiles.Count; $i++)
    {
        $installLogLines.Add(("- Amiga OS set file {0}/{1}: '{2}' = '{3}'" -f ($i + 1), $amigaOsSetFiles.Count, $amigaOsSetFiles[$i].Filename, $amigaOsSetFiles[$i].File))     
    }

    $installLogLines.Add('Kickstart')
    $installLogLines.Add("- Install Kickstart: '{0}'" -f $hstwb.Settings.Kickstart.InstallKickstart)
    $installLogLines.Add("- Kickstart Rom Dir: '{0}'" -f $hstwb.Settings.Kickstart.KickstartRomDir)

    $kickstartRomSetHashes = @() 
    $kickstartRomSetFiles = @()
    if ($hstwb.Settings.Kickstart.KickstartRomSet -notmatch '^$')
    {
        $kickstartRomSetHashes += $hstwb.KickstartRomHashes | Where-Object { $_.Set -eq $hstwb.Settings.Kickstart.KickstartRomSet }
        $kickstartRomSetFiles += $kickstartRomSetHashes | Where-Object { $_.File }
    }

    $installLogLines.Add(("- Kickstart Rom Set: '{0}' ({1}/{2})" -f $hstwb.Settings.Kickstart.KickstartRomSet, $kickstartRomSetFiles.Count, $kickstartRomSetHashes.Count))

    for ($i = 0; $i -lt $kickstartRomSetFiles.Count; $i++)
    {
        $installLogLines.Add(("- Kickstart Rom File {0}/{1}: '{2}' = '{3}'" -f ($i + 1), $kickstartRomSetFiles.Count, $kickstartRomSetFiles[$i].Filename, $kickstartRomSetFiles[$i].File))     
    }
    
    $installLogLines.Add('Packages')

    # get install packages
    $installPackageIndex = @{}
    foreach($installPackageKey in ($hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' }))
    {
        $installPackageIndex.Set_Item($hstwb.Settings.Packages[$installPackageKey].ToLower(), $true)
    }

    $packageNames = @()
    $packageNames += SortPackageNames $hstwb | ForEach-Object { $_.ToLower() }
    
    $installPackageNames = @()
    $installPackageNames += $packageNames | Where-Object { $installPackageIndex.ContainsKey($_) } 

    for ($i = 0; $i -lt $installPackageNames.Count; $i++)
    {
        $installLogLines.Add(("- Install Package {0}/{1}: '{2}'" -f ($i + 1), $installPackageNames.Count, $installPackageNames[$i]))     
    }

    $installLogLines.Add('User Packages')

    if ($hstwb.Settings.UserPackages.UserPackagesDir -and (Test-Path -Path $hstwb.Settings.UserPackages.UserPackagesDir))
    {
        $installLogLines.Add("- User Packages Dir: '{0}'" -f $hstwb.Settings.UserPackages.UserPackagesDir)
    }
    else
    {
        $installLogLines.Add("- User Packages Dir: ''")
    }

    # get install user packages
    $installUserPackageNames = @()
    foreach($installUserPackageKey in ($hstwb.Settings.UserPackages.Keys | Where-Object { $_ -match 'InstallUserPackage\d+' }))
    {
        $userPackageName = $hstwb.Settings.UserPackages.Get_Item($installUserPackageKey.ToLower())
        $userPackage = $hstwb.UserPackages.Get_Item($userPackageName)
        $installUserPackageNames += $userPackage.Name
    }
    
    for ($i = 0; $i -lt $installUserPackageNames.Count; $i++)
    {
        $installLogLines.Add(("- Install User Package {0}/{1}: '{2}'" -f ($i + 1), $installUserPackageNames.Count, $installUserPackageNames[$i]))     
    }

    $installLogLines.Add("Emulator")

    $emulatorFile = ''

    if ($hstwb.Settings.Emulator.EmulatorFile -and (Test-Path -Path $hstwb.Settings.Emulator.EmulatorFile))
    {
        $emulatorName = DetectEmulatorName $hstwb.Settings.Emulator.EmulatorFile

        if ($emulatorName)
        {
            $emulatorFile = "{0} ({1})" -f $emulatorName, $hstwb.Settings.Emulator.EmulatorFile
        }
        else
        {
            $emulatorFile = $hstwb.Settings.Emulator.EmulatorFile
        }
    }
    
    $installLogLines.Add("- Emulator File: '{0}'" -f $emulatorFile)
    $installLogLines.Add("Installer")

    $installerMode = ''
    switch ($hstwb.Settings.Installer.Mode)
    {
        "Test" { $installerMode = "Test" }
        "Install" { $installerMode = "Install" }
        "BuildSelfInstall" { $installerMode = "Build Self Install" }
        "BuildPackageInstallation" { $installerMode = "Build Package Installation" }
        "BuildUserPackageInstallation" { $installerMode = "Build User Package Installation" }
    }

    $installLogLines.Add("- Mode: '{0}'" -f $installerMode)

    return $installLogLines.ToArray()
}