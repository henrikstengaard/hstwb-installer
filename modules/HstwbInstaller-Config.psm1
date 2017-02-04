# HstWB Installer Config Module
# -----------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-01-27
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

    [System.IO.File]::WriteAllText($iniFile, $iniLines -join [System.Environment]::NewLine)
}


# default settings
function DefaultSettings($settings)
{
    $settings.Image = @{}
    $settings.Workbench = @{}
    $settings.Kickstart = @{}
    $settings.Winuae = @{}
    $settings.Packages = @{}
    $settings.Installer = @{}

    $settings.Workbench.InstallWorkbench = 'Yes'
    $settings.Kickstart.InstallKickstart = 'Yes'
    $settings.Packages.InstallPackages = ''
    $settings.Installer.Mode = 'Install'
    
    # use cloanto amiga forever data directory, if present
    $amigaForeverDataPath = ${Env:AMIGAFOREVERDATA}
    if ($amigaForeverDataPath)
    {
        $workbenchAdfPath = [System.IO.Path]::Combine($amigaForeverDataPath, "Shared\adf")
        if (test-path -path $workbenchAdfPath)
        {
            $settings.Workbench.WorkbenchAdfPath = $workbenchAdfPath
            $settings.Workbench.WorkbenchAdfSet = 'Workbench 3.1 Cloanto Amiga Forever 2016'
        }

        $kickstartRomPath = [System.IO.Path]::Combine($amigaForeverDataPath, "Shared\rom")
        if (test-path -path $kickstartRomPath)
        {
            $settings.Kickstart.KickstartRomPath = $kickstartRomPath
            $settings.Kickstart.KickstartRomSet = 'Kickstart Cloanto Amiga Forever 2016'
        }
    }

    # use winuae in program files x86, if present
    $winuaePath = "${Env:ProgramFiles(x86)}\WinUAE\winuae.exe"
    if (test-path -path $winuaePath)
    {
        $settings.Winuae.WinuaePath = $winuaePath
    }
}


# default assigns
function DefaultAssigns($assigns)
{
    $defaultHstwbInstallerAssigns = @{ "SystemDir" = "DH0:"; "HstWBInstallerDir" = "DH1:HstWBInstaller" }
    $assigns.Set_Item("HstWB Installer", $defaultHstwbInstallerAssigns)
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

        # get package filename
        $packageFileName = $packageFile.Name.ToLower() -replace '\.zip$'

        # add package ini to packages
        $packages.Set_Item($packageFileName, $packageIni)
    }

    return $packages
}


# update packages
function UpdatePackages($packages, $settings)
{
    # get install packages defined in settings packages section
    $packageFileNames = @()
    if ($settings.Packages.InstallPackages -and $settings.Packages.InstallPackages -ne '')
    {
        $packageFileNames += $settings.Packages.InstallPackages.ToLower() -split ',' | Where-Object { $_ }
    }

    # get packages that exist in packages path
    $existingPackages = New-Object System.Collections.ArrayList

    # remove packages, if they don't exist
    $packageFileNames | ForEach-Object { if ($packages.ContainsKey($_)) { [void]$existingPackages.Add($_) } }

    # update install packages with packages that exist
    $settings.Packages.InstallPackages = [string]::Join(',', $existingPackages.ToArray())
}


# update assigns
function UpdateAssigns($packages, $settings, $assigns)
{  
    # get install packages defined in settings packages section
    $packageFileNames = @()
    if ($settings.Packages.InstallPackages -and $settings.Packages.InstallPackages -ne '')
    {
        $packageFileNames += $settings.Packages.InstallPackages -split ',' | Where-Object { $_ }
    }

    $packageNames = @()

    # 
    foreach ($packageFileName in $packageFileNames)
    {
        $packageFileName = $packageFileName.ToLower()


        if (!$packages.ContainsKey($packageFileName))
        {
            continue
        }

        $package = $packages.Get_Item($packageFileName)

        $packageNames += $package.Package.Name

        if (!$package.DefaultAssigns)
        {
            continue
        }

        # add new package assigns, if package exists. otherwise add all package assigns
        if ($assigns.ContainsKey($package.Package.Name))
        {
            $packageAssigns = $assigns.Get_Item($package.Package.Name)

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
            $assigns.Set_Item($package.Package.Name, $package.DefaultAssigns) 
        }
    }

    # remove assigns for packages, that aren't going to be installed
    $assingSectionNames = $assigns.keys | Where-Object { $_ -notmatch 'hstwb installer' }
    foreach ($assingSectionName in $assingSectionNames)
    {
        if (!$packageNames.Contains($assingSectionName))
        {
            $assigns.Remove($assingSectionName)
        }
    }
}


# validate assigns
function ValidateAssigns($assigns)
{
    # return false, if assigns doesn't contain hstwb intaller section
    if (!$assigns.ContainsKey("HstWB Installer"))
    {
        Write-Host "Error: Assigns doesn't contain 'HstWB Installer' section!" -ForegroundColor "Red"
        return $false
    }


    $hstwbInstallerAssigns = $assigns.Get_Item("HstWB Installer")

    # get assign names from hstwb installer section
    $hstwbInstallerAssignNames = @()
    $hstwbInstallerAssignNames += $hstwbInstallerAssigns.keys | ForEach-Object { $_.ToUpper() } 


    # check hstwb installer assign names contain 'SYSTEMDIR', 'HSTWBINSTALLERDIR' assign name
    foreach ($assignName in @("SYSTEMDIR", "HSTWBINSTALLERDIR"))
    {
        # return false, if hstwb installer section doesn't contain assign name
        if (!($hstwbInstallerAssignNames -contains $assignName))
        {
            Write-Host "Error: Assign section 'HstWB Installer' doesn't contain assign name '$assignName'!" -ForegroundColor "Red"
            return $false
        }
    }


    # validate assign sections other than hstwb installer
    foreach ($assignSectionName in ($assigns.keys | Where-Object { $_ -notmatch 'HstWB Installer' }))
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
    # fail, if ImageDir directory doesn't exist
    if ($settings.Image.ImageDir -match '^.+$' -and !(test-path -path $settings.Image.ImageDir))
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
    if (!$settings.Workbench.WorkbenchAdfPath -or !(test-path -path $settings.Workbench.WorkbenchAdfPath))
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
    if (!$settings.Kickstart.KickstartRomPath -or !(test-path -path $settings.Kickstart.KickstartRomPath))
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


    # fail, if WinuaePath parameter doesn't exist in settings file or file doesn't exist
    if (!$settings.Winuae.WinuaePath -or !(test-path -path $settings.Winuae.WinuaePath))
    {
        Write-Host "Error: WinuaePath parameter doesn't exist in settings file or file doesn't exist!" -ForegroundColor "Red"
        return $false
    }
    

    # fail, if Mode parameter doesn't exist in settings file or is not valid
    if (!$settings.Installer.Mode -or $settings.Installer.Mode -notmatch '(Install|BuildSelfInstall|Test)')
    {
        Write-Host "Error: Mode parameter doesn't exist in settings file or is not valid!" -ForegroundColor "Red"
        return $false
    }


    return $true
}


# export
export-modulemember -function ReadIniFile
export-modulemember -function ReadIniText
export-modulemember -function WriteIniFile
export-modulemember -function DefaultSettings
export-modulemember -function DefaultAssigns
export-modulemember -function ReadPackages
export-modulemember -function UpdatePackages
export-modulemember -function UpdateAssigns
export-modulemember -function ValidateAssigns
export-modulemember -function ValidateSettings