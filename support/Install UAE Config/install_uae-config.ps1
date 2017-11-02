# Install UAE config
# ------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-11-02
#
# A powershell script to install UAE config for HstWB images by patching hard drive
# directories to current directory and installing Workbench 3.1 adf and
# Kickstart rom files from Cloanto Amiga Forever, if installed.


Param(
	[Parameter(Mandatory=$false)]
	[switch]$patchOnly
)


# calculate md5 hash from file
function CalculateMd5FromFile($file)
{
	$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	return [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($file))).ToLower().Replace('-', '')
}


# find a1200 kickstart 3.1 rom file
function FindA1200Kickstart31RomFile($kickstartDir)
{
    $kickstartFiles = @()
    $kickstartFiles += Get-ChildItem $kickstartDir
    
    foreach($kickstartFile in $kickstartFiles)
    {
        $md5Hash = CalculateMd5FromFile $kickstartFile.FullName
        
        # return kickstart file, if md5 matches Cloanto Amiga Forever 2016 Kickstart 3.1 (40.068) (A1200) rom
        if ($md5Hash -eq 'dc3f5e4698936da34186d596c53681ab')
        {
            return $kickstartFile.FullName
        }

        # return kickstart file, if md5 matches Custom Kickstart 3.1 (40.068) (A1200) rom
        if ($md5Hash -eq '646773759326fbac3b2311fd8c8793ee')
        {
            return $kickstartFile.FullName
        }
    }

    return $null
}


# is valid workbench adf file
function IsValidWorkbenchAdfFile($workbenchAdfFile)
{
    $md5Hash = CalculateMd5FromFile $workbenchAdfFile
    
    # return true, if md5 matches Cloanto Amiga Forever 2016 Workbench 3.1 Extras Disk
    if ($md5Hash -eq 'c1c673eba985e9ab0888c5762cfa3d8f')
    {
        return $true
    }

    # return true, if md5 matches Cloanto Amiga Forever 2016 Workbench 3.1 Fonts Disk
    if ($md5Hash -eq '6fae8b94bde75497021a044bdbf51abc')
    {
        return $true
    }

    # return true, if md5 matches Cloanto Amiga Forever 2016 Workbench 3.1 Install Disk
    if ($md5Hash -eq 'd6aa4537586bf3f2687f30f8d3099c99')
    {
        return $true
    }

    # return true, if md5 matches Cloanto Amiga Forever 2016 Workbench 3.1 Locale Disk
    if ($md5Hash -eq 'b53c9ff336e168643b10c4a9cfff4276')
    {
        return $true
    }

    # return true, if md5 matches Cloanto Amiga Forever 2016 Workbench 3.1 Storage Disk
    if ($md5Hash -eq '4fa1401aeb814d3ed138f93c54a5caef')
    {
        return $true
    }

    # return true, if md5 matches Cloanto Amiga Forever 2016 Workbench 3.1 Workbench Disk
    if ($md5Hash -eq '590c42a69675d6970df350e200fe25dc')
    {
        return $true
    }

    return $false
}


# install workbench adf files
function InstallWorkbenchAdfFiles($workbenchDir, $outputWorkbenchDir)
{
    $workbenchFiles = @()
    $workbenchFiles += Get-ChildItem $workbenchDir
    
    foreach($workbenchFile in $workbenchFiles)
    {
        if (IsValidWorkbenchAdfFile $workbenchFile.FullName)
        {
            Copy-Item -Path $workbenchFile.FullName -Destination $outputWorkbenchDir
        }
    }
}


# is valid kickstart rom file
function IsValidKickstartRomFile($kickstartRomFile)
{
    # return true, if filename matches Cloanto Amiga Forever rom.key
    if ($kickstartRomFile -match '[\\/]rom.key$')
    {
        return $true
    }

    $md5Hash = CalculateMd5FromFile $kickstartRomFile
    
    # return true, if md5 matches Cloanto Amiga Forever 2016 Kickstart 1.2 (33.180) (A500) Rom
    if ($md5Hash -eq 'c56ca2a3c644d53e780a7e4dbdc6b699')
    {
        return $true
    }

    # return true, if md5 matches Cloanto Amiga Forever 2016 Kickstart 1.3 (34.5) (A500) Rom
    if ($md5Hash -eq '89160c06ef4f17094382fc09841557a6')
    {
        return $true
    }

    # return true, if md5 matches Cloanto Amiga Forever 2016 Kickstart 3.1 (40.063) (A600) Rom
    if ($md5Hash -eq 'c3e114cd3b513dc0377a4f5d149e2dd9')
    {
        return $true
    }

    # return true, if md5 matches Cloanto Amiga Forever 2016 Kickstart 3.1 (40.068) (A1200) rom
    if ($md5Hash -eq 'dc3f5e4698936da34186d596c53681ab')
    {
        return $true
    }

    # return true, if md5 matches Cloanto Amiga Forever 2016 Kickstart 3.1 (40.068) (A4000) Rom
    if ($md5Hash -eq '8b54c2c5786e9d856ce820476505367d')
    {
        return $true
    }

    return $false
}


# install kickstart rom files
function InstallKickstartRomFiles($kickstartDir, $outputKickstartDir)
{
    $kickstartFiles = @()
    $kickstartFiles += Get-ChildItem $kickstartDir
    
    foreach($kickstartFile in $kickstartFiles)
    {
        if (IsValidKickstartRomFile $kickstartFile.FullName)
        {
            Copy-Item -Path $kickstartFile.FullName -Destination $outputKickstartDir
        }
    }
}


# patch winuae config file
function PatchWinuaeConfigFile($winuaeConfigFile, $workbenchDir, $kickstartDir, $os39Dir, $userPackagesDir)
{
    # find A1200 kickstart 3.1 rom file
    $a1200Kickstart31RomFile = FindA1200Kickstart31RomFile $kickstartDir
    
    # read winuae config file
    $winuaeConfigLines = @()
    $winuaeConfigLines += Get-Content $winuaeConfigFile

    # patch winuae config lines
    for ($i = 0; $i -lt $winuaeConfigLines.Count; $i++)
    {
        $line = $winuaeConfigLines[$i]

        # update kickstart rom file
        if ($line -match '^kickstart_rom_file=')
        {
            if ($a1200Kickstart31RomFile)
            {
                $line = "kickstart_rom_file={0}" -f $a1200Kickstart31RomFile
            }
            else
            {
                $line = 'kickstart_rom_file='
            }
        }

        # update self install directories
        if ($line -match '^(filesystem2|uaehf\d+)=' -and $line -match '(WORKBENCHDIR|KICKSTARTDIR|OS39DIR|USERPACKAGESDIR):')
        {
            # update workbenchdir filesystem2
            if ($line -match '^filesystem2=' -and $line -match 'WORKBENCHDIR:')
            {
                $line = $line -replace '^(filesystem2=[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$workbenchDir"
            }

            # update workbenchdir uaehf
            if ($line -match '^uaehf\d+=' -and $line -match 'WORKBENCHDIR:')
            {
                $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$workbenchDir"
            }
            
            # update kickstartdir filesystem2
            if ($line -match '^filesystem2=' -and $line -match 'KICKSTARTDIR:')
            {
                $line = $line -replace '^(filesystem2=[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$kickstartDir"
            }

            # update kickstartdir uaehf
            if ($line -match '^uaehf\d+=' -and $line -match 'KICKSTARTDIR:')
            {
                $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$kickstartDir"
            }
            
            # update os39dir filesystem2
            if ($line -match '^filesystem2=' -and $line -match 'OS39DIR:')
            {
                $line = $line -replace '^(filesystem2=[^,]*,[^:]*:[^:]*:)[^,]*', "`$1$os39Dir"
            }

            # update os39dir uaehf
            if ($line -match '^uaehf\d+=' -and $line -match 'OS39DIR:')
            {
                $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$os39Dir"
            }
            
            # update userpackagesdir filesystem2
            if ($line -match '^filesystem2=' -and $line -match 'USERPACKAGESDIR:')
            {
                $line = $line -replace '^(filesystem2=[^,]*,[^:]*:[^:]*:)[^,]*', "`$1$userPackagesDir"
            }

            # update userpackagesdir uaehf
            if ($line -match '^uaehf\d+=' -and $line -match 'USERPACKAGESDIR:')
            {
                $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$userPackagesDir"
            }
        }
        else
        {
            # update hardfile2 to current directory
            if ($line -match '^hardfile2=')
            {
                $hardfileFile = $line | Select-String -Pattern '^hardfile2=[^,]*,[^:]*:([^,]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

                if ($hardfileFile)
                {
                    $hardfileFile = Join-Path $currentDir -ChildPath (Split-Path $hardfileFile -Leaf)
                    $line = $line -replace '^(hardfile2=[^,]*,[^,:]*:)[^,]*', "`$1$hardfileFile"
                }
            }

            # update uaehf to current directory
            if ($line -match '^uaehf\d+=hdf')
            {
                $uaehfFile = $line | Select-String -Pattern '^uaehf\d+=[^,]*,[^,]*,[^,:]*:"?([^,"]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
                
                if ($uaehfFile)
                {
                    $uaehfFile = (Join-Path $currentDir -ChildPath (Split-Path ($uaehfFile.Replace('\\', '\')) -Leaf)).Replace('\', '\\')
                    $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:"?)[^,"]*', "`$1$uaehfFile"
                }
            }
            
            # update filesystem2 to current directory
            if ($line -match '^filesystem2=')
            {
                $filesystemDir = $line | Select-String -Pattern '^filesystem2=[^,]*,[^,:]*:[^:]*:([^,]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

                if ($filesystemDir)
                {
                    $filesystemDir = Join-Path $currentDir -Path (Split-Path $filesystemDir -Leaf)
                    $line = $line -replace '^(filesystem2=[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$filesystemDir"
                }
            }
        }

        
        # update line, if it's changed
        if ($line -ne $winuaeConfigLines[$i])
        {
            $winuaeConfigLines[$i] = $line
        }
    }

    # write winuae config file without byte order mark
    $utf8Encoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines($winuaeConfigFile, $winuaeConfigLines, $utf8Encoding)
}


# patch fs-uae config file
function PatchFsuaeConfigFile($fsuaeConfigFile, $workbenchDir, $kickstartDir, $os39Dir, $userPackagesDir)
{
    # find A1200 kickstart 3.1 rom file in kickstart dir
    $a1200Kickstart31RomFile = FindA1200Kickstart31RomFile $kickstartDir
    
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

        # patch logs dir
        if ($line -match '^logs_dir\s*=')
        {
            $line = "logs_dir = {0}" -f $currentDir.Replace('\', '/')
        }

        # patch kickstart file
        if ($line -match '^kickstart_file\s*=')
        {
            if ($a1200Kickstart31RomFile)
            {
                $line = "kickstart_file = {0}" -f $a1200Kickstart31RomFile.Replace('\', '/')
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
                # patch workbenchdir hard drive
                if ($harddriveLabels[$harddriveIndex] -match 'WORKBENCHDIR')
                {
                    $line = $line -replace '^(hard_drive_\d+\s*=\s*).*', ("`$1{0}" -f $workbenchDir.Replace('\', '/'))
                }
                # patch kickstartdir hard drive
                elseif ($harddriveLabels[$harddriveIndex] -match 'KICKSTARTDIR')
                {
                    $line = $line -replace '^(hard_drive_\d+\s*=\s*).*', ("`$1{0}" -f $kickstartDir.Replace('\', '/'))
                }
                # patch os39dir hard drive
                elseif ($harddriveLabels[$harddriveIndex] -match 'OS39DIR')
                {
                    $line = $line -replace '^(hard_drive_\d+\s*=\s*).*', ("`$1{0}" -f $os39Dir.Replace('\', '/'))
                }
                # patch userpackagesdir hard drive
                elseif ($harddriveLabels[$harddriveIndex] -match 'USERPACKAGESDIR')
                {
                    $line = $line -replace '^(hard_drive_\d+\s*=\s*).*', ("`$1{0}" -f $userPackagesDir.Replace('\', '/'))
                }
                # patch hard drive
                else
                {
                    $harddrivePath = Join-Path $currentDir -ChildPath (Split-Path $harddrivePath -Leaf)
                    $line = $line -replace '^(hard_drive_\d+\s*=\s*).*', ("`$1{0}" -f $harddrivePath.Replace('\', '/'))
                }
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
    $adfFiles += Get-ChildItem -Path $workbenchDir -Filter *.adf -File

    # add adf files to fs-uae config lines as swappable floppies
    for ($i = 0; $i -lt $adfFiles.Count; $i++)
    {
        $fsuaeConfigLines += "floppy_image_{0} = {1}" -f $i, $adfFiles[$i].FullName.Replace('\', '/')
    }

    # write fs-uae config file without byte order mark
    $utf8Encoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines($fsuaeConfigFile, $fsuaeConfigLines, $utf8Encoding)
}


# get current directory
$currentDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.')


# read winuae and fs-uae config files
$uaeConfigLines = @()

# add winuae config lines, if winuae config file exists
$winuaeConfigFile = Join-Path $currentDir -ChildPath "hstwb-installer.uae"
if (Test-Path -Path $winuaeConfigFile)
{
    $uaeConfigLines += Get-Content $winuaeConfigFile

}

# add fs-uae config lines, if fs-uae config file exists
$fsuaeConfigFile = Join-Path $currentDir -ChildPath "hstwb-installer.fs-uae"
if (Test-Path -Path $fsuaeConfigFile)
{
    $uaeConfigLines += Get-Content $fsuaeConfigFile

}


# self install directories
$workbenchDir = Join-Path $currentDir -ChildPath "Workbench"
$kickstartDir = Join-Path $currentDir -ChildPath "Kickstart"
$os39Dir = Join-Path $currentDir -ChildPath "OS39"
$userPackagesDir = Join-Path $currentDir -ChildPath "UserPackages"
$selfInstallDirs = @()

# check, if workbenchdir exists in uae config files
$workbenchDirPresent = $false
if (($uaeConfigLines | Where-Object { $_ -match 'WORKBENCHDIR' }).Count -gt 0)
{
    $workbenchDirPresent = $true
    $selfInstallDirs += $workbenchDir
}

# check, if workbenchdir exists in uae config files
$kickstartDirPresent = $false
if (($uaeConfigLines | Where-Object { $_ -match 'KICKSTARTDIR' }).Count -gt 0)
{
    $kickstartDirPresent = $true
    $selfInstallDirs += $kickstartDir
}

# check, if workbenchdir exists in uae config files
$os39DirPresent = $false
if (($uaeConfigLines | Where-Object { $_ -match 'OS39DIR' }).Count -gt 0)
{
    $os39DirPresent = $true
    $selfInstallDirs += $os39Dir
}

# check, if workbenchdir exists in uae config files
$userPackagesDirPresent = $false
if (($uaeConfigLines | Where-Object { $_ -match 'USERPACKAGESDIR' }).Count -gt 0)
{
    $userPackagesDirPresent = $true
    $selfInstallDirs += $userPackagesDir
}

# create self install directories, if they don't exist
foreach ($selfInstallDir in $selfInstallDirs)
{
    if (!(Test-Path -Path $selfInstallDir))
    {
        mkdir $selfInstallDir | Out-Null
    }
}


# write install uae config title
Write-Output "------------------"
Write-Output "Install UAE Config"
Write-Output "------------------"
Write-Output "Author: Henrik Noerfjand Stengaard"
Write-Output "Date: 2017-11-02"
Write-Output ""
Write-Output "Patch hard drives to use the following directories:"
Write-Output ("IMAGEDIR        : '{0}'" -f $currentDir)

# write workbenchdir, if it's present
if ($workbenchDirPresent)
{
    Write-Output ("WORKBENCHDIR    : '{0}'" -f $workbenchDir)
}

# write kickstartdir, if it's present
if ($kickstartDirPresent)
{
    Write-Output ("KICKSTARTDIR    : '{0}'" -f $kickstartDir)
}

# write os39dir, if it's present
if ($os39DirPresent)
{
    Write-Output ("OS39DIR         : '{0}'" -f $os39Dir)
}

# write userpackagesdir, if it's present
if ($userPackagesDirPresent)
{
    Write-Output ("USERPACKAGESDIR : '{0}'" -f $userPackagesDir)
}


# install workbench 3.1 adf and kickstart rom files from cloanto amiga forever data directory, if present and patch only is not set
$amigaForeverDataDir = ${Env:AMIGAFOREVERDATA}
if (!$patchOnly -and $amigaForeverDataDir -and (Test-Path -Path $amigaForeverDataDir))
{
    Write-Output ""
    Write-Output ("Installing Workbench 3.1 adf and Kickstart rom files from Cloanto Amiga Forever data directory '{0}'" -f $amigaForeverDataDir)
    
    $sharedAdfDir = [System.IO.Path]::Combine($amigaForeverDataDir, "Shared\adf")
    if (Test-Path -path $sharedAdfDir)
    {
        Write-Output ("- Workbench 3.1 adf files from '{0}'..." -f $sharedAdfDir)
        InstallWorkbenchAdfFiles $sharedAdfDir $workbenchDir
    }
    
    $sharedRomDir = [System.IO.Path]::Combine($amigaForeverDataDir, "Shared\rom")
    if (Test-Path -Path $sharedRomDir)
    {
        Write-Output ("- Kickstart rom files from '{0}'..." -f $sharedRomDir)
        InstallKickstartRomFiles $sharedRomDir $kickstartDir
    }
    Write-Output "Done"
}


# patch and install winuae config file, if it exists
if (Test-Path -Path $winuaeConfigFile)
{
    # patch winuae config file
    Write-Output ""
    Write-Output ("WinUAE configuration file '{0}'" -f $winuaeConfigFile)
    Write-Output "- Patching hard drive directories and kickstart rom..."
    PatchWinuaeConfigFile $winuaeConfigFile $workbenchDir $kickstartDir $os39Dir $userPackagesDir
    
    # get winuae directory from public directory
    $winuaeConfigDir = Get-ChildItem -Path ${Env:PUBLIC} -Recurse | Where-Object { $_.PSIsContainer -and $_.FullName -match 'Amiga Files\\WinUAE\\Configurations$' } | Select-Object -First 1

    # install winuae config file, if winuae config directory exists and patch only is not set
    if (!$patchOnly -and $winuaeConfigDir)
    {
        Write-Output ("- Installing in WinUAE configuration directory '{0}'..." -f $winuaeConfigDir.FullName)
        Copy-Item $winuaeConfigFile -Destination $winuaeConfigDir.FullName -Force
    }

    Write-Output "Done"
}

# patch and install fs-uae config file, if it exists
if (Test-Path -Path $fsuaeConfigFile)
{
    Write-Output ""
    Write-Output ("FS-UAE configuration file '{0}'" -f $fsuaeConfigFile)
    
    # patch fs-uae config file
    Write-Output "- Patching hard drive directories, kickstart rom and workbench adf files as swappable floppies..."
    PatchFsuaeConfigFile $fsuaeConfigFile $workbenchDir $kickstartDir $os39Dir $userPackagesDir

    # get fs-uae directory from public directory
    $fsuaeConfigDir = Get-ChildItem -Path ([System.Environment]::GetFolderPath("MyDocuments")) -Recurse | Where-Object { $_.PSIsContainer -and $_.FullName -match 'FS-UAE\\Configurations$' } | Select-Object -First 1
    
    # install fs-uae config file, if fs-uae config directory exists and patch only is not set
    if (!$patchOnly -and $fsuaeConfigDir)
    {
        Write-Output ("- Installing in FS-UAE configuration directory '{0}'..." -f $fsuaeConfigDir.FullName)
        Copy-Item $fsuaeConfigFile -Destination $fsuaeConfigDir.FullName -Force
    }

    Write-Output "Done"
}