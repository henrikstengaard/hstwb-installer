# HstWB Image Setup
# -----------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2019-01-18
#
# A powershell script to setup HstWB images with following installation steps:
#
# 1. Find Cloanto Amiga Forever data dir.
#    - Drives or mounted iso.
#    - Environment variable "AMIGAFOREVERDATA".
# 2. Detect if UAE or FS-UAE configuration files contains self install directories.
#    - Detect and install Amiga OS 3.1 adf and Kickstart rom files from Cloanto Amiga Forever data dir using MD5 hashes.
#    - Validate files in self install directories using MD5 hashes to indicate, if all files are present for self install.
# 3. Detect files for patching configuration files.
#    - Find A1200 Kickstart rom in kickstart dir.
#    - Find Amiga OS 3.9 iso file in amiga os dir.
# 4. Patch and install UAE and FS-UAE configuration files.
#    - For FS-UAE configuration files, .adf files from Workbench directory are added as swappable floppies.


Param(
	[Parameter(Mandatory=$false)]
    [string]$installDir,
	[Parameter(Mandatory=$false)]
    [string]$amigaOsDir,
	[Parameter(Mandatory=$false)]
    [string]$kickstartDir,
	[Parameter(Mandatory=$false)]
    [string]$userPackagesDir,
	[Parameter(Mandatory=$false)]
    [string]$amigaForeverDataDir,
	[Parameter(Mandatory=$false)]
    [string]$uaeInstallDir,
	[Parameter(Mandatory=$false)]
    [string]$fsuaeInstallDir,
	[Parameter(Mandatory=$false)]
    [switch]$patchOnly,
	[Parameter(Mandatory=$false)]
    [switch]$selfInstall
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

# config file has self install dirs
function ConfigFileHasSelfInstallDirs($configFile)
{
    return (Get-Content $configFile | `
        Where-Object { $_ -match '^hard_drive_\d+_label\s*=\s*(amigaosdir|kickstartdir|userpackagesdir)' -or `
        $_ -match '^(hardfile2|uaehf\d+|filesystem2)=.+(amigaosdir|kickstartdir|userpackagesdir):' }).Count -gt 0
}

# find amiga forever data for from media windows
function FindAmigaForeverDataDirFromMediaWindows()
{
    $drives = [System.IO.DriveInfo]::GetDrives() | Foreach-Object { $_.RootDirectory }

    foreach($drive in $drives)
    {
        $amigaForeverDataDir = FindValidAmigaFilesDir $drive

        if ($amigaForeverDataDir)
        {
            return $amigaForeverDataDir
        }
    }

    return $null
}

# find valid amiga files dir
function FindValidAmigaFilesDir($dir)
{
    if (!(Test-Path $dir))
    {
        return $null
    }

    $amigaFiles = Get-ChildItem $dir | `
        Where-Object { $_.Name -match '^amiga\sfiles$' } | `
        Select-Object -First 1

    if (!$amigaFiles)
    {
        return $null
    }

    return $amigaFiles.FullName
}

# get fsuae config dir
function GetFsuaeConfigDir()
{
    # get fs-uae config directory from my documents directory
    $fsuaeConfigurations = Get-ChildItem -Path ([System.Environment]::GetFolderPath("MyDocuments")) -Recurse | `
        Where-Object { $_.PSIsContainer -and $_.FullName -match 'FS-UAE\\Configurations$' } | `
        Select-Object -First 1

    if (!$fsuaeConfigurations)
    {
        return $null
    }

    return $fsuaeConfigurations.FullName
}

# get winuae config dir
function GetWinuaeConfigDir()
{
    $configurationPath = Get-ItemProperty -Path 'HKCU:\Software\Arabuusimiehet\WinUAE' -name 'ConfigurationPath'

    if (!$configurationPath)
    {
        return $null
    }

    return $configurationPath.ConfigurationPath
}

# patch uae config file
function PatchUaeConfigFile($uaeConfigFile, $a1200KickstartRomFile, $amigaOs39IsoFile, $amigaOsDir, $kickstartDir, $userPackagesDir)
{
    # self install dirs index
    $selfInstallDirsIndex = 
    @{
        'amigaosdir' = $amigaOsDir;
        'kickstartdir' = $kickstartDir;
        'userpackagesdir' = $userPackagesDir;
    }

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
        if ($line -match '^cdimage0=' -and $amigaOs39IsoFile)
        {
            $line = "cdimage0={0}" -f $amigaOs39IsoFile
        }
        
        # patch kickstart rom file
        if ($line -match '^kickstart_rom_file=' -and $a1200KickstartRomFile)
        {
            $line = "kickstart_rom_file={0}" -f $a1200KickstartRomFile
        }

        # patch hardfile2 to current directory
        if ($line -match '^hardfile2=')
        {
            $hardfileDevice = $line | Select-String -Pattern '^hardfile2=[^,]*,([^:]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
            $hardfilePath = $line | Select-String -Pattern '^hardfile2=[^,]*,[^:]*:([^,]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

            if ($hardfileDevice -and $hardfilePath)
            {
                $hardfilePath = if ($selfInstallDirsIndex.ContainsKey($hardfileDevice.ToLower()))
                {
                    $selfInstallDirsIndex[$hardfileDevice]
                }
                else
                {
                    Join-Path $uaeConfigDir -ChildPath (Split-Path $hardfilePath -Leaf)
                }
                
                $line = $line -replace '^(hardfile2=[^,]*,[^,:]*:)[^,]*', "`$1$hardfilePath"
            }
        }

        # patch uaehf to current directory
        if ($line -match '^uaehf\d+=')
        {
            $uaehfDevice = $line | Select-String -Pattern '^uaehf\d+=[^,]*,[^,]*,([^,:]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
            $uaehfPath = $line | Select-String -Pattern '^uaehf\d+=[^,]*,[^,]*,[^,:]*:"?([^,"]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
            
            if ($uaehfDevice -and $uaehfPath)
            {
                $uaehfPath = if ($selfInstallDirsIndex.ContainsKey($uaehfDevice.ToLower()))
                {
                    $selfInstallDirsIndex[$uaehfDevice].Replace('\', '\\')
                }
                else
                {
                    (Join-Path $uaeConfigDir -ChildPath (Split-Path ($uaehfPath.Replace('\\', '\')) -Leaf)).Replace('\', '\\')
                }
                
                $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:"?)[^,"]*', "`$1$uaehfPath"
            }
        }
        
        # patch filesystem2 to current directory
        if ($line -match '^filesystem2=')
        {
            $filesystemDevice = $line | Select-String -Pattern '^filesystem2=[^,]*,([^,:]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
            $filesystemPath = $line | Select-String -Pattern '^filesystem2=[^,]*,[^,:]*:[^:]*:([^,]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

            if ($filesystemDevice -and $filesystemPath)
            {
                $filesystemPath = if ($selfInstallDirsIndex.ContainsKey($filesystemDevice.ToLower()))
                {
                    $selfInstallDirsIndex[$filesystemDevice].Replace('\', '\\')
                }
                else
                {
                    Join-Path $uaeConfigDir -ChildPath (Split-Path $filesystemPath -Leaf)
                }
                
                $line = $line -replace '^(filesystem2=[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$filesystemPath"
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
function PatchFsuaeConfigFile($fsuaeConfigFile, $a1200KickstartRomFile, $amigaOs39IsoFile, $amigaOsDir, $kickstartDir, $userPackagesDir)
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
        if ($line -match '^cdrom_drive_0\s*=' -and $amigaOs39IsoFile)
        {
            $line = "cdrom_drive_0 = {0}" -f $amigaOs39IsoFile.Replace('\', '/')
        }
        
        # patch logs dir
        if ($line -match '^logs_dir\s*=')
        {
            $line = "logs_dir = {0}" -f $fsuaeConfigDir.Replace('\', '/')
        }

        # patch kickstart file
        if ($line -match '^kickstart_file\s*=' -and $a1200KickstartRomFile)
        {
            $line = "kickstart_file = {0}" -f $a1200KickstartRomFile.Replace('\', '/')
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
                $harddrivePath = switch ($harddriveLabels[$harddriveIndex].ToLower())
                {
                    'amigaosdir' { $amigaOsDir }
                    'kickstartdir' { $kickstartDir }
                    'userpackagesdir' { $userPackagesDir }
                    default { Join-Path $fsuaeConfigDir -ChildPath (Split-Path $harddrivePath -Leaf) }
                }

                $line = $line -replace '^(hard_drive_\d+\s*=\s*).*', ("`$1{0}" -f $harddrivePath.Replace('\', '/'))
            }
        }

        # update line, if it's changed
        if ($line -ne $fsuaeConfigLines[$i])
        {
            $fsuaeConfigLines[$i] = $line
        }
    }

    # get adf files from amiga os dir
    $adfFiles = @()
    if ($amigaOsDir -and (Test-Path -Path $amigaOsDir))
    {
        $adfFiles += Get-ChildItem -Path $amigaOsDir -Filter *.adf | Where-Object { ! $_.PSIsContainer }
    }

    # add adf files to fs-uae config lines as swappable floppies
    if ($adfFiles.Count -gt 0)
    {
        $fsuaeConfigLines += ''
        for ($i = 0; $i -lt $adfFiles.Count; $i++)
        {
            $fsuaeConfigLines += "floppy_image_{0} = {1}" -f $i, $adfFiles[$i].FullName.Replace('\', '/')
        }
    }

    # write fs-uae config file without byte order mark
    $utf8Encoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines($fsuaeConfigFile, $fsuaeConfigLines, $utf8Encoding)
}


# valid amiga os 3.1 adf md5 entries
$validAmigaOs31Md5Entries = @(
    @{ 'Md5' = 'c1c673eba985e9ab0888c5762cfa3d8f'; 'Filename' = 'workbench31extras.adf'; 'Name' = 'Workbench 3.1, Extras Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = '6fae8b94bde75497021a044bdbf51abc'; 'Filename' = 'workbench31fonts.adf'; 'Name' = 'Workbench 3.1, Fonts Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = 'd6aa4537586bf3f2687f30f8d3099c99'; 'Filename' = 'workbench31install.adf'; 'Name' = 'Workbench 3.1, Install Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = 'b53c9ff336e168643b10c4a9cfff4276'; 'Filename' = 'workbench31locale.adf'; 'Name' = 'Workbench 3.1, Locale Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = '4fa1401aeb814d3ed138f93c54a5caef'; 'Filename' = 'workbench31storage.adf'; 'Name' = 'Workbench 3.1, Storage Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = '590c42a69675d6970df350e200fe25dc'; 'Filename' = 'workbench31workbench.adf'; 'Name' = 'Workbench 3.1, Workbench Disk (Cloanto Amiga Forever 2016)' },

    @{ 'Md5' = 'c5be06daf40d4c3ace4eac874d9b48b1'; 'Filename' = 'workbench31install.adf'; 'Name' = 'Workbench 3.1, Install Disk (Cloanto Amiga Forever 7)' },
    @{ 'Md5' = 'e7b3a83df665a85e7ec27306a152b171'; 'Filename' = 'workbench31workbench.adf'; 'Name' = 'Workbench 3.1, Workbench Disk (Cloanto Amiga Forever 7)' }
)

# valid amiga os 3.1.4 adf md5 entries
$validAmigaOs314Md5Entries = @(
    @{ 'Md5' = '988ddad5106d5b846be57b711d878b4c'; 'Filename' = 'amiga-os-314-extras.adf'; 'Name' = 'Amiga OS 3.1.4, Extras Disk' },
    @{ 'Md5' = '27a7af42777a43a06f8d9d8e74226e56'; 'Filename' = 'amiga-os-314-fonts.adf'; 'Name' = 'Amiga OS 3.1.4, Fonts Disk' },
    @{ 'Md5' = '7e9b5ec9cf89d9aae771cd1b708792d9'; 'Filename' = 'amiga-os-314-install.adf'; 'Name' = 'Amiga OS 3.1.4, Install Disk' },
    @{ 'Md5' = '4007bfe06b5b51af981a3fa52c51f54a'; 'Filename' = 'amiga-os-314-locale.adf'; 'Name' = 'Amiga OS 3.1.4, Locale Disk' },
    @{ 'Md5' = '372215cd27888d65a95db92b6513e702'; 'Filename' = 'amiga-os-314-storage.adf'; 'Name' = 'Amiga OS 3.1.4, Storage Disk' },
    @{ 'Md5' = '05a7469fd903744aa5f53741765bf668'; 'Filename' = 'amiga-os-314-workbench.adf'; 'Name' = 'Amiga OS 3.1.4, Workbench Disk' },
    @{ 'Md5' = '8a3824e64dbe2c8327d5995188d5fdd3'; 'Filename' = 'amiga-os-314-modules-a500.adf'; 'Name' = 'Amiga OS 3.1.4, Modules A500 Disk (1st release)' },
    @{ 'Md5' = '2065c8850b5ba97099c3ff2672221e3f'; 'Filename' = 'amiga-os-314-modules-a500.adf'; 'Name' = 'Amiga OS 3.1.4, Modules A500 Disk (2nd release)' },
    @{ 'Md5' = 'c5a96c56ee5a7e2ca639c755d89dda36'; 'Filename' = 'amiga-os-314-modules-a600.adf'; 'Name' = 'Amiga OS 3.1.4, Modules A600 Disk (1st release)' },
    @{ 'Md5' = '4e095037af1da015c09ed26e3e107f50'; 'Filename' = 'amiga-os-314-modules-a600.adf'; 'Name' = 'Amiga OS 3.1.4, Modules A600 Disk (2nd release)' },
    @{ 'Md5' = 'b201f0b45c5748be103792e03f938027'; 'Filename' = 'amiga-os-314-modules-a2000.adf'; 'Name' = 'Amiga OS 3.1.4, Modules A2000 Disk (1st release)' },
    @{ 'Md5' = 'b8d09ea3369ac538c3920c515ba76e86'; 'Filename' = 'amiga-os-314-modules-a2000.adf'; 'Name' = 'Amiga OS 3.1.4, Modules A2000 Disk (2nd release)' },
    @{ 'Md5' = '2797193dc7b7daa233abe1bcfee9d5a1'; 'Filename' = 'amiga-os-314-modules-a1200.adf'; 'Name' = 'Amiga OS 3.1.4, Modules A1200 Disk (1st release)' },
    @{ 'Md5' = 'd170f8c11d1eb52f12643e0f13b44886'; 'Filename' = 'amiga-os-314-modules-a1200.adf'; 'Name' = 'Amiga OS 3.1.4, Modules A1200 Disk (2nd release)' },
    @{ 'Md5' = '60263124ea2c5f1831a3af639d085a28'; 'Filename' = 'amiga-os-314-modules-a3000.adf'; 'Name' = 'Amiga OS 3.1.4, Modules A3000 Disk (1st release)' },
    @{ 'Md5' = '7d20dc438e802e41def3694d2be59f0f'; 'Filename' = 'amiga-os-314-modules-a4000d.adf'; 'Name' = 'Amiga OS 3.1.4, Modules A4000D Disk (1st release)' },
    @{ 'Md5' = '68fb2ca4b81daeaf140d35dc7a63d143'; 'Filename' = 'amiga-os-314-modules-a4000t.adf'; 'Name' = 'Amiga OS 3.1.4, Modules A4000T Disk (1st release)' }
)

# valid kickstart rom md5 entries
$validKickstartMd5Entries = @(
    @{ 'Md5' = 'c56ca2a3c644d53e780a7e4dbdc6b699'; 'Filename' = 'kick33180.A500'; 'Encrypted' = $true; 'Name' = 'Kickstart 1.2, 33.180, A500 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = '89160c06ef4f17094382fc09841557a6'; 'Filename' = 'kick34005.A500'; 'Encrypted' = $true; 'Name' = 'Kickstart 1.3, 34.5, A500 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = 'c3e114cd3b513dc0377a4f5d149e2dd9'; 'Filename' = 'kick40063.A600'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1, 40.063, A600 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = 'dc3f5e4698936da34186d596c53681ab'; 'Filename' = 'kick40068.A1200'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1, 40.068, A1200 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = '8b54c2c5786e9d856ce820476505367d'; 'Filename' = 'kick40068.A4000'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1, 40.068, A4000 Rom (Cloanto Amiga Forever 7/2016)' },

    @{ 'Md5' = '6de08cd5c5efd926d0a7643e8fb776fe'; 'Filename' = 'kick.a1200.46.143'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1.4, 46.143, A1200 Rom (Original, 1st release)' },
    @{ 'Md5' = '79bfe8876cd5abe397c50f60ea4306b9'; 'Filename' = 'kick.a1200.46.143'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1.4, 46.143, A1200 Rom (Original, 2nd release)' },
    
    @{ 'Md5' = '85ad74194e87c08904327de1a9443b7a'; 'Filename' = 'kick33180.A500'; 'Encrypted' = $false; 'Name' = 'Kickstart 1.2, 33.180, A500 Rom (Original)' },
    @{ 'Md5' = '82a21c1890cae844b3df741f2762d48d'; 'Filename' = 'kick34005.A500'; 'Encrypted' = $false; 'Name' = 'Kickstart 1.3, 34.5, A500 Rom (Original)' },
    @{ 'Md5' = 'e40a5dfb3d017ba8779faba30cbd1c8e'; 'Filename' = 'kick40063.A600'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1, 40.063, A600 Rom (Original)' },
    @{ 'Md5' = '646773759326fbac3b2311fd8c8793ee'; 'Filename' = 'kick40068.A1200'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1, 40.068, A1200 Rom (Original)' },
    @{ 'Md5' = '9bdedde6a4f33555b4a270c8ca53297d'; 'Filename' = 'kick40068.A4000'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1, 40.068, A4000 Rom (Original)' }
)

# valid amiga os 39 md5 entries
$validAmigaOs39Md5Entries = @(
    @{ 'Md5' = '3cb96e77d922a4f8eb696e525a240448'; 'Filename' = 'amigaos3.9.iso'; 'Name' = 'Amiga OS 3.9 iso'; 'Size' = 490856448 },
    @{ 'Md5' = 'e32a107e68edfc9b28a2fe075e32e5f6'; 'Filename' = 'amigaos3.9.iso'; 'Name' = 'Amiga OS 3.9 iso'; 'Size' = 490686464 },
    @{ 'Md5' = '71353d4aeb9af1f129545618d013a8c8'; 'Filename' = 'boingbag39-1.lha'; 'Name' = 'Boing Bag 1 for Amiga OS 3.9'; 'Size' = 5254174 },
    @{ 'Md5' = 'fd45d24bb408203883a4c9a56e968e28'; 'Filename' = 'boingbag39-2.lha'; 'Name' = 'Boing Bag 2 for Amiga OS 3.9'; 'Size' = 2053444 }
)

# index valid amiga os 3.1 md5 entries
$validAmigaOs31Md5Index = @{}
$validAmigaOs31Md5Entries | ForEach-Object { $validAmigaOs31Md5Index[$_['Md5'].ToLower()] = $_ }

# index valid amiga os 3.1.4 md5 entries
$validAmigaOs314Md5Index = @{}
$validAmigaOs314Md5Entries | ForEach-Object { $validAmigaOs314Md5Index[$_['Md5'].ToLower()] = $_ }

# index valid amiga os 3.9 md5 entries
$validAmigaOs39Md5Index = @{}
$validAmigaOs39FilenameIndex = @{}
$validAmigaOs39Md5Entries | ForEach-Object { $validAmigaOs39Md5Index[$_['Md5'].ToLower()] = $_; $validAmigaOs39FilenameIndex[$_['Filename'].ToLower()] = $_; }

# index valid kickstart rom md5 entries
$validKickstartMd5Index = @{}
$validKickstartMd5Entries | ForEach-Object { $validKickstartMd5Index[$_['Md5'].ToLower()] = $_ }

# set install directory to current directory, if it's not defined
if (!$installDir)
{
    $installDir = '.'
}

# resolve paths
if ($installDir)
{
    $installDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($installDir)
}
if ($amigaOsDir)
{
    $amigaOsDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($amigaOsDir)
}
if ($kickstartDir)
{
    $kickstartDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($kickstartDir)
}
if ($userPackagesDir)
{
    $userPackagesDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($userPackagesDir)
}
if ($amigaForeverDataDir)
{
    $amigaForeverDataDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($amigaForeverDataDir)
}


# write hstwb image setup title
Write-Output "-----------------"
Write-Output "HstWB Image Setup"
Write-Output "-----------------"
Write-Output "Author: Henrik Noerfjand Stengaard"
Write-Output "Date: 2019-01-18"
Write-Output ""
Write-Output ("Install dir '{0}'" -f $installDir)

if (!(Test-Path $installDir))
{
    throw ("Error: Install dir '{0}' doesn't exist" -f $installDir)
}

# set uae install directory to detected winuae config directory, if uae install directory is not defined
if (!$uaeInstallDir)
{
    $uaeInstallDir = GetWinuaeConfigDir
}

# set fs-uae install directory to detected fs-uae config directory, if fs-uae install directory is not defined
if (!$fsuaeInstallDir)
{
    $fsuaeInstallDir = GetFsuaeConfigDir
}

# get uae config files from install directory
$uaeConfigFiles = Get-ChildItem $installDir | `
    Where-Object { !$_.PSIsContainer -and $_.Name -match '\.uae$' }

# get fs-uae config files from install directory
$fsuaeConfigFiles = Get-ChildItem $installDir | `
    Where-Object { !$_.PSIsContainer -and $_.Name -match '\.fs-uae$' }

# write uae and fs-uae configuration files
Write-Output ('{0} UAE configuration file(s)' -f $uaeConfigFiles.Count)
Write-Output ('{0} FS-UAE configuration file(s)' -f $fsuaeConfigFiles.Count)
    
# detect, if uae or fs-uae config files has self install directories
$configFilesHasSelfInstallDirs = $false
if (($uaeConfigFiles | Where-Object { ConfigFileHasSelfInstallDirs $_.FullName }).Count -gt 0)
{
    $configFilesHasSelfInstallDirs = $true
}
if (!$configFilesHasSelfInstallDirs -and ($fsuaeConfigFiles | Where-Object { ConfigFileHasSelfInstallDirs $_.FullName }).Count -gt 0)
{
    $configFilesHasSelfInstallDirs = $true
}

# set self install true, if patch only is not defined and config files has self install directories
if (!$patchOnly -and $configFilesHasSelfInstallDirs)
{
    $selfInstall = $true
}

# set install directories, if self install is true
if ($selfInstall)
{
    $amigaOsDir = Join-Path $installDir -ChildPath "amigaos"
    $kickstartDir = Join-Path $installDir -ChildPath "kickstart"
    $userPackagesDir = Join-Path $installDir -ChildPath "userpackages"

    # create self install directories, if they don't exist
    foreach ($dir in @($amigaOsDir, $kickstartDir, $userPackagesDir))
    {
        if (!(Test-Path -Path $dir))
        {
            mkdir $dir | Out-Null
        }
    }
}


# autodetect amiga forever data dir, if it's not defined
if (!$amigaForeverDataDir)
{
    # find amiga forever data dir from media
    $amigaForeverDataDir = FindAmigaForeverDataDirFromMediaWindows

    # get amiga forever data dir from environment variable, if no amiga forever data dir was detected from media
    if (!$amigaForeverDataDir -and ${Env:AMIGAFOREVERDATA} -ne $null)
    {
        $amigaForeverDataDir = ${Env:AMIGAFOREVERDATA}
    }
    
    # set kickstart dir to amiga forever data dir, if self install is false and amiga forever data shared rom dir exists
    if (!$selfInstall -and $amigaForeverDataDir)
    {
        $sharedDir = Join-Path $amigaForeverDataDir -ChildPath 'Shared'
        $sharedRomDir = Join-Path $sharedDir -ChildPath "rom"
        
        if (!$kickstartDir -and (Test-Path $sharedRomDir))
        {
            $kickstartDir = $sharedRomDir
        }
    }
}

# write install directories
if ($amigaOsDir)
{
    Write-Output ('Amiga OS dir ''{0}''' -f $amigaOsDir)
}
if ($kickstartDir)
{
    Write-Output ('Kickstart dir ''{0}''' -f $kickstartDir)
}
if ($userPackagesDir)
{
    Write-Output ('User packages dir ''{0}''' -f $userPackagesDir)
}
if ($amigaForeverDataDir)
{
    Write-Output ('Amiga Forever data dir ''{0}''' -f $amigaForeverDataDir)
}

# install amiga os 3.1 adf and kickstart rom files from cloanto amiga forever data directory, if its defined
if ($selfInstall -and $amigaForeverDataDir -and (Test-Path -Path $amigaForeverDataDir))
{
    # write cloanto amiga forever
    Write-Output ''
    Write-Output 'Cloanto Amiga Forever'
    Write-Output '---------------------'
    Write-Output 'Install Amiga OS 3.1 adf and Kickstart rom files from Amiga Forever data dir...'

    $sharedDir = Join-Path $amigaForeverDataDir -ChildPath 'Shared'
    $sharedAdfDir = Join-Path $sharedDir -ChildPath "adf"
    $sharedRomDir = Join-Path $sharedDir -ChildPath "rom"

    # install amiga os 3.1 adf rom files from cloanto amiga forever data directory, if shared adf directory exists
    if (Test-Path -path $sharedAdfDir)
    {
        # copy amiga os 3.1 adf files from shared adf dir that matches valid amiga os 3.1 md5
        $installedAmigaOs31AdfFilenames = New-Object System.Collections.Generic.List[System.Object]
        foreach ($md5File in (GetMd5FilesFromDir $sharedAdfDir))
        {
            if (!$validAmigaOs31Md5Index.ContainsKey($md5File.Md5))
            {
                continue
            }
            $amigaOs31AdfFilename = Split-Path $md5File.File -Leaf
            $installedAmigaOs31AdfFilenames.Add($amigaOs31AdfFilename)
            $installedAmigaOs31AdfFile = Join-Path $amigaOsDir -ChildPath $amigaOs31AdfFilename
            Copy-Item $md5File.File -Destination $installedAmigaOs31AdfFile -Force
            Set-ItemProperty $installedAmigaOs31AdfFile -name IsReadOnly -value $false
        }

        # write installed workbench 3.1 adf files
        Write-Output ('- {0} Workbench 3.1 adf files installed ''{1}''' -f $installedAmigaOs31AdfFilenames.Count, ($installedAmigaOs31AdfFilenames -join ', '))
    }
    else
    {
        Write-Output '- No Amiga Forever data shared adf dir detected'
    }

    # install kickstart rom files from cloanto amiga forever data directory, if shared rom directory exists
    if (Test-Path -Path $sharedRomDir)
    {
        # copy kickstart rom files from shared rom dir that matches valid kickstart md5
        $installedKickstartRomFilenames = New-Object System.Collections.Generic.List[System.Object]
        foreach ($md5File in (GetMd5FilesFromDir $sharedRomDir))
        {
            if (!$validKickstartMd5Index.ContainsKey($md5File.Md5))
            {
                continue
            }
            $kickstartRomFilename = Split-Path $md5File.File -Leaf
            $installedKickstartRomFilenames.Add($kickstartRomFilename)
            $installedKickstartRomFile = Join-Path $kickstartDir -ChildPath $kickstartRomFilename
            Copy-Item $md5File.File -Destination $installedKickstartRomFile -Force
            Set-ItemProperty $installedKickstartRomFile -name IsReadOnly -value $false
        }

        # copy amiga forever rom key file, if it exists
        $romKeyFilename = 'rom.key'
        $romKeyFile = Join-Path $sharedRomDir -ChildPath $romKeyFilename
        if (Test-Path $romKeyFile)
        {
            $installedKickstartRomFilenames.Add($romKeyFilename)
            $installedKickstartRomFile = Join-Path $kickstartDir -ChildPath $romKeyFilename
            Copy-Item $romKeyFile -Destination $installedKickstartRomFile -Force
            Set-ItemProperty $installedKickstartRomFile -name IsReadOnly -value $false
        }
        
        # write installed workbench 3.1 adf files
        Write-Output ('- {0} Kickstart rom files installed ''{1}''' -f $installedKickstartRomFilenames.Count, ($installedKickstartRomFilenames -join ', '))
    }
    else
    {
        Write-Output '- No Amiga Forever data shared rom dir detected'
    }
    Write-Output 'Done'
}

# validate self install directories, if self install is defined
if ($selfInstall)
{
    # write self install directories
    Write-Output ''
    Write-Output 'Self install'
    Write-Output '------------'
    Write-Output 'Validating Amiga OS...'
    Write-Output ("- Amiga OS dir '{0}'" -f $amigaOsDir)

    # get amiga os md5 files from amiga os directory
    $amigaOsMd5Files = GetMd5FilesFromDir $amigaOsDir

    # amiga os 3.9 filenames detected
    $detectedOs39FilenamesIndex = @{}
    foreach ($md5File in $amigaOsMd5Files)
    {
        $os39Filename = Split-Path $md5File.File -Leaf
        if (!$validAmigaOs39FilenameIndex.ContainsKey($os39Filename.ToLower()))
        {
            continue
        }
        $detectedOs39FilenamesIndex[$validAmigaOs39FilenameIndex[$os39Filename.ToLower()]['Filename'].ToLower()] = `
            $md5File
    }
    foreach ($md5File in $amigaOsMd5Files)
    {
        if (!$validAmigaOs39Md5Index.ContainsKey($md5File.Md5))
        {
            continue
        }
        $detectedOs39FilenamesIndex[$validAmigaOs39Md5Index[$md5File.Md5]['Filename'].ToLower()] = `
            $md5File
    }

    # detected amiga os 3.9 filenames
    $detectedOs39Filenames = $detectedOs39FilenamesIndex.Keys | `
        Sort-Object | `
        Get-Unique

    # write detected amiga os 3.9 files
    if ($detectedOs39Filenames.Count -gt 0)
    {
        Write-Output ('- {0} Amiga OS 3.9 files detected ''{1}''' -f $detectedOs39Filenames.Count, ($detectedOs39Filenames -join ', '))
    }
    else
    {
        Write-Output '- No Amiga OS 3.9 files detected'
    }


    # detected amiga os 3.1.4 md5 index and filenames from amiga os dir that matches valid amiga os 3.1.4 md5
    $detectedAmigaOs314Md5Index = @{}
    $detectedAmigaOs314Filenames = New-Object System.Collections.Generic.List[System.Object]
    foreach ($md5File in $amigaOsMd5Files)
    {
        if (!$validAmigaOs314Md5Index.ContainsKey($md5File.Md5))
        {
            continue
        }
        $detectedAmigaOs314Md5Index[$validAmigaOs314Md5Index[$md5File.Md5]['Filename'].ToLower()] = `
            $validAmigaOs314Md5Index[$md5File.Md5]
        $detectedAmigaOs314Filenames.Add((Split-Path $md5File.File -Leaf))
    }
    $detectedAmigaOs314Filenames = $detectedAmigaOs314Filenames | `
        Sort-Object | `
        Get-Unique

    # detected amiga os 3.1.4 adfs
    $detectedAmigaOs314Adfs = $detectedAmigaOs314Md5Index.Keys | `
        Foreach-Object { $detectedAmigaOs314Md5Index[$_]['Name'] } | `
        Sort-Object | `
        Get-Unique

    # print detected amiga os 3.1.4 adf files
    if ($detectedAmigaOs314Filenames.Count -gt 0)
    {
        Write-Output ('- {0} Amiga OS 3.1.4 adf files detected ''{1}''' -f $detectedAmigaOs314Filenames.Count, ($detectedAmigaOs314Filenames -join ', '))
        Write-Output ('- {0} Amiga OS 3.1.4 adfs detected ''{1}''' -f $detectedAmigaOs314Adfs.Count, ($detectedAmigaOs314Adfs -join ', '))
    }
    else
    {
        Write-Output '- No Amiga OS 3.1.4 adf files detected'
    }


    # detected amiga os 3.1 md5 index and filenames from amiga os dir that matches valid amiga os 3.1 md5
    $detectedAmigaOs31Md5Index = @{}
    $detectedAmigaOs31Filenames = New-Object System.Collections.Generic.List[System.Object]
    foreach ($md5File in $amigaOsMd5Files)
    {
        if (!$validAmigaOs31Md5Index.ContainsKey($md5File.Md5))
        {
            continue
        }
        $detectedAmigaOs31Md5Index[$validAmigaOs31Md5Index[$md5File.Md5]['Filename'].ToLower()] = `
            $validAmigaOs31Md5Index[$md5File.Md5]
        $detectedAmigaOs31Filenames.Add((Split-Path $md5File.File -Leaf))
    }
    $detectedAmigaOs31Filenames = $detectedAmigaOs31Filenames | `
        Sort-Object | `
        Get-Unique

    # detected amiga os 3.1 adfs
    $detectedAmigaOs31Adfs = $detectedAmigaOs31Md5Index.Keys | `
        Foreach-Object { $detectedAmigaOs31Md5Index[$_]['Name'] } | `
        Sort-Object | `
        Get-Unique

    # print detected amiga os 3.1 adf files
    if ($detectedAmigaOs31Filenames.Count -gt 0)
    {
        Write-Output ('- {0} Amiga OS 3.1 adf files detected ''{1}''' -f $detectedAmigaOs31Filenames.Count, ($detectedAmigaOs31Filenames -join ', '))
        Write-Output ('- {0} Amiga OS 3.1 adfs detected ''{1}''' -f $detectedAmigaOs31Adfs.Count, ($detectedAmigaOs31Adfs -join ', '))
    }
    else
    {
        Write-Output '- No Amiga OS 3.1 adf files detected'
    }
    Write-Output 'Done'


    # write kickstart directory
    Write-Output ''
    Write-Output 'Validating Kickstart...'
    Write-Output ('- Kickstart dir ''{0}''...' -f $kickstartDir)

    # detected kickstart md5 index and filenames from kickstart dir that matches valid kickstart md5
    $detectedKickstartMd5Index = @{}
    $detectedKickstartFilenames = New-Object System.Collections.Generic.List[System.Object]
    foreach ($md5File in (GetMd5FilesFromDir $kickstartDir))
    {
        $detectedKickstartFilename = Split-Path $md5File.File -Leaf
        if ($detectedKickstartFilename -match 'rom\.key')
        {
            $detectedKickstartFilenames.Add($detectedKickstartFilename)
            continue
        }
        if (!$validKickstartMd5Index.ContainsKey($md5File.Md5))
        {
            continue
        }
        $detectedKickstartMd5Index[$validKickstartMd5Index[$md5File.Md5]['Filename'].ToLower()] = `
            $validKickstartMd5Index[$md5File.Md5]
        $detectedKickstartFilenames.Add($detectedKickstartFilename)
    }
    $detectedKickstartFilenames = $detectedKickstartFilenames | `
        Sort-Object | `
        Get-Unique

    # detected kickstart roms
    $detectedKickstartRoms = $detectedKickstartMd5Index.Keys | `
        Foreach-Object { $detectedKickstartMd5Index[$_]['Name'] } | `
        Sort-Object | `
        Get-Unique

    # write detected kickstart rom files
    if ($detectedKickstartFilenames.Count -gt 0)
    {
        Write-Output ('- {0} Kickstart rom files detected ''{1}''' -f $detectedKickstartFilenames.Count, ($detectedKickstartFilenames -join ', '))
        Write-Output ('- {0} Kickstart roms detected ''{1}''' -f $detectedKickstartRoms.Count, ($detectedKickstartRoms -join ', '))
    }
    else
    {
        Write-Output '- No Kickstart rom files detected'
    }
    Write-Output 'Done'


    # write user packages directory
    Write-Output ''
    Write-Output 'Validating User Packages'
    Write-Output ('- User Packages dir ''{0}''...' -f $userPackagesDir)

    # detected user package dirs
    $detectedUserPackageDirs = @()
    $detectedUserPackageDirs += Get-ChildItem $userPackagesDir | `
        Where-Object { $_.PSIsContainer -and (Test-Path (Join-Path $_.FullName -ChildPath '_installdir')) }

    # write detected user packages
    if ($detectedUserPackageDirs.Count -gt 0)
    {
        Write-Output ('- {0} user packages detected ''{1}''' -f $detectedUserPackageDirs.Count, ($detectedUserPackageDirs -join ', '))
    }
    else
    {
        Write-Output '- No user packages detected'
    }
    Write-Output 'Done'
}

# find files for patching, if uae or fs-uae config files are present
$a1200KickstartRomFile = $null
$amigaOs39IsoFile = $null
if ($uaeConfigFiles.Count -gt 0 -or $fsuaeConfigFiles.Count -gt 0)
{
    # write files for patching
    Write-Output ''
    Write-Output 'Files for patching'
    Write-Output '------------------'
    Write-Output 'Finding A1200 Kickstart rom and Amiga OS 3.9 iso files...'

    # find a1200 kickstart rom file, if kickstart dir is defined and exists
    if ($kickstartDir -and (Test-Path $kickstartDir))
    {
        # find first a1200 kickstart rom md5 file
        $a1200KickstartRomMd5File = GetMd5FilesFromDir $kickstartDir | `
            Where-Object { $validKickstartMd5Index.ContainsKey($_.Md5) -and $validKickstartMd5Index[$_.Md5].Filename -match '(kick40068\.A1200|kick\.a1200\.46\.143)' } | `
            Sort-Object @{expression={$validKickstartMd5Index[$_.Md5].Filename}} | `
            Select-Object -First 1

        # get a1200 kickstart rom file
        if ($a1200KickstartRomMd5File)
        {
            # fail, if a1200 kickstart rom entry is encrypted and rom key file doesn't exist
            $romKeyFile = Join-Path $kickstartDir -ChildPath 'rom.key'
            if ($validKickstartMd5Index[$a1200KickstartRomMd5File.Md5].Encrypted -and !(Test-Path $romKeyFile))
            {
                throw ('Error: Amiga Forever rom key file ''{0}'' doesn''t exist' -f $romKeyFile)
            }
            $a1200KickstartRomFile = $a1200KickstartRomMd5File.File
        }
    }

    # find amiga os 3.9 iso file, if amiga os dir is defined and exists
    if ($amigaOsDir -and (Test-Path $amigaOsDir))
    {
        # find first amiga os 3.9 md5 files matching valid amiga os 3.9 md5 hash or has name 'amigaos3.9.iso'
        $amigaOs39IsoMd5File = GetMd5FilesFromDir $amigaOsDir | `
            Where-Object { ($validAmigaOs39Md5Index.ContainsKey($_.Md5.ToLower()) -and $validAmigaOs39Md5Index[$_.Md5.ToLower()].Filename -match 'amigaos3\.9\.iso') -or ($_.File -match '\\?amigaos3\.9\.iso$') } | `
            Sort-Object @{expression={!$validAmigaOs39Md5Index.ContainsKey($_.Md5.ToLower())}} | `
            Select-Object -First 1

        # set amiga os 3.9 iso file, if amiga os39 iso md5 file is defined
        if ($amigaOs39IsoMd5File)
        {
            $amigaOs39IsoFile = $amigaOs39IsoMd5File.File
        }
    }

    # write a1200 kickstart rom file, if it's defined
    if ($a1200KickstartRomFile)
    {
        Write-Output ('- Using A1200 Kickstart rom file ''{0}''' -f $a1200KickstartRomFile)
    }
    else
    {
        Write-Output '- No A1200 Kickstart rom file detected'
    }

    # write amiga os 3.9 iso file, if it's defined
    if ($amigaOs39IsoMd5File)
    {
        Write-Output ('- Using Amiga OS 3.9 iso file ''{0}''' -f $amigaOs39IsoFile)
    }
    else
    {
        Write-Output '- No Amiga OS 3.9 iso file detected'
    }

    Write-Output 'Done'
}

# patch and install uae configuration files, if they are present
if ($uaeConfigFiles.Count -gt 0)
{
    # write uae configuration
    Write-Output ''
    Write-Output 'UAE configuration'
    Write-Output '-----------------'
    Write-Output 'Patching and installing UAE configuration files...'

    # write uae install dir, if it exists
    if ($uaeInstallDir)
    {
        Write-Output ('- UAE install dir ''{0}''' -f $uaeInstallDir)
    }

    Write-Output ('- {0} UAE configuration files ''{1}''' -f $uaeConfigFiles.Count, ($uaeConfigFiles -join ', '))
    foreach($uaeConfigFile in $uaeConfigFiles)
    {
        # patch uae config file
        PatchUaeConfigFile $uaeConfigFile.FullName $a1200KickstartRomFile $amigaOs39IsoFile $amigaOsDir $kickstartDir $userPackagesDir

        # install uae config file in uae install directory, if uae install directory is defined
        if ($uaeInstallDir)
        {
            Copy-Item $uaeConfigFile.FullName -Destination $uaeInstallDir -Force
        }
    }    
    Write-Output 'Done'
}

# patch and install fs-uae configuration files, if they are present
if ($fsuaeConfigFiles.Count -gt 0)
{
    # write fs-uae configuration
    Write-Output ""
    Write-Output "FS-UAE configuration"
    Write-Output "--------------------"

    # write fs-uae install directory, if it exists
    if ($fsuaeInstallDir)
    {
        Write-Output ('- FS-UAE install dir ''{0}''' -f $fsuaeInstallDir)
    }

    Write-Output ('- {0} FS-UAE configuration files ''{1}''' -f $fsuaeConfigFiles.Count, ($fsuaeConfigFiles -join ', '))
    foreach($fsuaeConfigFile in $fsuaeConfigFiles)
    {
        # patch fs-uae config file
        PatchFsuaeConfigFile $fsuaeConfigFile.FullName $a1200KickstartRomFile $amigaOs39IsoFile $amigaOsDir $kickstartDir $userPackagesDir

        # install fs-uae config file in fs-uae install directory, if fs-uae install directory is defined
        if ($fsuaeInstallDir)
        {
            Copy-Item $fsuaeConfigFile.FullName -Destination $fsuaeInstallDir -Force
        }
    }
    Write-Output "Done"
}