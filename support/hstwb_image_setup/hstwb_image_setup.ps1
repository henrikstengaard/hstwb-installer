# HstWB Image Setup
# -----------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2021-08-06
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
    [string]$uaeConfigDir,
	[Parameter(Mandatory=$false)]
    [string]$fsuaeDir,
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
        $_ -match '^(hardfile2|uaehf\d+|filesystem2)=.*[,:](amigaosdir|kickstartdir|userpackagesdir)[,:]' }).Count -gt 0
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

# get fsuae dir
function GetFsuaeDir()
{
    # get fs-uae config directory from my documents directory
    $fsuaeConfigurationsDir = Get-ChildItem -Path ([System.Environment]::GetFolderPath("MyDocuments")) -Recurse | `
        Where-Object { $_.PSIsContainer -and $_.FullName -match 'FS-UAE\\Configurations$' } | `
        Select-Object -First 1

    if (!$fsuaeConfigurationsDir)
    {
        return $null
    }

    return Split-Path $fsuaeConfigurationsDir.FullName -Parent
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


function ReadModelFromConfigFile($uaeConfigFile)
{
    # get model config line
    $modelConfigLine = Get-Content $uaeConfigFile | `
        Where-Object { $_ -match '^(;|#)\s+Model:\s+A\d+' } | `
        Select-Object -First 1

    # return null, if model config file doesn't exist
    if (!$modelConfigLine)
    {
        return $null
    }

    # parse model
    $model = $modelConfigLine | Select-String -Pattern '^(;|#)\s+Model:\s+(A\d+)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[2].Value.Trim() } | Select-Object -First 1

    return $model
}

# patch uae config file
function PatchUaeConfigFile($uaeConfigFile, $kickstartFile, $amigaOs39IsoFile, $amigaOsDir, $kickstartDir, $userPackagesDir)
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
    $uaeConfigLines += Get-Content $uaeConfigFile | Where-Object { $_ -notmatch '^\s*$' }

    # patch uae config lines
    for ($i = 0; $i -lt $uaeConfigLines.Count; $i++)
    {
        $line = $uaeConfigLines[$i]

        # patch cd image 0
        if ($line -match '^cdimage0=')
        {
            $amigaOs39IsoFileFormatted = if ($amigaOs39IsoFile) { $amigaOs39IsoFile } else { '' }
            $line = "cdimage0={0}" -f $amigaOs39IsoFileFormatted
        }
        
        # patch kickstart rom file
        if ($line -match '^kickstart_rom_file=')
        {
            $kickstartFileFormatted = if ($kickstartFile) { $kickstartFile } else { '' }
            $line = "kickstart_rom_file={0}" -f $kickstartFileFormatted
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

                if (!$hardfilePath -or !(Test-Path $hardfilePath))
                {
                    Write-Warning ("Hardfile2 path '{0}' doesn't exist" -f $hardfilePath)
                }
                else
                {
                    $line = $line -replace '^(hardfile2=[^,]*,[^,:]*:)[^,]*', "`$1$hardfilePath"
                }
            }

            $fileSystemPath = $line | Select-String -Pattern ',([^,]*),uae$' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

            if ($fileSystemPath -and $fileSystemPath -ne '')
            {
                $fileSystemPath = Join-Path $uaeConfigDir -ChildPath (Split-Path $fileSystemPath -Leaf)

                if (!$fileSystemPath -or !(Test-Path $fileSystemPath))
                {
                    Write-Warning ("Hardfile2 filesystem path '{0}' doesn't exist" -f $fileSystemPath)
                }
                else
                {
                    $line = $line -replace '^(.+[^,]*,)[^,]*(,uae)$', "`$1$fileSystemPath`$2"
                }
            }
        }

        # patch uaehf to current directory
        if ($line -match '^uaehf\d+=')
        {
            $uaehfDevice = $line | Select-String -Pattern '^uaehf\d+=[^,]*,[^,]*,([^,:]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
            
            $uaehfIsDir = $false
            if ($line -match '^uaehf\d+=dir')
            {
                $uaehfIsDir = $true
                $uaehfPath = $line | Select-String -Pattern '^uaehf\d+=[^,]*,[^,]*,[^,:]*:[^,:]*:"?([^,"]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
            }
            else
            {
                $uaehfPath = $line | Select-String -Pattern '^uaehf\d+=[^,]*,[^,]*,[^,:]*:"?([^,"]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
            }
            
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
                
                if (!$uaehfPath -or !(Test-Path $uaehfPath))
                {
                    Write-Warning ("Uaehf path '{0}' doesn't exist" -f $uaehfPath)
                }
                else
                {
                    if ($uaehfIsDir)
                    {
                        $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:[^,:]*:"?)[^,"]*', "`$1$uaehfPath"
                    }
                    else
                    {
                        $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:"?)[^,"]*', "`$1$uaehfPath"
                    }
                }
            }

            $fileSystemPath = $line | Select-String -Pattern ',([^,]*),uae$' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

            if ($fileSystemPath -and $fileSystemPath -ne '')
            {
                $fileSystemPath = Join-Path $uaeConfigDir -ChildPath (Split-Path $fileSystemPath -Leaf)

                if (!$fileSystemPath -or !(Test-Path $fileSystemPath))
                {
                    Write-Warning ("Uaehf filesystem path '{0}' doesn't exist" -f $fileSystemPath)
                }
                else
                {
                    $line = $line -replace '^(.+[^,]*,)[^,]*(,uae)$', "`$1$fileSystemPath`$2"
                }
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

                if (!$filesystemPath -or !(Test-Path $filesystemPath))
                {
                    Write-Warning ("Filesystem2 path '{0}' doesn't exist" -f $filesystemPath)
                }
                else
                {
                    $line = $line -replace '^(filesystem2=[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$filesystemPath"
                }
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
function PatchFsuaeConfigFile($fsuaeConfigFile, $kickstartFile, $amigaOs39IsoFile, $amigaOsDir, $kickstartDir, $userPackagesDir)
{
    # get fs-uae config dir
    $fsuaeConfigDir = Split-Path $fsuaeConfigFile -Parent

    # read fs-uae config file and skip lines, that contains floppy_image
    $fsuaeConfigLines = @()
    $fsuaeConfigLines += Get-Content $fsuaeConfigFile | Where-Object { $_ -notmatch '^\s*$' -and $_ -notmatch '^floppy_image_\d+' }

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
            $amigaOs39IsoFileFormatted = if ($amigaOs39IsoFile) { $amigaOs39IsoFile.Replace('\', '/') } else { '' }
            $line = "cdrom_drive_0 = {0}" -f $amigaOs39IsoFileFormatted
        }
        
        # patch logs dir
        if ($line -match '^logs_dir\s*=')
        {
            $line = "logs_dir = {0}" -f $fsuaeConfigDir.Replace('\', '/')
        }

        # patch kickstart file
        if ($line -match '^kickstart_file\s*=')
        {
            $kickstartFileFormatted = if ($kickstartFile) { $kickstartFile.Replace('\', '/') } else { '' }
            $line = "kickstart_file = {0}" -f $kickstartFileFormatted
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

                if (!$harddrivePath -or !(Test-Path $harddrivePath))
                {
                    Write-Warning ("Hard drive path '{0}' doesn't exist" -f $harddrivePath)
                }
                else
                {
                    $line = $line -replace '^(hard_drive_\d+\s*=\s*).*', ("`$1{0}" -f $harddrivePath.Replace('\', '/'))
                }
            }
        }

        # patch hard drive file system path
        if ($line -match '^hard_drive_\d+_file_system\s*=')
        {
            # get file system path
            $fileSystemPath = $line | Select-String -Pattern '^hard_drive_\d+_file_system\s*=\s*(.*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

            if ($fileSystemPath)
            {
                $fileSystemPath = Join-Path $fsuaeConfigDir -ChildPath (Split-Path $fileSystemPath -Leaf)
            }

            if (!$fileSystemPath -or !(Test-Path $fileSystemPath))
            {
                Write-Warning ("Hard drive file system path '{0}' doesn't exist" -f $fileSystemPath)
            }
            else
            {
                $line = $line -replace '^(^hard_drive_\d+_file_system\s*=\s*).*', ("`$1{0}" -f $fileSystemPath.Replace('\', '/'))
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
    @{ 'Md5' = 'c1c673eba985e9ab0888c5762cfa3d8f'; 'Filename' = 'amiga-os-310-extras.adf'; 'Name' = 'Amiga OS 3.1 Extras Disk, Cloanto Amiga Forever 2016' },
    @{ 'Md5' = '6fae8b94bde75497021a044bdbf51abc'; 'Filename' = 'amiga-os-310-fonts.adf'; 'Name' = 'Amiga OS 3.1 Fonts Disk, Cloanto Amiga Forever 2016' },
    @{ 'Md5' = 'd6aa4537586bf3f2687f30f8d3099c99'; 'Filename' = 'amiga-os-310-install.adf'; 'Name' = 'Amiga OS 3.1 Install Disk, Cloanto Amiga Forever 2016' },
    @{ 'Md5' = 'b53c9ff336e168643b10c4a9cfff4276'; 'Filename' = 'amiga-os-310-locale.adf'; 'Name' = 'Amiga OS 3.1 Locale Disk, Cloanto Amiga Forever 2016' },
    @{ 'Md5' = '4fa1401aeb814d3ed138f93c54a5caef'; 'Filename' = 'amiga-os-310-storage.adf'; 'Name' = 'Amiga OS 3.1 Storage Disk, Cloanto Amiga Forever 2016' },
    @{ 'Md5' = '590c42a69675d6970df350e200fe25dc'; 'Filename' = 'amiga-os-310-workbench.adf'; 'Name' = 'Amiga OS 3.1 Workbench Disk, Cloanto Amiga Forever 2016' },

    @{ 'Md5' = 'c5be06daf40d4c3ace4eac874d9b48b1'; 'Filename' = 'amiga-os-310-install.adf'; 'Name' = 'Amiga OS 3.1 Install Disk, Cloanto Amiga Forever 7' },
    @{ 'Md5' = 'e7b3a83df665a85e7ec27306a152b171'; 'Filename' = 'amiga-os-310-workbench.adf'; 'Name' = 'Amiga OS 3.1 Workbench Disk, Cloanto Amiga Forever 7' }
)

# valid amiga os 3.1.4 adf md5 entries
$validAmigaOs314Md5Entries = @(
    @{ 'Md5' = '988ddad5106d5b846be57b711d878b4c'; 'Filename' = 'amiga-os-314-extras.adf'; 'Name' = 'Amiga OS 3.1.4 Extras Disk, Hyperion Entertainment' },
    @{ 'Md5' = '27a7af42777a43a06f8d9d8e74226e56'; 'Filename' = 'amiga-os-314-fonts.adf'; 'Name' = 'Amiga OS 3.1.4 Fonts Disk, Hyperion Entertainment' },
    @{ 'Md5' = '7e9b5ec9cf89d9aae771cd1b708792d9'; 'Filename' = 'amiga-os-314-install.adf'; 'Name' = 'Amiga OS 3.1.4 Install Disk, Hyperion Entertainment' },
    @{ 'Md5' = '2fac2ab6bdd36bd28c04297253238655'; 'Filename' = 'amiga-os-314-install.adf'; 'Name' = 'Amiga OS 3.1.4 Install Disk, Hyperion Entertainment' },
    @{ 'Md5' = '4007bfe06b5b51af981a3fa52c51f54a'; 'Filename' = 'amiga-os-314-locale.adf'; 'Name' = 'Amiga OS 3.1.4 Locale Disk, Hyperion Entertainment' },
    @{ 'Md5' = '372215cd27888d65a95db92b6513e702'; 'Filename' = 'amiga-os-314-storage.adf'; 'Name' = 'Amiga OS 3.1.4 Storage Disk, Hyperion Entertainment' },
    @{ 'Md5' = '05a7469fd903744aa5f53741765bf668'; 'Filename' = 'amiga-os-314-workbench.adf'; 'Name' = 'Amiga OS 3.1.4 Workbench Disk, Hyperion Entertainment' },
    @{ 'Md5' = '8a3824e64dbe2c8327d5995188d5fdd3'; 'Filename' = 'amiga-os-314-modules-a500.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A500 Disk, Hyperion Entertainment' },
    @{ 'Md5' = '2065c8850b5ba97099c3ff2672221e3f'; 'Filename' = 'amiga-os-314-modules-a500.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A500 Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'c5a96c56ee5a7e2ca639c755d89dda36'; 'Filename' = 'amiga-os-314-modules-a600.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A600 Disk, Hyperion Entertainment' },
    @{ 'Md5' = '4e095037af1da015c09ed26e3e107f50'; 'Filename' = 'amiga-os-314-modules-a600.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A600 Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'bc48d0bdafd123a6ed459c38c7a1c2e4'; 'Filename' = 'amiga-os-314-modules-a600.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A600 Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'b201f0b45c5748be103792e03f938027'; 'Filename' = 'amiga-os-314-modules-a2000.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A2000 Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'b8d09ea3369ac538c3920c515ba76e86'; 'Filename' = 'amiga-os-314-modules-a2000.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A2000 Disk, Hyperion Entertainment' },
    @{ 'Md5' = '2797193dc7b7daa233abe1bcfee9d5a1'; 'Filename' = 'amiga-os-314-modules-a1200.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A1200 Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'd170f8c11d1eb52f12643e0f13b44886'; 'Filename' = 'amiga-os-314-modules-a1200.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A1200 Disk, Hyperion Entertainment' },
    @{ 'Md5' = '60263124ea2c5f1831a3af639d085a28'; 'Filename' = 'amiga-os-314-modules-a3000.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A3000 Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'd068cbc850390c3e0028879cc1cae4c2'; 'Filename' = 'amiga-os-314-modules-a3000.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A3000 Disk, Hyperion Entertainment' },
    @{ 'Md5' = '7d20dc438e802e41def3694d2be59f0f'; 'Filename' = 'amiga-os-314-modules-a4000d.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A4000D Disk, Hyperion Entertainment' },
    @{ 'Md5' = '68fb2ca4b81daeaf140d35dc7a63d143'; 'Filename' = 'amiga-os-314-modules-a4000t.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A4000T Disk, Hyperion Entertainment' }
    @{ 'Md5' = 'a0ed3065558bd43e80647c1c522322a0'; 'Filename' = 'amiga-os-314-modules-a4000t.adf'; 'Name' = 'Amiga OS 3.1.4 Modules A4000T Disk, Hyperion Entertainment' }
)

# valid amiga os 3.2 adf md5 entries
$validAmigaOs32Md5Entries = @(
    @{ 'Md5' = '4f0c3383a10e62fdea5e5758a9238223'; 'Filename' = 'amiga-os-32-extras.adf'; 'Name' = 'Amiga OS 3.2 Extras Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'e03eb0505fb244aaf1c7486f6fe61ede'; 'Filename' = 'amiga-os-32-fonts.adf'; 'Name' = 'Amiga OS 3.2 Fonts Disk, Hyperion Entertainment' },
    @{ 'Md5' = '71edc1249c013d60380d3db81fd87ae7'; 'Filename' = 'amiga-os-32-install.adf'; 'Name' = 'Amiga OS 3.2 Install Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'b697a03f0620b5e06947b5e9d7b16142'; 'Filename' = 'amiga-os-32-locale.adf'; 'Name' = 'Amiga OS 3.2 Locale Disk, Hyperion Entertainment' },
    @{ 'Md5' = '3726fab6ec5cfc48f7c2368005964d90'; 'Filename' = 'amiga-os-32-storage.adf'; 'Name' = 'Amiga OS 3.2 Storage Disk, Hyperion Entertainment' },
    @{ 'Md5' = '5edf0b7a10409ef992ea351565ef8b6c'; 'Filename' = 'amiga-os-32-workbench.adf'; 'Name' = 'Amiga OS 3.2 Workbench Disk, Hyperion Entertainment' },
    @{ 'Md5' = '2236629e7c316ff907b7e0cb1ee0ad18'; 'Filename' = 'amiga-os-32-backdrops.adf'; 'Name' = 'Amiga OS 3.2 Backdrops Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'fd11e54b038d5f236248a941125065db'; 'Filename' = 'amiga-os-32-classes.adf'; 'Name' = 'Amiga OS 3.2 Classes Disk, Hyperion Entertainment' },
    @{ 'Md5' = '497d0aa96229a0e7fd2c475163d7462a'; 'Filename' = 'amiga-os-32-disk-doctor.adf'; 'Name' = 'Amiga OS 3.2 Disk Doctor Disk, Hyperion Entertainment' },
    @{ 'Md5' = '26ef4d09cf71b7fdbd9cc68f333b7373'; 'Filename' = 'amiga-os-32-glow-icons.adf'; 'Name' = 'Amiga OS 3.2 Glow Icons Disk, Hyperion Entertainment' },
    @{ 'Md5' = '3d36568bce19234b84fe88aa9629f5bf'; 'Filename' = 'amiga-os-32-locale-de.adf'; 'Name' = 'Amiga OS 3.2 Locale DE Disk, Hyperion Entertainment' },
    @{ 'Md5' = '3a80e4f6b0d2d95f727dc45f99068ad8'; 'Filename' = 'amiga-os-32-locale-dk.adf'; 'Name' = 'Amiga OS 3.2 Locale DK Disk, Hyperion Entertainment' },
    @{ 'Md5' = '7170c0bc81b7daeee39552279dada58c'; 'Filename' = 'amiga-os-32-locale-en.adf'; 'Name' = 'Amiga OS 3.2 Locale EN Disk, Hyperion Entertainment' },
    @{ 'Md5' = '5e2eb9acef8e7b062d103db3fd270a27'; 'Filename' = 'amiga-os-32-locale-es.adf'; 'Name' = 'Amiga OS 3.2 Locale ES Disk, Hyperion Entertainment' },
    @{ 'Md5' = '9f65d321d92d72e17d1f744f47d16323'; 'Filename' = 'amiga-os-32-locale-fr.adf'; 'Name' = 'Amiga OS 3.2 Locale FR Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'f93f2cd799ad1356adf4db01e20218f1'; 'Filename' = 'amiga-os-32-locale-gr.adf'; 'Name' = 'Amiga OS 3.2 Locale GR Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'ad728c377ce3d7f4bd6adba8419a81ae'; 'Filename' = 'amiga-os-32-locale-it.adf'; 'Name' = 'Amiga OS 3.2 Locale IT Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'e7b7b5a6583fca0d302201a1cb0b2829'; 'Filename' = 'amiga-os-32-locale-nl.adf'; 'Name' = 'Amiga OS 3.2 Locale NL Disk, Hyperion Entertainment' },
    @{ 'Md5' = '1a9b83a7385c1aab8094fc1d72123437'; 'Filename' = 'amiga-os-32-locale-no.adf'; 'Name' = 'Amiga OS 3.2 Locale NO Disk, Hyperion Entertainment' },
    @{ 'Md5' = '1aaa138753cec33a55f48d869780b7c8'; 'Filename' = 'amiga-os-32-locale-pl.adf'; 'Name' = 'Amiga OS 3.2 Locale PL Disk, Hyperion Entertainment' },
    @{ 'Md5' = '425bbeb03c74fb275d643644bdd1af9a'; 'Filename' = 'amiga-os-32-locale-pt.adf'; 'Name' = 'Amiga OS 3.2 Locale PT Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'c45409fca931fc1ce76f6713f27ccd00'; 'Filename' = 'amiga-os-32-locale-ru.adf'; 'Name' = 'Amiga OS 3.2 Locale RU Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'a588dbc1ee7bf43e0e79694e10e48669'; 'Filename' = 'amiga-os-32-locale-se.adf'; 'Name' = 'Amiga OS 3.2 Locale SE Disk, Hyperion Entertainment' },
    @{ 'Md5' = '6f9a623611fd19e084f7be2106ecfd99'; 'Filename' = 'amiga-os-32-locale-tr.adf'; 'Name' = 'Amiga OS 3.2 Locale TR Disk, Hyperion Entertainment' },
    @{ 'Md5' = '8d88812406cbf373cdb38148096972b9'; 'Filename' = 'amiga-os-32-locale-uk.adf'; 'Name' = 'Amiga OS 3.2 Locale UK Disk, Hyperion Entertainment' },
    @{ 'Md5' = '66c46918b7005167f1b65e444d0b95f7'; 'Filename' = 'amiga-os-32-mmulibs.adf'; 'Name' = 'Amiga OS 3.2 MMULibs Disk, Hyperion Entertainment' },
    @{ 'Md5' = '2d46a2856152256771883f212a4e462d'; 'Filename' = 'amiga-os-32-modules-a1200.adf'; 'Name' = 'Amiga OS 3.2 Modules A1200 Disk, Hyperion Entertainment' },
    @{ 'Md5' = '9b18dea310bf073ef9cae2a120254d92'; 'Filename' = 'amiga-os-32-modules-a2000.adf'; 'Name' = 'Amiga OS 3.2 Modules A2000 Disk, Hyperion Entertainment' },
    @{ 'Md5' = '99fdc21e434c2b2a988ba96b69d46389'; 'Filename' = 'amiga-os-32-modules-a3000.adf'; 'Name' = 'Amiga OS 3.2 Modules A3000 Disk, Hyperion Entertainment' },
    @{ 'Md5' = '729ddf87056936d77ee8287f9ad090a7'; 'Filename' = 'amiga-os-32-modules-a4000d.adf'; 'Name' = 'Amiga OS 3.2 Modules A4000D Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'f8eddbca10560582b99a2f4555ad0620'; 'Filename' = 'amiga-os-32-modules-a4000t.adf'; 'Name' = 'Amiga OS 3.2 Modules A4000T Disk, Hyperion Entertainment' },
    @{ 'Md5' = '2af6b84449996440211e9547660b10b6'; 'Filename' = 'amiga-os-32-modules-a500.adf'; 'Name' = 'Amiga OS 3.2 Modules A500 Disk, Hyperion Entertainment' },
    @{ 'Md5' = 'c6474df1d52300a4993f13a394701697'; 'Filename' = 'amiga-os-32-modules-a600.adf'; 'Name' = 'Amiga OS 3.2 Modules A600 Disk, Hyperion Entertainment' },
    @{ 'Md5' = '00b2c4d420c933894151c43dc3a24155'; 'Filename' = 'amiga-os-32-modules-cd32.adf'; 'Name' = 'Amiga OS 3.2 Modules CD32 Disk, Hyperion Entertainment' }
)

# valid kickstart rom md5 entries
$validKickstartMd5Entries = @(
    @{ 'Md5' = 'cad62a102848e13bf04d8a3b0f8be6ab'; 'Filename' = 'kick.a1200.47.96'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.2 47.96 A1200 Rom, Hyperion Entertainment'; 'Model' = 'A1200'; 'ConfigSupported' = $true },
    @{ 'Md5' = '1d9b6068abff5a44b4b2f1d5d3516dd9'; 'Filename' = 'kick.a500.47.96'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.2 47.96 A500 Rom, Hyperion Entertainment'; 'Model' = 'A500'; 'ConfigSupported' = $true },

    @{ 'Md5' = '6de08cd5c5efd926d0a7643e8fb776fe'; 'Filename' = 'kick.a1200.46.143'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1.4 46.143 A1200 Rom, Hyperion Entertainment'; 'Model' = 'A1200'; 'ConfigSupported' = $true },
    @{ 'Md5' = '79bfe8876cd5abe397c50f60ea4306b9'; 'Filename' = 'kick.a1200.46.143'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1.4 46.143 A1200 Rom, Hyperion Entertainment'; 'Model' = 'A1200'; 'ConfigSupported' = $true },
    
    @{ 'Md5' = '7fe1eb0ba2b767659bf547bfb40d67c4'; 'Filename' = 'kick.a500.46.143'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1.4 46.143 A500-A600-A2000 Rom, Hyperion Entertainment'; 'Model' = 'A500'; 'ConfigSupported' = $true },
    @{ 'Md5' = '61c5b9931555b8937803505db868d5a8'; 'Filename' = 'kick.a500.46.143'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1.4 46.143 A500-A600-A2000 Rom, Hyperion Entertainment'; 'Model' = 'A500'; 'ConfigSupported' = $true },

    @{ 'Md5' = '151cce9d7aa9a36a835ec2f78853125b'; 'Filename' = 'kick40068.A4000'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1 40.068 A4000 Rom, Cloanto Amiga Forever 8'; 'Model' = 'A4000'; 'ConfigSupported' = $false },
    @{ 'Md5' = '43efffafb382528355bb4cdde9fa9ce7'; 'Filename' = 'kick40068.A1200'; 'Encrypted '= $true; 'Name' = 'Kickstart 3.1 40.068 A1200 Rom, Cloanto Amiga Forever 8'; 'Model' = 'A1200'; 'ConfigSupported' = $true },
    @{ 'Md5' = '85a45066a0aebf9ec5870591b6ddcc52'; 'Filename' = 'kick40063.A600'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1 40.063 A500-A600-A2000 Rom, Cloanto Amiga Forever 8'; 'Model' = 'A500'; 'ConfigSupported' = $true },
    @{ 'Md5' = '189fd22ec463a9375f2ea63045ed6315'; 'Filename' = 'kick34005.A500'; 'Encrypted' = $true; 'Name' = 'Kickstart 1.3 34.5 A500 Rom, Cloanto Amiga Forever 8'; 'Model' = 'A500'; 'ConfigSupported' = $false },
    @{ 'Md5' = 'd59262012424ee5ddc5aadab9cb57cad'; 'Filename' = 'kick33180.A500'; 'Encrypted' = $true; 'Name' = 'Kickstart 1.2 33.180 A500 Rom, Cloanto Amiga Forever 8'; 'Model' = 'A500'; 'ConfigSupported' = $false },

    @{ 'Md5' = '8b54c2c5786e9d856ce820476505367d'; 'Filename' = 'kick40068.A4000'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1 40.068 A4000 Rom, Cloanto Amiga Forever 7/2016'; 'Model' = 'A4000'; 'ConfigSupported' = $false },
    @{ 'Md5' = 'dc3f5e4698936da34186d596c53681ab'; 'Filename' = 'kick40068.A1200'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1 40.068 A1200 Rom, Cloanto Amiga Forever 7/2016'; 'Model' = 'A1200'; 'ConfigSupported' = $true },
    @{ 'Md5' = 'c3e114cd3b513dc0377a4f5d149e2dd9'; 'Filename' = 'kick40063.A600'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1 40.063 A500-A600-A2000 Rom, Cloanto Amiga Forever 7/2016'; 'Model' = 'A500'; 'ConfigSupported' = $true },
    @{ 'Md5' = '89160c06ef4f17094382fc09841557a6'; 'Filename' = 'kick34005.A500'; 'Encrypted' = $true; 'Name' = 'Kickstart 1.3 34.5 A500 Rom, Cloanto Amiga Forever 7/2016'; 'Model' = 'A500'; 'ConfigSupported' = $false },
    @{ 'Md5' = 'c56ca2a3c644d53e780a7e4dbdc6b699'; 'Filename' = 'kick33180.A500'; 'Encrypted' = $true; 'Name' = 'Kickstart 1.2 33.180 A500 Rom, Cloanto Amiga Forever 7/2016'; 'Model' = 'A500'; 'ConfigSupported' = $false },

    @{ 'Md5' = '9bdedde6a4f33555b4a270c8ca53297d'; 'Filename' = 'kick40068.A4000'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1 40.068 A4000 Rom, Dump of original Amiga Kickstart'; 'Model' = 'A4000'; 'ConfigSupported' = $false },
    @{ 'Md5' = '646773759326fbac3b2311fd8c8793ee'; 'Filename' = 'kick40068.A1200'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1 40.068 A1200 Rom, Dump of original Amiga Kickstart'; 'Model' = 'A1200'; 'ConfigSupported' = $true },
    @{ 'Md5' = 'e40a5dfb3d017ba8779faba30cbd1c8e'; 'Filename' = 'kick40063.A600'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1 40.063 A500-A600-A2000 Rom, Dump of original Amiga Kickstart'; 'Model' = 'A500'; 'ConfigSupported' = $true },
    @{ 'Md5' = '82a21c1890cae844b3df741f2762d48d'; 'Filename' = 'kick34005.A500'; 'Encrypted' = $false; 'Name' = 'Kickstart 1.3 34.5 A500 Rom, Dump of original Amiga Kickstart'; 'Model' = 'A500'; 'ConfigSupported' = $false },
    @{ 'Md5' = '85ad74194e87c08904327de1a9443b7a'; 'Filename' = 'kick33180.A500'; 'Encrypted' = $false; 'Name' = 'Kickstart 1.2 33.180 A500 Rom, Dump of original Amiga Kickstart'; 'Model' = 'A500'; 'ConfigSupported' = $false }
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
$validAmigaOs31Md5Entries | ForEach-Object { $_.Priority = $validAmigaOs31Md5Index.Count + 1; $validAmigaOs31Md5Index[$_['Md5'].ToLower()] = $_ }

# index valid amiga os 3.2 md5 entries
$validAmigaOs32Md5Index = @{}
$validAmigaOs32Md5Entries | ForEach-Object { $_.Priority = $validAmigaOs32Md5Index.Count + 1; $validAmigaOs32Md5Index[$_['Md5'].ToLower()] = $_ }

# index valid amiga os 3.1.4 md5 entries
$validAmigaOs314Md5Index = @{}
$validAmigaOs314Md5Entries | ForEach-Object { $_.Priority = $validAmigaOs314Md5Index.Count + 1; $validAmigaOs314Md5Index[$_['Md5'].ToLower()] = $_ }

# index valid amiga os 3.9 md5 entries
$validAmigaOs39Md5Index = @{}
$validAmigaOs39FilenameIndex = @{}
$validAmigaOs39Md5Entries | ForEach-Object { $_.Priority = $validAmigaOs39Md5Index.Count + 1; $validAmigaOs39Md5Index[$_['Md5'].ToLower()] = $_; $validAmigaOs39FilenameIndex[$_['Filename'].ToLower()] = $_; }

# index valid kickstart rom md5 entries
$validKickstartMd5Index = @{}
$validKickstartMd5Entries | ForEach-Object { $_.Priority = $validKickstartMd5Index.Count + 1; $validKickstartMd5Index[$_['Md5'].ToLower()] = $_ }

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
Write-Output "Date: 2021-08-06"
Write-Output ""
Write-Output ("Install dir '{0}'" -f $installDir)

if (!(Test-Path $installDir))
{
    throw ("Error: Install dir '{0}' doesn't exist" -f $installDir)
}

# set uae config directory to detected winuae config directory, if uae config directory is not defined
if (!$uaeConfigDir)
{
    $uaeConfigDir = GetWinuaeConfigDir
}

# set fs-uae directory to detected fs-uae directory, if fs-uae directory is not defined
if (!$fsuaeDir)
{
    $fsuaeDir = GetFsuaeDir
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
    Write-Output 'One or more configuration files contain self install dirs'
    $selfInstall = $true
}


# set default amiga os dir, if it's not defined
if (!$amigaOsDir)
{
    $amigaOsDir = Join-Path $installDir -ChildPath "amigaos"

    # unset default amiga os dir, if it doesn't exist
    if (!(Test-Path $amigaOsDir))
    {
        $amigaOsDir = $null
    }
}

# set default kickstart dir, if it's not defined
if (!$kickstartDir)
{
    $kickstartDir = Join-Path $installDir -ChildPath "kickstart"

    # unset default kickstart dir, if it doesn't exist
    if (!(Test-Path $kickstartDir))
    {
        $kickstartDir = $null
    }
}

# set default user packages dir, if it's not defined
if (!$userPackagesDir)
{
    $userPackagesDir = Join-Path $installDir -ChildPath "userpackages"

    # unset default user packages dir, if it doesn't exist
    if (!(Test-Path $userPackagesDir))
    {
        $userPackagesDir = $null
    }
}


# autodetect amiga forever data dir, if it's not defined
if (!$amigaForeverDataDir)
{
    # find amiga forever data dir from media
    $amigaForeverDataDir = FindAmigaForeverDataDirFromMediaWindows

    # get amiga forever data dir from environment variable, if no amiga forever data dir was detected from media
    if (!$amigaForeverDataDir -and $null -ne ${Env:AMIGAFOREVERDATA})
    {
        $amigaForeverDataDir = ${Env:AMIGAFOREVERDATA}
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
if ($amigaForeverDataDir -and (Test-Path -Path $amigaForeverDataDir))
{
    # write cloanto amiga forever
    Write-Output ''
    Write-Output 'Cloanto Amiga Forever'
    Write-Output '---------------------'

    $sharedDir = Join-Path $amigaForeverDataDir -ChildPath 'Shared'
    $sharedAdfDir = Join-Path $sharedDir -ChildPath "adf"
    $sharedRomDir = Join-Path $sharedDir -ChildPath "rom"

    if ($selfInstall)
    {
        Write-Output 'Install Amiga OS adf and Kickstart rom files from Amiga Forever data dir...'

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
    }
    else
    {
        Write-Output 'Using Kickstart rom files from Amiga Forever data dir...'

        if (!$kickstartDir -and (Test-Path -path $sharedRomDir))
        {
            $kickstartDir = $sharedRomDir
            Write-Output ('- Kickstart dir ''{0}''' -f $kickstartDir)
        }
        else
        {
            Write-Output '- No Amiga Forever data shared rom dir detected or Kickstart dir is already set'
        }
    }
    Write-Output 'Done'
}


# write image directories
Write-Output ''
Write-Output 'Image directories'
Write-Output '-----------------'

# write detecting amiga os
Write-Output 'Detecting Amiga OS...'
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
    $filename = $validAmigaOs39FilenameIndex[$os39Filename.ToLower()]['Filename'].ToLower()
    $detectedOs39FilenamesIndex[$filename] = $md5File
    $detectedOs39FilenamesIndex[$filename].Priority = $validAmigaOs39FilenameIndex[$os39Filename.ToLower()]['Priority']
}
foreach ($md5File in $amigaOsMd5Files)
{
    if (!$validAmigaOs39Md5Index.ContainsKey($md5File.Md5))
    {
        continue
    }
    $filename = $validAmigaOs39Md5Index[$md5File.Md5]['Filename'].ToLower()
    $detectedOs39FilenamesIndex[$filename] = $md5File
    $detectedOs39FilenamesIndex[$filename].Priority = $validAmigaOs39Md5Index[$md5File.Md5]['Priority']
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

# detected amiga os 3.2 md5 index and filenames from amiga os dir that matches valid amiga os 3.2 md5
$detectedAmigaOs32Md5Index = @{}
$detectedAmigaOs32Filenames = New-Object System.Collections.Generic.List[System.Object]
foreach ($md5File in $amigaOsMd5Files)
{
    if (!$validAmigaOs32Md5Index.ContainsKey($md5File.Md5))
    {
        continue
    }
    $detectedAmigaOs32Md5Index[$validAmigaOs32Md5Index[$md5File.Md5]['Filename'].ToLower()] = `
        $validAmigaOs32Md5Index[$md5File.Md5]
    $detectedAmigaOs32Filenames.Add((Split-Path $md5File.File -Leaf))
}
$detectedAmigaOs32Filenames = $detectedAmigaOs32Filenames | `
    Sort-Object | `
    Get-Unique

# print detected amiga os 3.2 adf files
if ($detectedAmigaOs32Filenames.Count -gt 0)
{
    Write-Output ('- {0} Amiga OS 3.2 adf files detected ''{1}''' -f $detectedAmigaOs32Filenames.Count, ($detectedAmigaOs32Filenames -join ', '))
}
else
{
    Write-Output '- No Amiga OS 3.2 adf files detected'
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

# print detected amiga os 3.1.4 adf files
if ($detectedAmigaOs314Filenames.Count -gt 0)
{
    Write-Output ('- {0} Amiga OS 3.1.4 adf files detected ''{1}''' -f $detectedAmigaOs314Filenames.Count, ($detectedAmigaOs314Filenames -join ', '))
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

# print detected amiga os 3.1 adf files
if ($detectedAmigaOs31Filenames.Count -gt 0)
{
    Write-Output ('- {0} Amiga OS 3.1 adf files detected ''{1}''' -f $detectedAmigaOs31Filenames.Count, ($detectedAmigaOs31Filenames -join ', '))
}
else
{
    Write-Output '- No Amiga OS 3.1 adf files detected'
}


# write detecting kickstart roms
Write-Output 'Detecting Kickstart roms...'
Write-Output ('- Kickstart dir ''{0}''' -f $kickstartDir)

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
    $filename = $validKickstartMd5Index[$md5File.Md5]['Filename'].ToLower()
    $detectedKickstartMd5Index[$filename] = $validKickstartMd5Index[$md5File.Md5]
    $detectedKickstartMd5Index[$filename].File = $md5File.File
    $detectedKickstartFilenames.Add($detectedKickstartFilename)
}
$detectedKickstartFilenames = $detectedKickstartFilenames | `
    Sort-Object | `
    Get-Unique

# write detected kickstart rom files
if ($detectedKickstartFilenames.Count -gt 0)
{
    Write-Output ('- {0} Kickstart rom files detected ''{1}''' -f $detectedKickstartFilenames.Count, ($detectedKickstartFilenames -join ', '))
}
else
{
    Write-Output '- No Kickstart rom files detected'
}


# write detecting user packages
Write-Output 'Detecting User Packages...'
Write-Output ('- User Packages dir ''{0}''' -f $userPackagesDir)

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


# set amiga os 3.9 iso file, if uae or fs-uae config files are present
$amigaOs39IsoFile = $null
if ($uaeConfigFiles.Count -gt 0 -or $fsuaeConfigFiles.Count -gt 0)
{
    # find first amiga os 3.9 md5 files matching valid amiga os 3.9 md5 hash or has filename 'amigaos3.9.iso'
    $amigaOs39IsoEntry = $detectedOs39FilenamesIndex.Values | `
        Where-Object { ($validAmigaOs39Md5Index.ContainsKey($_.Md5.ToLower()) -and $validAmigaOs39Md5Index[$_.Md5.ToLower()].Filename -match 'amigaos3\.?9\.iso') -or ($_.File -match '\\?amigaos3\.?9\.iso$') } | `
        Sort-Object @{expression={$_.Priority}} | `
        Select-Object -First 1

    # set amiga os 3.9 iso file, if amiga os39 iso md5 file is defined
    if ($amigaOs39IsoEntry)
    {
        $amigaOs39IsoFile = $amigaOs39IsoEntry.File
    }
}


# patch and install uae configuration files, if they are present
if ($uaeConfigFiles.Count -gt 0)
{
    # write uae configuration
    Write-Output ''
    Write-Output 'UAE configuration'
    Write-Output '-----------------'
    Write-Output 'Patching and installing UAE configuration files...'

    # write uae config directory, if not patch only and uae config directory exists
    if (!$patchOnly -and $uaeConfigDir)
    {
        Write-Output ('- UAE config dir ''{0}''' -f $uaeConfigDir)
    }

    if ($amigaOs39IsoFile)
    {
        Write-Output ('- Using Amiga OS 3.9 iso file ''{0}''' -f $amigaOs39IsoFile)
    }
    else
    {
        Write-Output '- No Amiga OS 3.9 iso file detected'
    }

    Write-Output ('- {0} UAE configuration files' -f $uaeConfigFiles.Count)
    foreach($uaeConfigFile in $uaeConfigFiles)
    {
        $kickstartFile = ''

        # read model from uae config file
        $model = ReadModelFromConfigFile $uaeConfigFile.FullName

        # get kickstart file for model, if model is defined
        if ($model)
        {
            # get kickstart entry for model
            $kickstartEntry = $validKickstartMd5Index.Values | `
                Where-Object { $_.Model -match $model -and $_.ConfigSupported -and $_.File } | `
                Sort-Object @{expression={$_.Priority}} | `
                Select-Object -First 1

            # set kickstart file
            $kickstartFile = if ($kickstartEntry) { $kickstartEntry.File } else { '' }
        }
        else
        {
            $model = 'unknown'
        }

        if ($kickstartFile)
        {
            Write-Output ('- ''{0}''. Using Kickstart file ''{1}'' for {2} model' -f $uaeConfigFile.FullName, $kickstartFile, $model)
        }
        else
        {
            Write-Output ('- ''{0}''. No Kickstart file for {1} model!' -f $uaeConfigFile.FullName, $model)
        }

        # patch uae config file
        PatchUaeConfigFile $uaeConfigFile.FullName $kickstartFile $amigaOs39IsoFile $amigaOsDir $kickstartDir $userPackagesDir

        # install uae config file in uae config directory, if not patch only and uae config directory is defined
        if (!$patchOnly -and $uaeConfigDir)
        {
            Copy-Item $uaeConfigFile.FullName -Destination $uaeConfigDir -Force
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
    Write-Output 'Patching and installing FS-UAE configuration files...'

    # fs-uae config dir
    $fsuaeConfigDir = $null

    # set and write fs-uae config directory, if not patch only and fs-uae dir exists
    if (!$patchOnly -and $fsuaeDir)
    {
        # fs-uae configuration directory
        $fsuaeConfigDir = Join-Path $fsuaeDir -ChildPath 'Configurations'

        Write-Output ('- FS-UAE config dir ''{0}''' -f $fsuaeConfigDir)

        # create fs-uae configuration directory, if it doesn't exist
        if (!(Test-Path $fsuaeConfigDir))
        {
            mkdir -Path $fsuaeConfigDir | Out-Null
        }
    }
    
    if ($amigaOs39IsoFile)
    {
        Write-Output ('- Using Amiga OS 3.9 iso file ''{0}''' -f $amigaOs39IsoFile)
    }
    else
    {
        Write-Output '- No Amiga OS 3.9 iso file detected'
    }

    Write-Output ('- {0} FS-UAE configuration files' -f $fsuaeConfigFiles.Count)
    foreach($fsuaeConfigFile in $fsuaeConfigFiles)
    {
        $kickstartFile = ''

        # read model from fs-uae config file
        $model = ReadModelFromConfigFile $fsuaeConfigFile.FullName

        # get kickstart file for model, if model is defined
        if ($model)
        {
            # get kickstart entry for model
            $kickstartEntry = $validKickstartMd5Index.Values | `
                Where-Object { $_.Model -match $model -and $_.ConfigSupported -and $_.File } | `
                Sort-Object @{expression={$_.Priority}} | `
                Select-Object -First 1

            # set kickstart file
            $kickstartFile = if ($kickstartEntry) { $kickstartEntry.File } else { '' }
        }
        else
        {
            $model = 'unknown'
        }

        if ($kickstartFile)
        {
            Write-Output ('- ''{0}''. Using Kickstart file ''{1}'' for {2} model' -f $fsuaeConfigFile.FullName, $kickstartFile, $model)
        }
        else
        {
            Write-Output ('- ''{0}''. No Kickstart file for {1} model!' -f $fsuaeConfigFile.FullName, $model)
        }

        # patch fs-uae config file
        PatchFsuaeConfigFile $fsuaeConfigFile.FullName $kickstartFile $amigaOs39IsoFile $amigaOsDir $kickstartDir $userPackagesDir

        # install fs-uae config file in fs-uae config directory, if not patch only and fs-uae config directory is defined
        if (!$patchOnly -and $fsuaeConfigDir)
        {
            Copy-Item $fsuaeConfigFile.FullName -Destination $fsuaeConfigDir -Force
        }
    }

    # install fs-uae hstwb installer theme
    $hstwbInstallerFsUaeThemeDir = Join-Path $installDir -ChildPath 'fs-uae\themes\hstwb-installer'
    if (!$patchOnly -and $fsuaeDir -and (Test-Path $hstwbInstallerFsUaeThemeDir))
    {
        $hstwbInstallerFsUaeThemeDirInstalled = Join-Path $fsuaeDir -ChildPath 'themes\hstwb-installer'
        Copy-Item $hstwbInstallerFsUaeThemeDir -Destination (Split-Path $hstwbInstallerFsUaeThemeDirInstalled -Parent) -Recurse -Force
        Write-Output '- HstWB Installer FS-UAE theme installed'
    }

    Write-Output "Done"
}