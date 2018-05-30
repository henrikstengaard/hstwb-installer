# HstWB Image Setup
# -----------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-05-30
#
# A powershell script to setup HstWB images with following installation:
# - Detect and install Workbench 3.1 adf and Kickstart rom files from Cloanto Amiga Forever using MD5 hashes.
# - Validate files in self install directories using MD5 hashes to indicate, if all files are present for self install.
# - Patch and install UAE and FS-UAE configuration files.
# - For FS-UAE configuration files, .adf files from Workbench directory are added as swappable floppies.


Param(
	[Parameter(Mandatory=$false)]
    [string]$installDir,
	[Parameter(Mandatory=$false)]
    [string]$amigaForeverDataDir
)


# get md5 files from dir
function GetMd5FilesFromDir($dir)
{
    $md5Files = New-Object System.Collections.Generic.List[System.Object]

    foreach($file in (Get-ChildItem $dir | Where-Object { ! $_.PSIsContainer }))
    {
        $md5Files.Add(@{
            'Md5' = (Get-FileHash $file.FullName -Algorithm MD5).Hash.ToLower();
            'File' = $file.FullName
        })
    }

    return $md5Files
}

# patch uae config file
function PatchUaeConfigFile($uaeConfigFile, $a1200KickstartRomFile, $amigaOs39IsoFile)
{
    # get uae config dir
    $uaeConfigDir = Split-Path $uaeConfigFile -Parent

    # read uae config file
    $uaeConfigLines = @()
    $uaeConfigLines += Get-Content $uaeConfigFile

    # patch uae config lines
    for ($i = 0; $i -lt $uaeConfigLines.Count; $i++)
    {
        $line = $uaeConfigLines[$i]

        # patch cd image 0
        if ($line -match '^cdimage0=')
        {
            if ($amigaOs39IsoFile)
            {
                $line = "cdimage0={0}" -f $amigaOs39IsoFile
            }
            else
            {
                $line = 'cdimage0='
            }
        }
        
        # patch kickstart rom file
        if ($line -match '^kickstart_rom_file=')
        {
            if ($a1200KickstartRomFile)
            {
                $line = "kickstart_rom_file={0}" -f $a1200KickstartRomFile
            }
            else
            {
                $line = 'kickstart_rom_file='
            }
        }

        # patch hardfile2 to current directory
        if ($line -match '^hardfile2=')
        {
            $hardfileFile = $line | Select-String -Pattern '^hardfile2=[^,]*,[^:]*:([^,]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

            if ($hardfileFile)
            {
                $hardfileFile = Join-Path $uaeConfigDir -ChildPath (Split-Path $hardfileFile -Leaf)
                $line = $line -replace '^(hardfile2=[^,]*,[^,:]*:)[^,]*', "`$1$hardfileFile"
            }
        }

        # patch uaehf to current directory
        if ($line -match '^uaehf\d+=')
        {
            $uaehfFile = $line | Select-String -Pattern '^uaehf\d+=[^,]*,[^,]*,[^,:]*:"?([^,"]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
            
            if ($uaehfFile)
            {
                $uaehfFile = (Join-Path $uaeConfigDir -ChildPath (Split-Path ($uaehfFile.Replace('\\', '\')) -Leaf)).Replace('\', '\\')
                $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:"?)[^,"]*', "`$1$uaehfFile"
            }
        }
        
        # patch filesystem2 to current directory
        if ($line -match '^filesystem2=')
        {
            $filesystemDir = $line | Select-String -Pattern '^filesystem2=[^,]*,[^,:]*:[^:]*:([^,]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

            if ($filesystemDir)
            {
                $filesystemDir = Join-Path $uaeConfigDir -ChildPath (Split-Path $filesystemDir -Leaf)
                $line = $line -replace '^(filesystem2=[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$filesystemDir"
            }
        }

        # update line, if it's changed
        if ($line -ne $uaeConfigLines[$i])
        {
            $uaeConfigLines[$i] = $line
        }
    }

    # write uae config file without byte order mark
    $utf8Encoding = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($uaeConfigFile, $uaeConfigLines, $utf8Encoding)
}

# patch fs-uae config file
function PatchFsuaeConfigFile($fsuaeConfigFile, $a1200KickstartRomFile, $amigaOs39IsoFile)
{
    # get fs-uae config dir
    $fsuaeConfigDir = Split-Path $fsuaeConfigFile -Parent

    # read fs-uae config file and skip lines, that contains floppy_image
    $fsuaeConfigLines = @()
    $fsuaeConfigLines += Get-Content $fsuaeConfigFile | Where-Object { $_ -notmatch '^floppy_image_\d+' }

    # add hard drive labels
    $harddriveLabels = @{}
    $fsuaeConfigLines | ForEach-Object { $_ | Select-String -Pattern '^(hard_drive_\d+)_label\s*=\s*(.*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $harddriveLabels.Set_Item($_.Groups[1].Value.Trim(), $_.Groups[2].Value.Trim()) } }

    # patch fs-uae config lines
    for ($i = 0; $i -lt $fsuaeConfigLines.Count; $i++)
    {
        $line = $fsuaeConfigLines[$i]

        # patch cdrom drive 0
        if ($line -match '^cdrom_drive_0\s*=')
        {
            if ($amigaOs39IsoFile)
            {
                $line = "cdrom_drive_0 = {0}" -f $amigaOs39IsoFile.Replace('\', '/')
            }
            else
            {
                $line = 'cdrom_drive_0 ='
            }
        }
        
        # patch logs dir
        if ($line -match '^logs_dir\s*=')
        {
            $line = "logs_dir = {0}" -f $fsuaeConfigDir.Replace('\', '/')
        }

        # patch kickstart file
        if ($line -match '^kickstart_file\s*=')
        {
            if ($a1200KickstartRomFile)
            {
                $line = "kickstart_file = {0}" -f $a1200KickstartRomFile.Replace('\', '/')
            }
            else
            {
                $line = 'kickstart_file = '
            }
        }
        
        # patch hard drives
        if ($line -match '^hard_drive_\d+\s*=')
        {
            # get hard drive index
            $harddriveIndex = $line | Select-String -Pattern '^(hard_drive_\d+)\s*=' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

            # get hard drive path
            $harddrivePath = $line | Select-String -Pattern '^hard_drive_\d+\s*=\s*(.*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
                                
            # patch hard drive, if hard drive index exists 
            if ($harddriveIndex -and $harddrivePath -and $harddriveLabels.ContainsKey($harddriveIndex))
            {
                $harddrivePath = Join-Path $fsuaeConfigDir -ChildPath (Split-Path $harddrivePath -Leaf)
                $line = $line -replace '^(hard_drive_\d+\s*=\s*).*', ("`$1{0}" -f $harddrivePath.Replace('\', '/'))
            }
        }

        # update line, if it's changed
        if ($line -ne $fsuaeConfigLines[$i])
        {
            $fsuaeConfigLines[$i] = $line
        }
    }

    # get adf files from workbench dir
    $adfFiles = @()
    if (Test-Path -Path $workbenchDir)
    {
        $adfFiles += Get-ChildItem -Path $workbenchDir -Filter *.adf | Where-Object { ! $_.PSIsContainer }
    }

    # add adf files to fs-uae config lines as swappable floppies
    for ($i = 0; $i -lt $adfFiles.Count; $i++)
    {
        $fsuaeConfigLines += "floppy_image_{0} = {1}" -f $i, $adfFiles[$i].FullName.Replace('\', '/')
    }

    # write fs-uae config file without byte order mark
    $utf8Encoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines($fsuaeConfigFile, $fsuaeConfigLines, $utf8Encoding)
}


# workbench 3.1 adf md5 entries
$workbench31AdfMd5Entries = @(
    @{ 'Md5' = 'c1c673eba985e9ab0888c5762cfa3d8f'; 'Filename' = 'workbench31extras.adf'; 'Name' = 'Workbench 3.1, Extras Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = '6fae8b94bde75497021a044bdbf51abc'; 'Filename' = 'workbench31fonts.adf'; 'Name' = 'Workbench 3.1, Fonts Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = 'd6aa4537586bf3f2687f30f8d3099c99'; 'Filename' = 'workbench31install.adf'; 'Name' = 'Workbench 3.1, Install Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = 'b53c9ff336e168643b10c4a9cfff4276'; 'Filename' = 'workbench31locale.adf'; 'Name' = 'Workbench 3.1, Locale Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = '4fa1401aeb814d3ed138f93c54a5caef'; 'Filename' = 'workbench31storage.adf'; 'Name' = 'Workbench 3.1, Storage Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = '590c42a69675d6970df350e200fe25dc'; 'Filename' = 'workbench31workbench.adf'; 'Name' = 'Workbench 3.1, Workbench Disk (Cloanto Amiga Forever 2016)' },

    @{ 'Md5' = 'c5be06daf40d4c3ace4eac874d9b48b1'; 'Filename' = 'workbench31install.adf'; 'Name' = 'Workbench 3.1, Install Disk (Cloanto Amiga Forever 7)' },
    @{ 'Md5' = 'e7b3a83df665a85e7ec27306a152b171'; 'Filename' = 'workbench31workbench.adf'; 'Name' = 'Workbench 3.1, Workbench Disk (Cloanto Amiga Forever 7)' }
)

# kickstart rom md5 entries
$kickstartRomMd5Entries = @(
    @{ 'Md5' = 'c56ca2a3c644d53e780a7e4dbdc6b699'; 'Filename' = 'kick33180.A500'; 'Encrypted' = $true; 'Name' = 'Kickstart 1.2, 33.180, A500 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = '89160c06ef4f17094382fc09841557a6'; 'Filename' = 'kick34005.A500'; 'Encrypted' = $true; 'Name' = 'Kickstart 1.3, 34.5, A500 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = 'c3e114cd3b513dc0377a4f5d149e2dd9'; 'Filename' = 'kick40063.A600'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1, 40.063, A600 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = 'dc3f5e4698936da34186d596c53681ab'; 'Filename' = 'kick40068.A1200'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1, 40.068, A1200 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = '8b54c2c5786e9d856ce820476505367d'; 'Filename' = 'kick40068.A4000'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1, 40.068, A4000 Rom (Cloanto Amiga Forever 7/2016)' },

    @{ 'Md5' = '85ad74194e87c08904327de1a9443b7a'; 'Filename' = 'kick33180.A500'; 'Encrypted' = $false; 'Name' = 'Kickstart 1.2, 33.180, A500 Rom (Original)' },
    @{ 'Md5' = '82a21c1890cae844b3df741f2762d48d'; 'Filename' = 'kick34005.A500'; 'Encrypted' = $false; 'Name' = 'Kickstart 1.3, 34.5, A500 Rom (Original)' },
    @{ 'Md5' = 'e40a5dfb3d017ba8779faba30cbd1c8e'; 'Filename' = 'kick40063.A600'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1, 40.063, A600 Rom (Original)' },
    @{ 'Md5' = '646773759326fbac3b2311fd8c8793ee'; 'Filename' = 'kick40068.A1200'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1, 40.068, A1200 Rom (Original)' },
    @{ 'Md5' = '9bdedde6a4f33555b4a270c8ca53297d'; 'Filename' = 'kick40068.A4000'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1, 40.068, A4000 Rom (Original)' }
)

# os 39 md5 entries
$os39Md5Entries = @(
    @{ 'Md5' = '3cb96e77d922a4f8eb696e525a240448'; 'Filename' = 'amigaos3.9.iso'; 'Name' = 'Amiga OS 3.9 iso'; 'Size' = 490856448 },
    @{ 'Md5' = 'e32a107e68edfc9b28a2fe075e32e5f6'; 'Filename' = 'amigaos3.9.iso'; 'Name' = 'Amiga OS 3.9 iso'; 'Size' = 490686464 },
    @{ 'Md5' = '71353d4aeb9af1f129545618d013a8c8'; 'Filename' = 'boingbag39-1.lha'; 'Name' = 'Boing Bag 1 for Amiga OS 3.9'; 'Size' = 5254174 },
    @{ 'Md5' = 'fd45d24bb408203883a4c9a56e968e28'; 'Filename' = 'boingbag39-2.lha'; 'Name' = 'Boing Bag 2 for Amiga OS 3.9'; 'Size' = 2053444 }
)


# set install directory to current directory, if not defined
if (!$installDir)
{
    $installDir = '.'
}

# set amiga forever data directory to amiga forever data environment variable, if not defined
if (!$amigaForeverDataDir -and ${Env:AMIGAFOREVERDATA} -ne $null)
{
    $amigaForeverDataDir = ${Env:AMIGAFOREVERDATA}
}

# cloanto amiga forever data directory
if (!$amigaForeverDataDir -or !(Test-Path -Path $amigaForeverDataDir))
{
    $amigaForeverDataDir = $null
}


# resolve paths
$installDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($installDir)

# self install directories
$workbenchDir = Join-Path $installDir -ChildPath "workbench"
$kickstartDir = Join-Path $installDir -ChildPath "kickstart"
$os39Dir = Join-Path $installDir -ChildPath "os39"
$userPackagesDir = Join-Path $installDir -ChildPath "userpackages"

# write hstwb image setup title
Write-Output "-----------------"
Write-Output "HstWB Image Setup"
Write-Output "-----------------"
Write-Output "Author: Henrik Noerfjand Stengaard"
Write-Output "Date: 2018-05-30"
Write-Output ""
Write-Output ("Install dir '{0}'" -f $installDir)

# create self install directories, if they don't exist
foreach ($selfInstallDir in @($workbenchDir, $kickstartDir, $os39Dir, $userPackagesDir))
{
    if (!(Test-Path -Path $selfInstallDir))
    {
        mkdir $selfInstallDir | Out-Null
    }
}

# cloanto amiga forever
Write-Output ""
Write-Output "Cloanto Amiga Forever"
Write-Output "---------------------"
Write-Output ("Installing Workbench 3.1 adf and Kickstart rom files from Cloanto Amiga Forever...")
if ($amigaForeverDataDir -and (Test-Path -Path $amigaForeverDataDir))
{
    Write-Output ("- Amiga Forever data dir detected '{0}'" -f $amigaForeverDataDir)
    $sharedDir = Join-Path $amigaForeverDataDir -ChildPath 'Shared'
    
    # install workbench 3.1 adf rom files from cloanto amiga forever data directory, if shared adf directory exists
    $sharedAdfDir = Join-Path $sharedDir -ChildPath "adf"
    if (Test-Path -path $sharedAdfDir)
    {
        Write-Output ("- Installing Workbench 3.1 adf files to Workbench directory '{0}'..." -f $workbenchDir)

        # index workbench 3.1 adf md5
        $workbench31AdfMd5Index = @{}
        $workbench31AdfMd5Entries | `
            ForEach-Object { $workbench31AdfMd5Index[$_.Md5.ToLower()] = $_ }

        # copy workbench 3.1 adf files from shared adf dir that matches workbench 3.1 md5
        GetMd5FilesFromDir $sharedAdfDir | `
            Where-Object { $workbench31AdfMd5Index.ContainsKey($_.Md5.ToLower()) } | `
            ForEach-Object { Copy-Item $_.File -Destination $workbenchDir -Force }
    }
    else
    {
        Write-Output ("- Amiga Forever data shared adf directory '{0}' doesn't exist!" -f $sharedAdfDir)
    }

    # install kickstart rom files from cloanto amiga forever data directory, if shared rom directory exists
    $sharedRomDir = Join-Path $sharedDir -ChildPath "rom"
    if (Test-Path -Path $sharedRomDir)
    {
        Write-Output ("- Installing Kickstart rom files to Kickstart directory '{0}'..." -f $kickstartDir)

        # index kickstart rom md5
        $kickstartRomMd5Index = @{}
        $kickstartRomMd5Entries | `
            Where-Object { $_.Encrypted } | `
            ForEach-Object { $kickstartRomMd5Index[$_.Md5.ToLower()] = $_ }

        # copy kickstart rom files from shared rom dir that matches kickstart rom md5
        GetMd5FilesFromDir $sharedRomDir | `
            Where-Object { $kickstartRomMd5Index.ContainsKey($_.Md5.ToLower()) } | `
            ForEach-Object { Copy-Item $_.File -Destination $kickstartDir -Force }

        # copy amiga forever rom key file, if it exists
        $romKeyFile = Join-Path $sharedRomDir -ChildPath 'rom.key'
        if (Test-Path $romKeyFile)
        {
            Copy-Item $romKeyFile -Destination $kickstartDir -Force
        }
    }
    else
    {
        Write-Output ("- Amiga Forever data shared rom directory '{0}' doesn't exist!" -f $sharedRomDir)
    }
}
else
{
    Write-Output ("- Amiga Forever data directory doesn't exist!")
}
Write-Output "Done"


# write self install directories
Write-Output ""
Write-Output "Self install directories"
Write-Output "------------------------"
Write-Output ("Validating Workbench dir '{0}'..." -f $workbenchDir)

# index workbench 3.1 adf md5
$workbench31AdfMd5Index = @{}
$workbench31AdfMd5Entries | `
    ForEach-Object { $workbench31AdfMd5Index[$_.Md5.ToLower()] = $_ }

# get workbench 3.1 adf files from workbench dir that matches workbench 3.1 md5
$workbench31AdfMd5Files = GetMd5FilesFromDir $workbenchDir | `
    Where-Object { $workbench31AdfMd5Index.ContainsKey($_.Md5.ToLower()) }

# workbench 3.1 adf filenames
$workbench31AdfFilenames = $workbench31AdfMd5Entries.Filename | `
    Sort-Object | `
    Get-Unique

# workbench 3.1 adf filenames detected
$workbench31AdfFilenamesDetected = $workbench31AdfMd5Files | `
    Where-Object { $workbench31AdfMd5Index.ContainsKey($_.Md5.ToLower()) } | `
    ForEach-Object { $workbench31AdfMd5Index[$_.Md5.ToLower()].Filename } | `
    Sort-Object | `
    Get-Unique

# write workbench 3.1 adf files
Write-Output ("- {0} of {1} Workbench 3.1 adf files detected" -f $workbench31AdfFilenamesDetected.Count, $workbench31AdfFilenames.Count)
$workbench31AdfMd5Files | `
    ForEach-Object { Write-Output ("- {0} MD5 match '{1}'" -f $workbench31AdfMd5Index[$_.Md5.ToLower()].Name, $_.File) }
Write-Output "Done"


# write kickstart directory
Write-Output ""
Write-Output ("Validating Kickstart dir '{0}'..." -f $kickstartDir)

# index kickstart rom md5
$kickstartRomMd5Index = @{}
$kickstartRomMd5Entries | `
    ForEach-Object { $kickstartRomMd5Index[$_.Md5.ToLower()] = $_ }

# get kickstart rom files from kickstart dir that matches kickstart rom md5
$kickstartRomMd5Files = GetMd5FilesFromDir $kickstartDir | `
    Where-Object { $kickstartRomMd5Index.ContainsKey($_.Md5.ToLower()) }

# workbench 3.1 adf filenames
$kickstartRomFilenames = $kickstartRomMd5Entries.Filename | `
    Sort-Object | `
    Get-Unique

# workbench 3.1 adf filenames detected
$kickstartRomFilenamesDetected = $kickstartRomMd5Files | `
    Where-Object { $kickstartRomMd5Index.ContainsKey($_.Md5.ToLower()) } | `
    ForEach-Object { $kickstartRomMd5Index[$_.Md5.ToLower()].Filename } | `
    Sort-Object | `
    Get-Unique
    
# write workbench 3.1 adf files
Write-Output ("- {0} of {1} Kickstart rom files detected" -f $kickstartRomFilenamesDetected.Count, $kickstartRomFilenames.Count)
$kickstartRomMd5Files | `
    ForEach-Object { Write-Output ("- {0} MD5 match '{1}'" -f $kickstartRomMd5Index[$_.Md5.ToLower()].Name, $_.File) }
Write-Output "Done"


# write os39 directory
Write-Output ""
Write-Output ("Validating OS39 dir '{0}'..." -f $os39Dir)

# index os39 md5
$os39Md5Index = @{}
$os39Md5Entries | `
    ForEach-Object { $os39Md5Index[$_.Md5.ToLower()] = $_ }

# os39 filenames
$os39FilenamesIndex = @{}
$os39Md5Entries | `
    ForEach-Object { $os39FilenamesIndex[$_.Filename.ToLower()] = $_ }

# get os39 files from os39 dir
$os39Md5Files = GetMd5FilesFromDir $os39Dir

# os39 filenames detected
$os39FilenamesDetectedIndex = @{}
$os39Md5Files | `
    Where-Object { $os39FilenamesIndex.ContainsKey((Split-Path $_.File -Leaf).ToLower()) } | `
    ForEach-Object { $os39FilenamesDetectedIndex[$os39FilenamesIndex[(Split-Path $_.File -Leaf).ToLower()].Filename] = $_ }
$os39Md5Files | `
    Where-Object { $os39Md5Index.ContainsKey($_.Md5.ToLower()) } | `
    ForEach-Object { $os39FilenamesDetectedIndex[$os39Md5Index[$_.Md5.ToLower()].Filename] = $_ }

# write os39 files
Write-Output ("- {0} Amiga OS 3.9 files detected" -f $os39FilenamesDetectedIndex.Count)
foreach($os39Filename in ($os39FilenamesDetectedIndex.Keys | Sort-Object))
{
    $os39File = $os39FilenamesDetectedIndex[$os39Filename]

    if ($os39Md5Index.ContainsKey($os39File.Md5.ToLower()))
    {
        ForEach-Object { Write-Output ("- {0} MD5 match '{1}'" -f $os39Md5Index[$os39File.Md5.ToLower()].Name, $os39File.File) }
    }
    elseif ($os39FilenamesIndex.ContainsKey($os39Filename))
    {
        ForEach-Object { Write-Output ("- {0} filename match '{1}'" -f $os39FilenamesIndex[$os39Filename].Name, $os39File.File) }
    }
}
Write-Output "Done"


# write user packages directory
Write-Output ""
Write-Output ("Validating User Packages dir '{0}'..." -f $userPackagesDir)

$userPackageDirs = @()
$userPackageDirs += Get-ChildItem $userPackagesDir | `
    Where-Object { $_.PSIsContainer -and (Test-Path (Join-Path $_.FullName -ChildPath '_installdir')) }

Write-Output ("- {0} user packages detected" -f $userPackageDirs.Count)
$userPackageDirs | `
    ForEach-Object { Write-Output ("- {0} '{1}'" -f $_.Name, $_.FullName) }
Write-Output "Done"


# write files for patching
Write-Output ""
Write-Output "Files for patching"
Write-Output "------------------"
Write-Output "Finding A1200 Kickstart 3.1 rom and Amiga OS 3.9 iso files for patching configuration files..."

# find first a1200 kickstart 3.1 rom md5 file
$a1200KickstartRomMd5File = $kickstartRomMd5Files | `
    Where-Object { $kickstartRomMd5Index.ContainsKey($_.Md5.ToLower()) -and $kickstartRomMd5Index[$_.Md5.ToLower()].Filename -match 'kick40068\.A1200' } | `
    Select-Object -First 1

# find a1200 kickstart 3.1 rom file
$a1200KickstartRomFile = $null
if ($a1200KickstartRomMd5File)
{
    # fail, if a1200 kickstart rom entry is encrypted and rom key file doesn't exist
    $romKeyFile = Join-Path $kickstartDir -ChildPath 'rom.key'
    if ($a1200KickstartRomMd5Entry.Encrypted -and !(Test-Path $romKeyFile))
    {
        throw ("Amiga Forever rom key file '{0}' doesn't exist" -f $romKeyFile)
    }

    $a1200KickstartRomFile = $a1200KickstartRomMd5File.File
}

if ($a1200KickstartRomFile)
{
    Write-Output ("- Using A1200 Kickstart 3.1 rom file '{0}'" -f $a1200KickstartRomFile)
}
else
{
    Write-Output "- No A1200 Kickstart 3.1 rom file detected"
}

$amigaOs39IsoMd5File = $os39Md5Files | `
    Where-Object { ($os39Md5Index.ContainsKey($_.Md5.ToLower()) -and $os39Md5Index[$_.Md5.ToLower()].Filename -match 'amigaos3\.9\.iso$') -or ($_.File -match '\\?amigaos3\.9\.iso$') } | `
    Sort-Object @{expression={!$os39Md5Index.ContainsKey($_.Md5.ToLower())}} | `
    Select-Object -First 1

$amigaOs39IsoFile = $null
if ($amigaOs39IsoMd5File)
{
    $amigaOs39IsoFile = $amigaOs39IsoMd5File.File
    Write-Output ("- Using Amiga OS 3.9 iso file '{0}'" -f $amigaOs39IsoFile)
}
else
{
    Write-Output "- No Amiga OS 3.9 iso file detected"
}

Write-Output "Done"


# write uae configuration
Write-Output ""
Write-Output "UAE configuration"
Write-Output "-----------------"


# winuae config directory
$winuaeConfigDir = Get-ChildItem -Path ${Env:PUBLIC} -Recurse | `
    Where-Object { $_.PSIsContainer -and $_.FullName -match 'Amiga Files\\WinUAE\\Configurations$' } | `
    Select-Object -First 1

# get uae config files from install directory
$uaeConfigFiles = @()
$uaeConfigFiles += Get-ChildItem $installDir -Filter *.uae

# patch and install uae configuration files
Write-Output ("Patching and installing UAE configuration files from '{0}'..." -f $installDir)

# write winuae configuration dir, if it exists
if ($winuaeConfigDir)
{
    Write-Output ("- WinUAE configuration dir detected '{0}'" -f $winuaeConfigDir.FullName)
}

if ($uaeConfigFiles.Count -gt 0)
{
    foreach($uaeConfigFile in $uaeConfigFiles)
    {
        Write-Output ("- UAE configuration file '{0}'..." -f $uaeConfigFile.FullName)

        # patch uae config file
        PatchUaeConfigFile $uaeConfigFile.FullName $a1200KickstartRomFile $amigaOs39IsoFile

        # install winuae config file, if winuae config directory exists
        if ($winuaeConfigDir)
        {
            Copy-Item $uaeConfigFile.FullName -Destination $winuaeConfigDir.FullName -Force
        }
    }
}
else
{
    Write-Output ("- No UAE configuration files detected")
}
Write-Output "Done"


# write fs-uae configuration
Write-Output ""
Write-Output "FS-UAE configuration"
Write-Output "--------------------"

# get fs-uae config directory from my documents directory
$fsuaeConfigDir = Get-ChildItem -Path ([System.Environment]::GetFolderPath("MyDocuments")) -Recurse | `
    Where-Object { $_.PSIsContainer -and $_.FullName -match 'FS-UAE\\Configurations$' } | `
    Select-Object -First 1

# get fs-uae config files from install directory
$fsuaeConfigFiles = @()
$fsuaeConfigFiles += Get-ChildItem $installDir -Filter *.fs-uae

# patch and install fs-uae configuration files
Write-Output ("Patching and installing FS-UAE configuration files from '{0}'..." -f $installDir)

# write fs-uae configuration dir, if it exists
if ($fsuaeConfigDir)
{
    Write-Output ("- FS-UAE configuration dir detected '{0}'" -f $fsuaeConfigDir.FullName)
}

if ($fsuaeConfigFiles.Count -gt 0)
{
    foreach($fsuaeConfigFile in $fsuaeConfigFiles)
    {
        Write-Output ("- FS-UAE configuration file '{0}'" -f $fsuaeConfigFile.FullName)
        PatchFsuaeConfigFile $fsuaeConfigFile.FullName $a1200KickstartRomFile $amigaOs39IsoFile

        # install fs-uae config file, if fs-uae config directory exists
        if ($fsuaeConfigDir)
        {
            Copy-Item $fsuaeConfigFile.FullName -Destination $fsuaeConfigDir.FullName -Force
        }
    }
}
else
{
    Write-Output ("- No FS-UAE configuration files detected")
}
Write-Output "Done"