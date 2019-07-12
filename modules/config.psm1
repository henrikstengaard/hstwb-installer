# HstWB Installer Config Module
# -----------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2019-07-12
#
# A powershell module for HstWB Installer with config functions.


# read ini file
function ReadIniFile($iniFile)
{
    return ReadIniText (Get-Content -Path $iniFile)
}


# read ini text
function ReadIniText($iniText)
{
    $ini = @{}

    switch -regex ($iniText -split "`r`n" | Where-Object { $_ })
    {
        "^\[(.+)\]$" {
            $section = $matches[1]
            $ini[$section] = @{}
        }
        "(.+)=(.+)" {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }

    return $ini
}


# write ini file
function WriteIniFile($iniFile, $ini)
{
    $iniLines = @()

    foreach ($key in ($ini.keys | Sort-Object))
    {
        if (!($($ini[$key].GetType().Name) -eq "Hashtable"))
        {
            $iniLines += "$key=$($ini[$key])"
        }
        else
        {
            # Section
            $iniLines += "[$key]"
            
            foreach ($sectionKey in ($ini[$key].keys | Sort-Object))
            {
                $iniLines += "$sectionKey=$($ini[$key][$sectionKey])"
            }
        }
    }

    [System.IO.File]::WriteAllText($iniFile, ($iniLines -join [System.Environment]::NewLine) + [System.Environment]::NewLine)
}


# default settings
function DefaultSettings($settings)
{
    $settings.Image = @{}
    $settings.AmigaOs = @{}
    $settings.Kickstart = @{}
    $settings.Winuae = @{}
    $settings.Packages = @{}
    $settings.Installer = @{}
    $settings.Emulator = @{}
    $settings.UserPackages = @{}

    $settings.Kickstart.InstallKickstart = 'Yes'
    $settings.Packages.InstallPackages = ''
    $settings.Installer.Mode = 'Install'
    
    # use cloanto amiga forever data directory, if present
    $amigaForeverDataPath = ${Env:AMIGAFOREVERDATA}
    if ($amigaForeverDataPath)
    {
        $amigaOsDir = [System.IO.Path]::Combine($amigaForeverDataPath, "Shared\adf")
        if (test-path -path $amigaOsDir)
        {
            $settings.AmigaOs.AmigaOsDir = $amigaOsDir
        }

        $kickstartRomDir = [System.IO.Path]::Combine($amigaForeverDataPath, "Shared\rom")
        if (test-path -path $kickstartRomDir)
        {
            $settings.Kickstart.KickstartRomDir = $kickstartRomDir
        }
    }

    $settings.Emulator.EmulatorFile = DefaultEmulatorFile

    $settings.UserPackages.UserPackagesDir = ''
    $settings.UserPackages.InstallUserPackages = ''
}

function IsFsuae64bit($fsuaeFile)
{
    $fsuaeBytes = [System.IO.File]::ReadAllBytes($fsuaeFile)
    $x64PatternBytes = [System.Text.Encoding]::UTF8.GetBytes("windows-x86-64")
    
    for ($i = 0; $i -lt $fsuaeBytes.Count; $i++)
    {
        if ($fsuaeBytes[$i] -ne $x64PatternBytes[0])
        {
            continue
        }

        $hasX64Pattern = $true

        for ($j = 0; $j -lt $x64PatternBytes.Count; $j++)
        {
            if ($i + $j -ge $fsuaeBytes.Count)
            {
                return $false
            }

            if ($fsuaeBytes[$i + $j] -ne $x64PatternBytes[$j])
            {
                $hasX64Pattern = $false
            }
        }

        if ($hasX64Pattern)
        {
            return $true
        }
    }

    return $false
}

function DetectEmulatorName($emulatorFile)
{
    if (!$emulatorFile -or !(Test-Path -Path $emulatorFile))
    {
        return $null
    }

    $version = (get-item $emulatorFile).VersionInfo.FileVersion

    if ($emulatorFile -match 'winuae64.exe$')
    {
        return 'WinUAE {0} 64-bit' -f $version
    }
    elseif ($emulatorFile -match 'winuae.exe$')
    {
        return 'WinUAE {0} 32-bit' -f $version
    }
    elseif ($emulatorFile -match 'fs-uae.exe$')
    {
        # if (IsFsuae64bit $emulatorFile)
        # {
        #     $platform = '64-bit'
        # }
        # else
        # {
        #     $platform = '32-bit'
        # }
        # return 'FS-UAE {0} {1}' -f $version, $platform
        return 'FS-UAE {0}' -f $version
    }

    return $null
}

function FindEmulators()
{
    $emulators = @()
    
    $winuaeX64File = "${Env:ProgramFiles}\WinUAE\winuae64.exe"
    if (test-path -path $winuaeX64File)
    {
        $version = (get-item $winuaeX64File).VersionInfo.FileVersion
        $emulators += @{ 'Name' = (DetectEmulatorName $winuaeX64File); 'File' = $winuaeX64File }
    }
    
    $winuaeX86File = "${Env:ProgramFiles(x86)}\WinUAE\winuae.exe"
    if (test-path -path $winuaeX86File)
    {
        $version = (get-item $winuaeX86File).VersionInfo.FileVersion
        $emulators += @{ 'Name' = (DetectEmulatorName $winuaeX86File); 'File' = $winuaeX86File }
    }

    $cloantoWinuaeX64File = "${Env:ProgramFiles}\Cloanto\Amiga Forever\WinUAE\winuae64.exe"
    if (test-path -path $cloantoWinuaeX64File)
    {
        $version = (get-item $cloantoWinuaeX64File).VersionInfo.FileVersion
        $emulators += @{ 'Name' = (DetectEmulatorName $cloantoWinuaeX64File); 'File' = $cloantoWinuaeX64File }
    }
    
    $cloantoWinuaeX86File = "${Env:ProgramFiles(x86)}\Cloanto\Amiga Forever\WinUAE\winuae.exe"
    if (test-path -path $cloantoWinuaeX86File)
    {
        $version = (get-item $cloantoWinuaeX86File).VersionInfo.FileVersion
        $emulators += @{ 'Name' = (DetectEmulatorName $cloantoWinuaeX86File); 'File' = $cloantoWinuaeX86File }
    }
    
    $fsuaeFile = "${Env:LOCALAPPDATA}\fs-uae\fs-uae.exe"
    if (test-path -path $fsuaeFile)
    {
        $version = (get-item $fsuaeFile).VersionInfo.FileVersion
        $emulators += @{ 'Name' = (DetectEmulatorName $fsuaeFile); 'File' = $fsuaeFile }
    }

    return $emulators
}

function DefaultEmulatorFile()
{
    $defaultEmulator = FindEmulators | Select-Object -First 1

    if (!$defaultEmulator)
    {
        return $null
    }

    return $defaultEmulator.File
}


# default assigns
function DefaultAssigns($assigns)
{
    $defaultHstwbInstallerAssigns = @{ 'SystemDir' = 'DH0:'; 'HstWBInstallerDir' = 'DH1:HstWBInstaller' }
    $assigns.Set_Item('Global', $defaultHstwbInstallerAssigns)
}


# upgrade settings
function UpgradeSettings($hstwb)
{
    # set default installer mode, if not present
    if (!$hstwb.Settings.Installer -or !$hstwb.Settings.Installer.Mode)
    {
        $hstwb.Settings.Installer = @{}
        $hstwb.Settings.Installer.Mode = "Install"
    }
    
    # create packages section in settings, if it doesn't exist
    if (!($hstwb.Settings.Packages))
    {
        $hstwb.Settings.Packages = @{}
    }

    if (!($hstwb.Settings.UserPackages))
    {
        $hstwb.Settings.UserPackages = @{}
    }
    
    # remove amiga os 3.9 section in settings, if it exist
    if ($hstwb.Settings.AmigaOS39)
    {
        $hstwb.Settings.Remove('AmigaOS39')
    }
    
    # set default image dir, if image dir doesn't exist
    if ($hstwb.Settings.Image.ImageDir -match '^.+$' -and !(test-path -path $hstwb.Settings.Image.ImageDir))
    {
        $hstwb.Settings.Image.ImageDir = ''
    }

    # add emulator settings, if not present
    if (!$hstwb.Settings.Emulator -or !$hstwb.Settings.Emulator.EmulatorFile)
    {
        $hstwb.Settings.Emulator = @{}
        $hstwb.Settings.Emulator.EmulatorFile = DefaultEmulatorFile
    }

    # upgrade winuae to emulator settings
    if ($hstwb.Settings.Winuae -and $hstwb.Settings.Winuae.WinuaePath)
    {
        $hstwb.Settings.Emulator.EmulatorFile = $hstwb.Settings.Winuae.WinuaePath
        $hstwb.Settings.Remove('WinUAE')
    }

    # add amiga os settings, if it doesn't exist
    if (!$hstwb.Settings.AmigaOs)
    {
        $hstwb.Settings.AmigaOs = @{}
    }

    if ($hstwb.Settings.Workbench)
    {
        # upgrade workbench adf path to workbench adf dir
        if ($hstwb.Settings.Workbench.WorkbenchAdfPath)
        {
            $hstwb.Settings.Workbench.WorkbenchAdfDir = $hstwb.Settings.Workbench.WorkbenchAdfPath
            $hstwb.Settings.Workbench.Remove('WorkbenchAdfPath')
        }

        # upgrade workbench to amiga os
        $hstwb.Settings.AmigaOs.InstallAmigaOs = $hstwb.Settings.Workbench.InstallWorkbench
        $hstwb.Settings.AmigaOs.AmigaOsDir = $hstwb.Settings.Workbench.WorkbenchAdfDir
        $hstwb.Settings.AmigaOs.AmigaOsSet = $hstwb.Settings.Workbench.WorkbenchAdfSet

        # remove workbench settings
        $hstwb.Settings.Remove('Workbench')
    }


    # upgrade kickstart rom path to kickstart rom dir
    if ($hstwb.Settings.Kickstart.KickstartRomPath)
    {
        $hstwb.Settings.Kickstart.KickstartRomDir = $hstwb.Settings.Kickstart.KickstartRomPath
        $hstwb.Settings.Kickstart.Remove('KickstartRomPath')
    }

    # upgrade kickstart rom dir to kickstart dir
    if ($hstwb.Settings.Kickstart.KickstartRomDir)
    {
        $hstwb.Settings.Kickstart.KickstartDir = $hstwb.Settings.Kickstart.KickstartRomDir
        $hstwb.Settings.Kickstart.Remove('KickstartRomDir')
    }

    # upgrade kickstart rom set to kickstart set
    if ($hstwb.Settings.Kickstart.KickstartRomSet)
    {
        $hstwb.Settings.Kickstart.KickstartSet = $hstwb.Settings.Kickstart.KickstartRomSet
        $hstwb.Settings.Kickstart.Remove('KickstartRomSet')
    }

    # upgrade install packages
    if ($hstwb.Settings.Packages.InstallPackages)
    {
        $installPackageNames = @()
        if ($hstwb.Settings.Packages.InstallPackages -ne '')
        {
            $installPackageNames += $hstwb.Settings.Packages.InstallPackages.ToLower() -split ',' | Where-Object { $_ }
        }        

        # add install packages in packages
        for($i = 0; $i -lt $installPackageNames.Count; $i++)
        {
            $hstwb.Settings.Packages.Set_Item(("InstallPackage{0}" -f ($i + 1)), $installPackageNames[$i])
        }

        $hstwb.Settings.Packages.Remove('InstallPackages')
    }    
}


# upgrade assigns
function UpgradeAssigns($hstwb)
{
    # create defailt assigns, if assigns is empty or doesn't contain global assigns
    if ($hstwb.Assigns.Keys.Count -eq 0 -or !$hstwb.Assigns.ContainsKey('Global'))
    {
        DefaultAssigns $hstwb.Assigns
    }
}


# read images
function ReadImages($imagesPath)
{
    $images = New-Object System.Collections.Generic.List[System.Object]
    
    # get image files
    $imageFiles = Get-ChildItem -Path $imagesPath -Filter '*.zip' | Where-Object { !$_.PSIsContainer }

    # read image json from image files
    foreach ($imageFile in $imageFiles)
    {
        # read image json file from image file
        $imageJsonText = ReadZipEntryTextFile $imageFile.FullName 'hstwb-image\.json$'

        # skip, if image ini text doesn't exist
        if (!$imageJsonText)
        {
            #throw ("Image file '{0}' doesn't contain 'hstwb-image.json' file!" -f $imageFile.Name)
            continue
        }

        # TODO validate image, check structure is correct
        
        # read image json text
        $image = $imageJsonText | ConvertFrom-Json

        # add image name and image file to images
        $images.Add(@{ "Name" = $image.Name; "ImageFile" = $imageFile.FullName })
    }

    return $images
}


# read packages
function ReadPackages($packagesPath)
{
    $packages = @{}

    # get package files
    $packageFiles = Get-ChildItem -Path $packagesPath -Filter '*.zip' | Where-Object { !$_.PSIsContainer }

    # read package ini from package files
    foreach ($packageFile in $packageFiles)
    {
        # read package json text file from package file
        $packageJsonText = ReadZipEntryTextFile $packageFile.FullName 'hstwb-package\.json$'

        # skip, if package ini text doesn't exist
        if (!$packageJsonText)
        {
            #throw ("Package file '" + $packageFile.FullName + "' doesn't contain 'hstwb-package.json' file!")
            continue
        }

        # read package json text
        $package = $packageJsonText | ConvertFrom-Json
        
        # TODO validate package, check structure is correct

        # add id, fullname and package file properties to package
        $package | Add-Member -MemberType NoteProperty -Name 'Id' -Value (CalculateMd5FromText $package.Name.ToLower())
        $package | Add-Member -MemberType NoteProperty -Name 'FullName' -Value ("{0} v{1}" -f $package.Name, $package.Version)
        $package | Add-Member -MemberType NoteProperty -Name 'PackageFile' -Value $packageFile.FullName

        # add package, if it's not added or version is newer
        if (!$packages[$package.Id] -or [version]$package.Version -gt $packages[$package.Id].Version)
        {
            $packages[$package.Name.ToLower()] = $package
        }
    }

    return $packages
}


# detect user packages
function DetectUserPackages($hstwb)
{
    $userPackages = @{}

    if (!$hstwb.Settings.UserPackages.UserPackagesDir -or !(Test-Path -Path $hstwb.Settings.UserPackages.UserPackagesDir))
    {
        return $userPackages
    }

    # get user packages dirs
    $userPackageDirs += Get-ChildItem -Path $hstwb.Settings.UserPackages.UserPackagesDir | Where-Object { $_.PSIsContainer }

    foreach($userPackageDir in $userPackageDirs)
    {
        # skip, if user package doesn't contain '_installdir' assign file
        if (!(Test-Path -Path (Join-Path $userPackageDir.FullName -ChildPath '_installdir')))
        {
            continue
        }

        $userPackage = @{ 'Name' = $userPackageDir.Name }
        
        # get user package dir name
        $userPackageDirName = $userPackageDir.Name.ToLower()
                
        # add user package
        $userPackages.Set_Item($userPackageDirName, $userPackage)
    }

    return $userPackages
}

# remove install packages
function RemoveInstallPackages($hstwb)
{
    foreach($installPackageKey in ($hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' }))
    {
        $hstwb.Settings.Packages.Remove($installPackageKey)
    }

    UpdateAssigns $hstwb     
}

# update install packages
function UpdateInstallPackages($hstwb)
{
    # build amiga os versions
    $amigaOsVersionsIndex = @{}
    foreach ($package in ($hstwb.Packages.Values | Where-Object { $_.AmigaOsVersions }))
    {
        $package.AmigaOsVersions | ForEach-Object { $amigaOsVersionsIndex[$_] = $true }
    }

    # reset package filtering to all amiga os versions, if package filtering is not defined or doesn't match packages amiga os versions
    if (!$hstwb.Settings.Packages.PackageFiltering -or !$amigaOsVersionsIndex.ContainsKey($hstwb.Settings.Packages.PackageFiltering))
    {
        $hstwb.Settings.Packages.PackageFiltering = 'All'
    }

    # get and remove install packages
    $installPackageNames = @()
    foreach($installPackageKey in ($hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' }))
    {
        $installPackageNames += $hstwb.Settings.Packages.Get_Item($installPackageKey.ToLower())
        $hstwb.Settings.Packages.Remove($installPackageKey)
    }

    # add install packages for packages that exist
    $installPackageIndex = 0;
    foreach($installPackageName in $installPackageNames)
    {
        # skip, if package doesn't exist or package filtering is not all and package doesn't support amiga os version
        if (!$hstwb.Packages.ContainsKey($installPackageName) -or ($hstwb.Settings.Packages.PackageFiltering -ne 'All' -and $hstwb.Packages[$installPackageName].AmigaOsVersions -and $hstwb.Packages[$installPackageName].AmigaOsVersions -notcontains $hstwb.Settings.Packages.PackageFiltering))
        {
            continue
        }

        $installPackageIndex++
        $hstwb.Settings.Packages.Set_Item(("InstallPackage{0}" -f $installPackageIndex), $installPackageName)
    }
}


# update install user packages
function UpdateInstallUserPackages($hstwb)
{
    # get and remove install user packages
    $installUserPackageNames = @()
    foreach($installUserPackageKey in ($hstwb.Settings.UserPackages.Keys | Where-Object { $_ -match 'InstallUserPackage\d+' }))
    {
        $installUserPackageNames += $hstwb.Settings.UserPackages.Get_Item($installUserPackageKey.ToLower())
        $hstwb.Settings.UserPackages.Remove($installUserPackageKey)
    }

    # add install packages for packages that exist
    $installUserPackageIndex = 0;
    foreach($installUserPackageName in $installUserPackageNames)
    {
        if (!$hstwb.UserPackages.ContainsKey($installUserPackageName))
        {
            continue
        }

        $installUserPackageIndex++
        $hstwb.Settings.UserPackages.Set_Item(("InstallUserPackage{0}" -f $installUserPackageIndex), $installUserPackageName)
    }
}


# update assigns
function UpdateAssigns($hstwb)
{  
    # get install packages
    $installPackageNames = @()
    foreach($installPackageKey in ($hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' }))
    {
        $installPackageNames += $hstwb.Settings.Packages.Get_Item($installPackageKey.ToLower())
    }
    
    # 
    $packageNames = @()
    foreach ($installPackageName in $installPackageNames)
    {
        $package = $hstwb.Packages[$installPackageName]

        if (!$package)
        {
            continue
        }

        $packageNames += $package.Name

        if (!$package.Assigns -or $package.Assigns.Count -eq 0)
        {
            continue
        }

        # add new package assigns, if package exists. otherwise add all package assigns
        if ($hstwb.Assigns.ContainsKey($package.Name))
        {
            $packageAssigns = $hstwb.Assigns[$package.Name]

            foreach ($assign in ($package.Assigns | Where-Object { $_.Path } | Sort-Object @{expression={$_.Name};Ascending=$true} ))
            {
                if ($packageAssigns.ContainsKey($assign.Name))
                {
                    continue
                }
                $packageAssigns.Set_Item($assign.Name, $assign.Path)
            }
        }
        else
        {
            $hstwb.Assigns[$package.Name] = @{}
            $package.Assigns | Where-Object { $_.Path } | Sort-Object @{expression={$_.Name};Ascending=$true} | Foreach-Object { $hstwb.Assigns[$package.Name][$_.Name] = $_.Path }
        }
    }


    # remove assigns for packages, that doesn't exist in 
    $assignKeys = @()
    $assignKeys += $hstwb.Assigns.Keys | Where-Object { $_ -notmatch 'Global' }

    foreach($assignKey in $assignKeys)
    {
        $packageKey = $packageNames | Where-Object { $_ -like ('*{0}*' -f $assignKey) } | Select-Object -First 1

        if (!$packageKey)
        {
            $hstwb.Assigns.Remove($assignKey)
        }
    }
}


# validate assigns
function ValidateAssigns($assigns)
{
    # return false, if assigns doesn't contain global section
    if (!$assigns.ContainsKey('Global'))
    {
        Write-Host "Error: Assigns doesn't contain 'Global' section!" -ForegroundColor "Red"
        return $false
    }


    $globalAssigns = $assigns.Get_Item('Global')

    # get assign names from global section
    $globalAssignNames = @()
    $globalAssignNames += $globalAssigns.keys | ForEach-Object { $_.ToUpper() } 


    # check global assign names contain 'SYSTEMDIR', 'HSTWBINSTALLERDIR' assign name
    foreach ($assignName in @("SYSTEMDIR", "HSTWBINSTALLERDIR"))
    {
        # return false, if global section doesn't contain assign name
        if (!($globalAssignNames -contains $assignName))
        {
            Write-Host "Error: Assign section 'Global' doesn't contain assign name '$assignName'!" -ForegroundColor "Red"
            return $false
        }
    }


    # validate assign sections other than global
    foreach ($assignSectionName in ($assigns.keys | Where-Object { $_ -notmatch 'Global' }))
    {
        $assignSection = $assigns.Get_Item($assignSectionName)

        # get assign names from assign section
        $assignSectionAssignNames = @()
        $assignSectionAssignNames += $assignSection.keys | ForEach-Object { $_.ToUpper() } 
        
        # check assign section assign names doesn't contain a reserved assign name
        foreach ($assignName in @("SYSTEMDIR", "HSTWBINSTALLERDIR", "PACKAGES", "PACKAGESDIR", "INSTALL"))
        {
            # return false, if assign section contain reserved assign name
            if ($assignSectionAssignNames -contains $assignName)
            {
                Write-Host "Error: Assign section '$assignSectionName' can not contain reserved assign name '$assignName'!" -ForegroundColor "Red"
                return $false
            }
        }
    }

    return $true
}


# validate settings
function ValidateSettings($settings)
{
    # fail, if Mode parameter doesn't exist in settings file or is not valid
    if (!$settings.Installer.Mode -or $settings.Installer.Mode -notmatch '^(Install|BuildSelfInstall|BuildPackageInstallation|BuildUserPackageInstallation|Test)$')
    {
        Write-Host "Error: Mode parameter doesn't exist in settings file or is not valid!" -ForegroundColor "Red"
        return $false
    }

    # fail, if ImageDir directory doesn't exist for installer modes other than 'BuildPackageInstallation'
    if ($settings.Installer.Mode -notmatch '^(BuildPackageInstallation|BuildUserPackageInstallation)$' -and $settings.Image.ImageDir -match '^.+$' -and !(test-path -path $settings.Image.ImageDir))
    {
        Write-Host "Error: ImageDir parameter doesn't exist in settings file or directory doesn't exist!" -ForegroundColor "Red"
        return $false
    }

    if ($settings.Installer.Mode -match '^Install$')
    {
        # fail, if install amiga os parameter doesn't exist in settings file or is not valid
        if (!$settings.AmigaOs.InstallAmigaOs -or $settings.AmigaOs.InstallAmigaOs -notmatch '(Yes|No)')
        {
            Write-Host "Error: InstallAmigaOs parameter doesn't exist in settings file or is not valid!" -ForegroundColor "Red"
            return $false
        }

        # fail, if amiga os dir parameter doesn't exist in settings file or directory doesn't exist
        if (!$settings.AmigaOs.AmigaOsDir -or ($settings.AmigaOs.AmigaOsDir -match '^.+$' -and !(test-path -path $settings.AmigaOs.AmigaOsDir)))
        {
            Write-Host "Error: AmigaOsDir parameter doesn't exist in settings file or directory doesn't exist!" -ForegroundColor "Red"
            return $false
        }

        # fail, if amiga os set parameter doesn't exist settings file or it's not defined
        if (!$settings.AmigaOs.AmigaOsSet -or $settings.AmigaOs.AmigaOsSet -eq '')
        {
            Write-Host "Error: AmigaOsSet parameter doesn't exist in settings file or it's not defined!" -ForegroundColor "Red"
            return $false
        }

        # fail, if InstallKickstart parameter doesn't exist in settings file or is not valid
        if (!$settings.Kickstart.InstallKickstart -or $settings.Kickstart.InstallKickstart -notmatch '^(Yes|No)$')
        {
            Write-Host "Error: InstallKickstart parameter doesn't exist in settings file or is not valid!" -ForegroundColor "Red"
            return $false
        }

        # fail, if KickstartSet parameter doesn't exist in settings file or it's not defined
        if (!$settings.Kickstart.KickstartSet -or $settings.Kickstart.KickstartSet -eq '')
        {
            Write-Host "Error: KickstartSet parameter doesn't exist in settings file or it's not defined!" -ForegroundColor "Red"
            return $false
        }
    }

    if ($settings.Installer.Mode -match '^(Install|BuildSelfInstall|Test)$')
    {
        # fail, if KickstartDir parameter doesn't exist in settings file or directory doesn't exist
        if (!$settings.Kickstart.KickstartDir -or ($settings.Kickstart.KickstartRomDir -match '^.+$' -and !(test-path -path $settings.Kickstart.KickstartRomDir)))
        {
            Write-Host "Error: KickstartRomPath parameter doesn't exist in settings file or directory doesn't exist!" -ForegroundColor "Red"
            return $false
        }
    }

    return $true
}