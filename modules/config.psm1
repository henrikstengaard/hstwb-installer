# HstWB Installer Config Module
# -----------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-05-05
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
    $settings.Workbench = @{}
    $settings.AmigaOS39 = @{}
    $settings.Kickstart = @{}
    $settings.Winuae = @{}
    $settings.Packages = @{}
    $settings.Installer = @{}
    $settings.Emulator = @{}

    $settings.Workbench.InstallWorkbench = 'Yes'
    $settings.Kickstart.InstallKickstart = 'Yes'
    $settings.Packages.InstallPackages = ''
    $settings.Installer.Mode = 'Install'
    
    $settings.AmigaOS39.InstallAmigaOS39 = 'No'

    # use cloanto amiga forever data directory, if present
    $amigaForeverDataPath = ${Env:AMIGAFOREVERDATA}
    if ($amigaForeverDataPath)
    {
        $workbenchAdfPath = [System.IO.Path]::Combine($amigaForeverDataPath, "Shared\adf")
        if (test-path -path $workbenchAdfPath)
        {
            $settings.Workbench.WorkbenchAdfDir = $workbenchAdfPath
            $settings.Workbench.WorkbenchAdfSet = 'Workbench 3.1 Cloanto Amiga Forever 2016'
        }

        $kickstartRomPath = [System.IO.Path]::Combine($amigaForeverDataPath, "Shared\rom")
        if (test-path -path $kickstartRomPath)
        {
            $settings.Kickstart.KickstartRomDir = $kickstartRomPath
            $settings.Kickstart.KickstartRomSet = 'Kickstart Cloanto Amiga Forever 2016'
        }
    }

    $settings.Emulator.EmulatorFile = DefaultEmulatorFile
}

function DefaultEmulatorFile()
{
    # return winuae 64-bit, if it exists in program files
    $winuaeX64Path = "${Env:ProgramFiles}\WinUAE\winuae64.exe"
    if (test-path -path $winuaeX64Path)
    {
        return $winuaeX64Path
    }

    # return winuae 32-bit, if it exists in program files x86
    $winuaeX86Path = "${Env:ProgramFiles(x86)}\WinUAE\winuae.exe"
    if (test-path -path $winuaeX86Path)
    {
        return $winuaeX86Path
    }

    # return fs-uae, if it exists in user's local app data
    $fsuaeFile = "${Env:LOCALAPPDATA}\fs-uae\fs-uae.exe"
    if (test-path -path $fsuaeFile)
    {
        return $fsuaeFile
    }
    
    return $null
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
        $hstwb.Settings.Packages.InstallPackages = ''
    }
    
    
    # create amiga os 3.9 section in settings, if it doesn't exist
    if (!($hstwb.Settings.AmigaOS39))
    {
        $hstwb.Settings.AmigaOS39 = @{}
        $hstwb.Settings.AmigaOS39.InstallAmigaOS39 = 'No'
        $hstwb.Settings.AmigaOS39.InstallBoingBags = 'No'
    }
    
    
    # set default image dir, if image dir doesn't exist
    if ($hstwb.Settings.Image.ImageDir -match '^.+$' -and !(test-path -path $hstwb.Settings.Image.ImageDir))
    {
        $hstwb.Settings.Image.ImageDir = ''
    }
    

    # set default emulator, if not present
    if (!$hstwb.Settings.Emulator -or !$hstwb.Settings.Emulator.EmulatorFile)
    {
        $hstwb.Settings.Emulator = @{}
        $hstwb.Settings.Emulator.EmulatorFile = DefaultEmulatorFile
        $hstwb.SettingsWinUAE
    }

    if ($hstwb.Settings.WinUAE)
    {
        $hstwb.Settings.Remove('WinUAE')
    }

    if ($hstwb.Settings.Workbench.WorkbenchAdfPath)
    {
        $hstwb.Settings.Workbench.WorkbenchAdfDir = $hstwb.Settings.Workbench.WorkbenchAdfPath
        $hstwb.Settings.Workbench.Remove('WorkbenchAdfPath')
    }

    if ($hstwb.Settings.Kickstart.KickstartRomPath)
    {
        $hstwb.Settings.Kickstart.KickstartRomDir = $hstwb.Settings.Kickstart.KickstartRomPath
        $hstwb.Settings.Workbench.Remove('KickstartRomPath')
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
    $images = @{}
    
    # get image files
    $imageFiles = Get-ChildItem -Path $imagesPath -Filter '*.zip' | Where-Object { !$_.PSIsContainer }

    # read image ini from image files
    foreach ($imageFile in $imageFiles)
    {
        # read image ini text file from image file
        $imageIniText = ReadZipEntryTextFile $imageFile.FullName 'image\.ini$'

        # skip, if image ini text doesn't exist
        if (!$imageIniText)
        {
            Write-Error ("Image file '" + $imageFile.FullName + "' doesn't contain image.ini file!")
            exit 1
        }

        # read image ini text
        $imageIni = ReadIniText $imageIniText

        # add image name and image file to images
        $images.Set_Item($imageIni.Image.Name, $imageFile.FullName)
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
        # read package ini text file from package file
        $packageIniText = ReadZipEntryTextFile $packageFile.FullName 'package\.ini$'

        # skip, if package ini text doesn't exist
        if (!$packageIniText)
        {
            Write-Error ("Package file '" + $packageFile.FullName + "' doesn't contain package.ini file!")
            exit 1
        }

        # read package ini text
        $packageIni = ReadIniText $packageIniText

        # fail, if package ini doesn't contain package section
        if (!$packageIni.Package)
        {
            Write-Error ("Package file '" + $packageFile.FullName + "' doesn't have package section in package.ini!")
            exit 1
            
        }

        # fail, if package ini doesn't have a valid name
        if (!$packageIni.Package.Name -or $packageIni.Package.Name -eq '')
        {
            Write-Error ("Package file '" + $packageFile.FullName + "' doesn't have a valid name in package.ini!")
            exit 1
        }

        # fail, if package ini doesn't have a valid version
        if (!$packageIni.Package.Version -or $packageIni.Package.Version -notmatch '^\d+\.\d+\.\d+$' )
        {
            Write-Error ("Package file '" + $packageFile.FullName + "' doesn't have a valid version in package section!")
            exit 1
        }

        # get package filename
        $packageFileName = $packageFile.Name.ToLower() -replace '\.zip$'

        # add package ini to packages
        $packages.Set_Item($packageFileName, $packageIni)
    }

    return $packages
}


# update packages
function UpdatePackages($hstwb)
{
    # get install packages defined in settings packages section
    $packageFileNames = @()
    if ($hstwb.Settings.Packages.InstallPackages -and $hstwb.Settings.Packages.InstallPackages -ne '')
    {
        $packageFileNames += $hstwb.Settings.Packages.InstallPackages.ToLower() -split ',' | Where-Object { $_ }
    }

    # get packages that exist in packages path
    $existingPackages = New-Object System.Collections.ArrayList

    # remove packages, if they don't exist
    $packageFileNames | ForEach-Object { if ($hstwb.Packages.ContainsKey($_)) { [void]$existingPackages.Add($_) } }

    # update install packages with packages that exist
    $hstwb.Settings.Packages.InstallPackages = [string]::Join(',', $existingPackages.ToArray())
}


# update assigns
function UpdateAssigns($hstwb)
{  
    # get install packages defined in settings packages section
    $packageFileNames = @()
    if ($hstwb.Settings.Packages.InstallPackages -and $hstwb.Settings.Packages.InstallPackages -ne '')
    {
        $packageFileNames += $hstwb.Settings.Packages.InstallPackages -split ',' | Where-Object { $_ }
    }

    $packageNames = @()

    # 
    foreach ($packageFileName in $packageFileNames)
    {
        $packageFileName = $packageFileName.ToLower()


        if (!$hstwb.Packages.ContainsKey($packageFileName))
        {
            continue
        }

        $package = $hstwb.Packages.Get_Item($packageFileName)

        $packageNames += $package.Package.Name

        if (!$package.DefaultAssigns)
        {
            continue
        }

        # add new package assigns, if package exists. otherwise add all package assigns
        if ($hstwb.Assigns.ContainsKey($package.Package.Name))
        {
            $packageAssigns = $hstwb.Assigns.Get_Item($package.Package.Name)

            foreach ($key in ($package.DefaultAssigns.keys | Sort-Object))
            {
                if (!$packageAssigns.ContainsKey($key))
                {
                    $packageAssigns.Set_Item($key, $package.DefaultAssigns.Get_Item($key))
                }
            }
        }
        else
        {
            $hstwb.Assigns.Set_Item($package.Package.Name, $package.DefaultAssigns) 
        }
    }

    # remove assigns for packages, that aren't going to be installed
    $assignSectionNames = $hstwb.Assigns.keys | Where-Object { $_ -notmatch 'Global' }
    foreach ($assignSectionName in $assignSectionNames)
    {
        if (!$packageNames.Contains($assignSectionName))
        {
            $hstwb.Assigns.Remove($assignSectionName)
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
    # fail, if ImageDir directory doesn't exist for installer modes other than 'BuildPackageInstallation'
    if ($settings.Installer.Mode -notmatch 'BuildPackageInstallation' -and $settings.Image.ImageDir -match '^.+$' -and !(test-path -path $settings.Image.ImageDir))
    {
        Write-Host "Error: ImageDir parameter doesn't exist in settings file or directory doesn't exist!" -ForegroundColor "Red"
        return $false
    }


    # fail, if InstallWorkbench parameter doesn't exist in settings file or is not valid
    if (!$settings.Workbench.InstallWorkbench -or $settings.Workbench.InstallWorkbench -notmatch '(Yes|No)')
    {
        Write-Host "Error: InstallWorkbench parameter doesn't exist in settings file or is not valid!" -ForegroundColor "Red"
        return $false
    }


    # fail, if WorkbenchAdfPath parameter doesn't exist in settings file or directory doesn't exist
    if (!$settings.Workbench.WorkbenchAdfDir -or ($settings.Workbench.WorkbenchAdfDir -match '^.+$' -and !(test-path -path $settings.Workbench.WorkbenchAdfDir)))
    {
        Write-Host "Error: WorkbenchAdfPath parameter doesn't exist in settings file or directory doesn't exist!" -ForegroundColor "Red"
        return $false
    }


    # fail, if WorkbenchAdfSet parameter doesn't exist settings file or it's not defined
    if (!$settings.Workbench.WorkbenchAdfSet -or $settings.Workbench.WorkbenchAdfSet -eq '')
    {
        Write-Host "Error: WorkbenchAdfSet parameter doesn't exist in settings file or it's not defined!" -ForegroundColor "Red"
        return $false
    }


    # fail, if InstallKickstart parameter doesn't exist in settings file or is not valid
    if (!$settings.Kickstart.InstallKickstart -or $settings.Kickstart.InstallKickstart -notmatch '(Yes|No)')
    {
        Write-Host "Error: InstallKickstart parameter doesn't exist in settings file or is not valid!" -ForegroundColor "Red"
        return $false
    }


    # fail, if KickstartRomPath parameter doesn't exist in settings file or directory doesn't exist
    if (!$settings.Kickstart.KickstartRomDir -or ($settings.Kickstart.KickstartRomDir -match '^.+$' -and !(test-path -path $settings.Kickstart.KickstartRomDir)))
    {
        Write-Host "Error: KickstartRomPath parameter doesn't exist in settings file or directory doesn't exist!" -ForegroundColor "Red"
        return $false
    }


    # fail, if KickstartRomSet parameter doesn't exist in settings file or it's not defined
    if (!$settings.Kickstart.KickstartRomSet -or $settings.Kickstart.KickstartRomSet -eq '')
    {
        Write-Host "Error: KickstartRomSet parameter doesn't exist in settings file or it's not defined!" -ForegroundColor "Red"
        return $false
    }


    # fail, if EmulatorFile parameter doesn't exist in settings file or file doesn't exist
    if (!$settings.Emulator.EmulatorFile -or ($settings.Emulator.EmulatorFile -match '^.+$' -and !(test-path -path $settings.Emulator.EmulatorFile)))
    {
        Write-Host "Error: EmulatorFile parameter doesn't exist in settings file or file doesn't exist!" -ForegroundColor "Red"
        return $false
    }
    

    # fail, if Mode parameter doesn't exist in settings file or is not valid
    if (!$settings.Installer.Mode -or $settings.Installer.Mode -notmatch '(Install|BuildSelfInstall|BuildPackageInstallation|Test)')
    {
        Write-Host "Error: Mode parameter doesn't exist in settings file or is not valid!" -ForegroundColor "Red"
        return $false
    }


    return $true
}