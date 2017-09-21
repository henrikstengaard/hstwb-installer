# Install UAE config
# ------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-08-18
#
# A powershell script to patch HstWB Installer UAE config files with A1200 Kickstart 3.1 rom file and changes harddrive paths to current directory.


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


# patch winuae config file
function PatchWinuaeConfigFile($winuaeConfigFile, $workbenchDir, $kickstartDir, $os39Dir)
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
        if ($line -match '^(filesystem2|uaehf\d+)=' -and $line -match '(WORKBENCHDIR|KICKSTARTDIR|OS39DIR):')
        {
            # update workbench filesystem2
            if ($line -match '^filesystem2=' -and $line -match 'WORKBENCHDIR:')
            {
                $line = $line -replace '^(filesystem2=[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$workbenchDir"
            }

            # update workbench uaehf
            if ($line -match '^uaehf\d+=' -and $line -match 'WORKBENCHDIR:')
            {
                $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$workbenchDir"
            }
            
            # update kickstart filesystem2
            if ($line -match '^filesystem2=' -and $line -match 'KICKSTARTDIR:')
            {
                $line = $line -replace '^(filesystem2=[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$kickstartDir"
            }

            # update kickstart uaehf
            if ($line -match '^uaehf\d+=' -and $line -match 'KICKSTARTDIR:')
            {
                $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$kickstartDir"
            }
            
            # update os39 filesystem2
            if ($line -match '^filesystem2=' -and $line -match 'OS39DIR:')
            {
                $line = $line -replace '^(filesystem2=[^,]*,[^:]*:[^:]*:)[^,]*', "`$1$os39Dir"
            }

            # update os39 uaehf
            if ($line -match '^uaehf\d+=' -and $line -match 'OS39DIR:')
            {
                $line = $line -replace '^(uaehf\d+=[^,]*,[^,]*,[^,:]*:[^:]*:)[^,]*', "`$1$os39Dir"
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
function PatchFsuaeConfigFile($fsuaeConfigFile, $workbenchDir, $kickstartDir, $os39Dir)
{
    # find A1200 kickstart 3.1 rom file
    $a1200Kickstart31RomFile = FindA1200Kickstart31RomFile $kickstartDir
    
    # read fs-uae config file
    $fsuaeConfigLines = @()
    $fsuaeConfigLines += Get-Content $fsuaeConfigFile | Where-Object { $_ -notmatch '^floppy_image_\d+' }

    # get self install harddrives
    $selfInstallHarddrives = @{}
    $fsuaeConfigLines | ForEach-Object { $_ | Select-String -Pattern '^(hard_drive_\d+)_label\s*=\s*(.*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $selfInstallHarddrives.Set_Item($_.Groups[1].Value.Trim(), $_.Groups[2].Value.Trim()) } }

    # patch fs-uae config lines
    for ($i = 0; $i -lt $fsuaeConfigLines.Count; $i++)
    {
        $line = $fsuaeConfigLines[$i]

        # update kickstart file
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
        
        # update hard_drive parameters
        if ($line -match '^hard_drive_\d+\s*=')
        {
            $harddriveIndex = $line | Select-String -Pattern '^(hard_drive_\d+)\s*=' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

            if ($harddriveIndex -and $selfInstallHarddrives.ContainsKey($harddriveIndex))
            {
                if ($selfInstallHarddrives[$harddriveIndex] -match 'WORKBENCHDIR')
                {
                    $line = $line -replace '^(hard_drive_\d+\s*=\s*).*', ("`$1{0}" -f $workbenchDir.Replace('\', '/'))
                }
                elseif ($selfInstallHarddrives[$harddriveIndex] -match 'KICKSTARTDIR')
                {
                    $line = $line -replace '^(hard_drive_\d+\s*=\s*).*', ("`$1{0}" -f $kickstartDir.Replace('\', '/'))
                }
                elseif ($selfInstallHarddrives[$harddriveIndex] -match 'OS39DIR')
                {
                    $line = $line -replace '^(hard_drive_\d+\s*=\s*).*', ("`$1{0}" -f $os39Dir.Replace('\', '/'))
                }
            }
            else
            {
                $harddrivePath = $line | Select-String -Pattern '^hard_drive_\d+\s*=\s*(.*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1

                if ($harddrivePath)
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


# default self install directories
$workbenchDir = Join-Path $currentDir -ChildPath "Workbench"
$kickstartDir = Join-Path $currentDir -ChildPath "Kickstart"
$os39Dir = Join-Path $currentDir -ChildPath "OS39"


# use cloanto amiga forever data directory for self install directories, if present
$amigaForeverDataDir = ${Env:AMIGAFOREVERDATA}
if ($amigaForeverDataDir -and (Test-Path -Path $amigaForeverDataDir))
{
    $sharedAdfDir = [System.IO.Path]::Combine($amigaForeverDataDir, "Shared\adf")
    if (Test-Path -path $sharedAdfDir)
    {
        $workbenchDir = $sharedAdfDir
    }

    $sharedRomDir = [System.IO.Path]::Combine($amigaForeverDataDir, "Shared\rom")
    if (Test-Path -Path $sharedRomDir)
    {
        $kickstartDir = $sharedRomDir
    }
}


# create workbench, kickstart and os39 directories, if they don't exist
foreach ($dir in @($workbenchDir, $kickstartDir, $os39Dir))
{
    if (!(Test-Path -Path $dir))
    {
        mkdir $dir | Out-Null
    }
}


# winuae config file
$winuaeConfigFile = Join-Path $currentDir -ChildPath "hstwb-installer.uae"


# patch and install winuae config file, if it exists
if (Test-Path -Path $winuaeConfigFile)
{
    # patch winuae config file
    Write-Output ("Patching WinUAE configuration '{0}'" -f $winuaeConfigFile)
    Write-Output ""
    PatchWinuaeConfigFile $winuaeConfigFile $workbenchDir $kickstartDir $os39Dir


    # get winuae directory from public directory
    $winuaeConfigDir = Get-ChildItem -Path ${Env:PUBLIC} -Recurse | Where-Object { $_.PSIsContainer -and $_.FullName -match 'Amiga Files\\WinUAE\\Configurations$' } | Select-Object -First 1

    # prompt for install winuae configuration, if winuae configuration directory exists
    if ($winuaeConfigDir)
    {
        Write-Output ("Detected WinUAE configurations directory '{0}'" -f $winuaeConfigDir.FullName)
        Write-Output ""
        
        # copy winuae configuration file to winuae config dir, if confirmed install winuae configuration
        if ((Read-Host -Prompt "Install WinUAE configuration? [Y/N]") -match '^y')
        {
            Copy-Item $winuaeConfigFile -Destination $winuaeConfigDir.FullName -Force
        }
    }
    else
    {
        Write-Output ("WinUAE configurations directory doesn't exist in '{0}'" -f ${Env:PUBLIC})
    }
    Write-Output ""
}


# fs-uae config file
$fsuaeConfigFile = Join-Path $currentDir -ChildPath "hstwb-installer.fs-uae"


# patch and install fs-uae config file, if it exists
if (Test-Path -Path $fsuaeConfigFile)
{
    # patch fs-uae config file
    Write-Output ("Patching FS-UAE configuration '{0}'" -f $fsuaeConfigFile)
    Write-Output ""
    PatchFsuaeConfigFile $fsuaeConfigFile $workbenchDir $kickstartDir $os39Dir


    # get fs-uae directory from public directory
    $fsuaeConfigDir = Get-ChildItem -Path ([System.Environment]::GetFolderPath("MyDocuments")) -Recurse | Where-Object { $_.PSIsContainer -and $_.FullName -match 'FS-UAE\\Configurations$' } | Select-Object -First 1
    
    # prompt for install fs-uae configuration, if winuae configuration directory exists
    if ($fsuaeConfigDir)
    {
        Write-Output ("Detected FS-UAE configurations directory '{0}'" -f $fsuaeConfigDir.FullName)
        Write-Output ""
        
        # copy fs-uae configuration file to fs-uae config dir, if confirmed install fs-uae configuration
        if ((Read-Host -Prompt "Install FS-UAE configuration? [Y/N]") -match '^y')
        {
            Copy-Item $fsuaeConfigFile -Destination $fsuaeConfigDir.FullName -Force
        }
    }
    else
    {
        Write-Output ("FS-UAE configurations directory doesn't exist in '{0}'" -f ([System.Environment]::GetFolderPath("MyDocuments")))
    }
}
