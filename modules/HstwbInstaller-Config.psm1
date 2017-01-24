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
function DefaultSettings()
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
function DefaultAssigns()
{
    $defaultHstwbInstallerAssigns = @{ "SystemDir" = "DH0:"; "HstWBInstallerDir" = "DH1:HstWBInstaller" }
    $assigns.Set_Item("HstWB Installer", $defaultHstwbInstallerAssigns)
}


# read packages
function ReadPackages()
{
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
}


# update packages
function UpdatePackages()
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
function UpdateAssigns()
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


# validate settings
function ValidateSettings()
{
    # fail, if HdfImagePath parameter doesn't exist in settings file or file doesn't exist
    if (!$settings.Image.HdfImagePath -or !(test-path -path $settings.Image.HdfImagePath))
    {
        Write-Host "Error: HdfImagePath parameter doesn't exist in settings file or file doesn't exist!" -ForegroundColor "Red"
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
    if (!$settings.Installer.Mode -or $settings.Installer.Mode -notmatch '(Install|Test)')
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
export-modulemember -function ValidateSettings