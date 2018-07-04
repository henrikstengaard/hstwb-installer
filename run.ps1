# HstWB Installer Run
# -------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-07-04
#
# A powershell script to run HstWB Installer automating installation of workbench, kickstart roms and packages to an Amiga HDF file.


Param(
	[Parameter(Mandatory=$false)]
	[string]$settingsDir
)


Import-Module (Resolve-Path('modules\version.psm1')) -Force
Import-Module (Resolve-Path('modules\config.psm1')) -Force
Import-Module (Resolve-Path('modules\dialog.psm1')) -Force
Import-Module (Resolve-Path('modules\data.psm1')) -Force


Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Windows.Forms


# show folder browser dialog using WinForms
function FolderBrowserDialog($title, $directory, $showNewFolderButton)
{
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserDialog.Description = $title
    $folderBrowserDialog.SelectedPath = $directory
    $folderBrowserDialog.ShowNewFolderButton = $showNewFolderButton
    $result = $folderBrowserDialog.ShowDialog()

    if($result -ne "OK")
    {
        return $null
    }    

    return $folderBrowserDialog.SelectedPath    
}


# confirm dialog
function ConfirmDialog($title, $message)
{
    $result = [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OKCancel)

    if($result -eq "OK")
    {
        return $true
    }

    return $false
}


# write text file encoded for Amiga
function WriteAmigaTextLines($path, $lines)
{
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
	$utf8 = [System.Text.Encoding]::UTF8;

	$amigaTextBytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $utf8.GetBytes($lines -join "`n"))
	[System.IO.File]::WriteAllText($path, $iso88591.GetString($amigaTextBytes), $iso88591)
}


# update version amiga text file
function UpdateVersionAmigaTextFile($amigaTextFile, $version)
{
    $iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
    $lines = @()
    $lines += [System.IO.File]::ReadAllLines($amigaTextFile, $iso88591)
    
    $updated = $false

    for ($i = 0; $i -lt $lines.Count; $i++)
    {
        if ($lines[$i] -cmatch "[`$VersionText]")
        {
            $updated = $true
            $lines[$i] = $lines[$i].Replace("[`$VersionText]", $version)
        }
        
        if ($lines[$i] -cmatch "[`$VersionDashes]")
        {
            $updated = $true
            $lines[$i] = $lines[$i].Replace("[`$VersionDashes]", ("-" * $version.Length))
        }
    }

    if ($updated)
    {
        WriteAmigaTextLines $amigaTextFile $lines
    }
}


# start process
function StartProcess($fileName, $arguments, $workingDirectory)
{
	# start process info
	$processInfo = New-Object System.Diagnostics.ProcessStartInfo
	$processInfo.FileName = $fileName
	$processInfo.RedirectStandardError = $true
	$processInfo.RedirectStandardOutput = $true
	$processInfo.UseShellExecute = $false
	$processInfo.Arguments = $arguments
	$processInfo.WorkingDirectory = $workingDirectory

	# run process
	$process = New-Object System.Diagnostics.Process
	$process.StartInfo = $processInfo
	$process.Start() | Out-Null
    $process.BeginErrorReadLine()
    $process.BeginOutputReadLine()
	$process.WaitForExit()

	if ($process.ExitCode -ne 0)
	{
        $standardOutput = $process.StandardOutput.ReadToEnd()
        $standardError = $process.StandardError.ReadToEnd()

		if ($standardOutput)
		{
			Write-Error ("StandardOutput: " + $standardOutput)
		}

		if ($standardError)
		{
			Write-Error ("StandardError: " + $standardError)
		}
	}

	return $process.ExitCode	
}


# find packages to install
function FindPackagesToInstall($hstwb)
{
    # get install packages
    $installPackageNames = @{}
    foreach($installPackageKey in ($hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' }))
    {
        $installPackageNames.Set_Item($hstwb.Settings.Packages.Get_Item($installPackageKey.ToLower()), $true)
    }

    $packageNames = SortPackageNames $hstwb

    $installPackages = @()
    $installPackages += $packageNames | Where-Object { $installPackageNames[$_] }

    return $installPackages
}


# extract packages
function ExtractPackages($hstwb, $packageNames, $packagesDir)
{
    foreach($packageName in $packageNames)
    {
        # get package
        $package = $hstwb.Packages[$packageName]

        if (!$package)
        {
            continue
        }

        # extract package file to package directory
        $packageDir = [System.IO.Path]::Combine($packagesDir, $package.Id)
        Write-Host ("Extracting '{0}' package to directory '{1}'" -f $package.Name, $packageDir)

        # delete existing package directory, if it exists
        if(test-path -path $packageDir)
        {
            remove-item -Path $packageDir -Recurse -Force
        }

        # create package directory
        mkdir $packageDir | Out-Null

        # extract package to package directory
        [System.IO.Compression.ZipFile]::ExtractToDirectory($package.PackageFile, $packageDir)
    }
}


# install hstwb installer fs-uae theme
function InstallHstwbInstallerFsUaeTheme($hstwb)
{
    $hstwbInstallerFsUaeThemeDir = Join-Path $hstwb.Paths.FsUaePath -ChildPath "theme\\hstwb-installer"

    # fail, if hstwb installer fs-uae theme directory doesn't exist
    if (!(Test-Path -Path $hstwbInstallerFsUaeThemeDir))
    {
        throw ("HstWB Installer FS-UAE theme '{0}' doesn't exist" -f $hstwbInstallerFsUaeThemeDir)
    }

    # fs-uae theme directory
    $fsuaeThemeDir = Join-Path ([System.Environment]::GetFolderPath('MyDocuments')) -ChildPath 'FS-UAE\\Themes\\hstwb-installer'
    
    # return, if fs-uae themes directory exist
    if (Test-Path -Path $fsuaeThemeDir)
    {
        return
    }

    # create fs-uae themes directory, if it doesn't exist
    mkdir -Path $fsuaeThemeDir | Out-Null
    
    # copy hstwb installer fs-uae theme directory to fs-uae theme directory
    Copy-Item -Path "$hstwbInstallerFsUaeThemeDir\*" $fsuaeThemeDir -force
}


# build assign hstwb installer script lines
function BuildAssignHstwbInstallerScriptLines($hstwb, $createDirectories)
{
    $globalAssigns = $hstwb.Assigns.Get_Item('Global')

    $assignHstwbInstallerScriptLines = @()

    foreach ($assignName in $globalAssigns.keys)
    {
        # skip, if assign name is 'HstWBInstallerDir' and installer mode is build package installation
        if ($assignName -match 'HstWBInstallerDir' -and $hstwb.Settings.Installer.Mode -match "^(Install|BuildPackageInstallation)$")
        {
            continue
        }

        # get assign path and drive
        $assignDir = $globalAssigns.Get_Item($assignName)
        $assignDrive = $assignDir -replace '^([^:]+:).*', '$1'

        # add package assign lines
        $assignHstwbInstallerScriptLines += "; Add assign for '$assignName' to '$assignDir'"
        $assignHstwbInstallerScriptLines += "Assign >NIL: EXISTS ""$assignDrive"""
        $assignHstwbInstallerScriptLines += "IF WARN"
        $assignHstwbInstallerScriptLines += "  echo ""Error: Drive '$assignDrive' doesn't exist for assign '$assignDir'!"""
        $assignHstwbInstallerScriptLines += "  ask ""Press ENTER to exit"""
        $assignHstwbInstallerScriptLines += "  QUIT 5"
        $assignHstwbInstallerScriptLines += "ELSE"

        # create directory for assignpath or check if path exist
        if ($createDirectories)
        {
            # add makedir dir each directory in assign path
            $dirs = @()
            $dirs += ($assignDir -replace '^[^:]+:(.*)', '$1') -split '/' | Where-Object { $_ }
            $currentAssignPath = $assignDrive
            foreach ($dir in $dirs)
            {
                if ($currentAssignPath -notmatch ':$')
                {
                    $currentAssignPath += '/'
                }
                $currentAssignPath += $dir
                $assignHstwbInstallerScriptLines += ("  IF NOT EXISTS """ + $currentAssignPath + """")
                $assignHstwbInstallerScriptLines += ("    MakeDir >NIL: """ + $currentAssignPath + """")
                $assignHstwbInstallerScriptLines += ("  ENDIF")
            }

            $assignHstwbInstallerScriptLines += ("  Assign " + $assignName + ": """ + $assignDir + """")
        }
        else
        {
            $assignHstwbInstallerScriptLines += ("  IF EXISTS """ + $assignDir + """")
            $assignHstwbInstallerScriptLines += ("    Assign " + $assignName + ": """ + $assignDir + """")
            $assignHstwbInstallerScriptLines += "  ELSE"
            $assignHstwbInstallerScriptLines += "    echo ""Error: Path '$assignDir' doesn't exist for assign!"""
            $assignHstwbInstallerScriptLines += "    ask ""Press ENTER to exit"""
            $assignHstwbInstallerScriptLines += "    QUIT 5"
            $assignHstwbInstallerScriptLines += "  ENDIF"
        }

        $assignHstwbInstallerScriptLines += "ENDIF"
    }

    return $assignHstwbInstallerScriptLines
}


# build assign dir script lines
function BuildAssignDirScriptLines($assignId, $assignDir)
{
    $assignDirScriptLines = @()
    $assignDirScriptLines += ("IF EXISTS ""T:{0}""" -f $assignId)
    $assignDirScriptLines += ("  Set assigndir ""``type ""T:{0}""``""" -f $assignId)
    $assignDirScriptLines += "ELSE"
    $assignDirScriptLines += ("  Set assigndir ""{0}""" -f $assignDir)
    $assignDirScriptLines += "ENDIF"

    return $assignDirScriptLines
}


# build add assign script lines
function BuildAddAssignScriptLines($assignId, $assignName, $assignDir)
{
    $addAssignScriptLines = @()
    $addAssignScriptLines += ("; Add assign and set variable for assign '{0}'" -f $assignName)
    $addAssignScriptLines += BuildAssignDirScriptLines $assignId $assignDir
    $addAssignScriptLines += "IF NOT EXISTS ""`$assigndir"""
    $addAssignScriptLines += "  MakePath ""`$assigndir"""
    $addAssignScriptLines += "ENDIF"
    $addAssignScriptLines += ("echo ""Add assign '`$assigndir' = '{0}'"" >>SYS:hstwb-installer.log" -f $assignName)
    $addAssignScriptLines += ("SetEnv {0} ""`$assigndir""" -f $assignName)
    $addAssignScriptLines += ("Assign {0}: ""`$assigndir""" -f $assignName)
    
    return $addAssignScriptLines
}


# build remove assign script lines
function BuildRemoveAssignScriptLines($assignId, $assignName, $assignDir)
{
    $removeAssignScriptLines = @()
    $removeAssignScriptLines += ("; Remove assign and unset variable for assign '{0}'" -f $assignName)
    $removeAssignScriptLines += BuildAssignDirScriptLines $assignId $assignDir
    $removeAssignScriptLines += ("echo ""Remove assign '`$assigndir' = '{0}'"" >>SYS:hstwb-installer.log" -f $assignName)
    $removeAssignScriptLines += ("Assign {0}: ""`$assigndir"" REMOVE" -f $assignName)
    $removeAssignScriptLines += ("IF EXISTS ""ENV:{0}""" -f $assignName)
    $removeAssignScriptLines += ("  delete >NIL: ""ENV:{0}""" -f $assignName)
    $removeAssignScriptLines += "ENDIF"

    return $removeAssignScriptLines
}


# build install package script lines
function BuildInstallPackageScriptLines($hstwb, $packageNames)
{
    $globalAssigns = $hstwb.Assigns.Get_Item('Global')

    $installPackageScripts = @()
 
    foreach ($packageName in $packageNames)
    {
        # get package
        $package = $hstwb.Packages[$packageName.ToLower()]

        # add package installation lines to install packages script
        $installPackageLines = @()
        $installPackageLines += ("; Install package '{0}'" -f $package.FullName)
        $installPackageLines += "echo """""
        $installPackageLines += ("echo ""*e[1mInstalling package '{0}'*e[0m""" -f $package.FullName)

        $removePackageAssignLines = @()

        # get package assign names
        $packageAssignNames = @()
        if ($package.Assigns)
        {
            $packageAssignNames += $package.Assigns | Where-Object { $_.Path } | ForEach-Object { $_.Name }
        }

        # package assigns
        if ($hstwb.Assigns.ContainsKey($package.Name))
        {
            $packageAssigns = $hstwb.Assigns[$package.Name]
        }
        else
        {
            $packageAssigns = @{}
        }

        # build and and remove package assigns
        foreach ($assignName in $packageAssignNames)
        {
            # get matching global and package assign name (case insensitive)
            $matchingGlobalAssignName = $globalAssigns.Keys | Where-Object { $_ -like $assignName } | Select-Object -First 1
            $matchingPackageAssignName = $packageAssigns.Keys | Where-Object { $_ -like $assignName } | Select-Object -First 1

            # fail, if package assign name doesn't exist in either global or package assigns
            if (!$matchingGlobalAssignName -and !$matchingPackageAssignName)
            {
                Fail $hstwb ("Error: Package '" + $package.Name + "' doesn't have assign defined for '$assignName' in either global or package assigns!")
            }

            # skip, if package assign name is global
            if ($matchingGlobalAssignName)
            {
                continue
            }

            # get assign path and drive
            $assignId = CalculateMd5FromText (("{0}.{1}" -f $package.Name, $assignName).ToLower())
            $assignDir = $packageAssigns.Get_Item($matchingPackageAssignName)

            # append add package assign
            $installPackageLines += ""
            $installPackageLines += BuildAddAssignScriptLines $assignId $assignName $assignDir

            # append ini file set for package assign, if installer mode is build self install or build package installation
            if ($hstwb.Settings.Installer.Mode -eq "BuildSelfInstall" -or $hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation")
            {
                $installPackageLines += 'execute INSTALLDIR:S/IniFileSet "{0}" "{1}" "{2}" "$assigndir"' -f 'SYSTEMDIR:Prefs/HstWB-Installer/Packages/Assigns.ini', $package.Name, $assignName
            }

            # append remove package assign
            $removePackageAssignLines += BuildRemoveAssignScriptLines $assignId $assignName $assignDir
        }


        # add package dir assign, execute package install script and remove package dir assign
        $installPackageLines += ""
        $installPackageLines += "; Add package dir assign"
        $installPackageLines += ("Assign PACKAGEDIR: ""PACKAGESDIR:{0}""" -f $package.Id)
        $installPackageLines += ""
        $installPackageLines += "; Execute package install script"
        $installPackageLines += ("echo ""Running package '{0}' install script"" >>SYS:hstwb-installer.log" -f $package.Name)
        $installPackageLines += "execute ""PACKAGEDIR:Install"""
        $installPackageLines += ""
        $installPackageLines += "; Remove package dir assign"
        $installPackageLines += ("Assign PACKAGEDIR: ""PACKAGESDIR:{0}"" REMOVE" -f $package.Id)


        # add remove package assign lines, if there are any
        if ($removePackageAssignLines.Count -gt 0)
        {
            $installPackageLines += ""
            $installPackageLines += $removePackageAssignLines
        }

        $installPackageLines += "echo ""Done"""
        
        $installPackageScripts += @{ "Lines" = $installPackageLines; "Package" = $package }
    }

    return $installPackageScripts
}


# build reset assigns script lines
function BuildResetAssignsScriptLines($hstwb)
{
    $resetAssignsScriptLines = @()

    # reset assigns settings and get existing assign value, if present in prefs assigns ini file
    foreach ($assignSectionName in $hstwb.Assigns.keys)
    {
        $sectionAssigns = $hstwb.Assigns[$assignSectionName]

        foreach ($assignName in ($sectionAssigns.keys | Sort-Object | Where-Object { $_ -notlike 'HstWBInstallerDir' }))
        {
            $assignId = CalculateMd5FromText (("{0}.{1}" -f $assignSectionName, $assignName).ToLower())

            $resetAssignsScriptLines += ''
            $resetAssignsScriptLines += ("; Reset assign path setting for package '{0}' and assign '{1}'" -f $assignSectionName, $assignName)
            $resetAssignsScriptLines += '; Get assign path from ini'
            $resetAssignsScriptLines += 'set assigndir ""'
            $resetAssignsScriptLines += 'set assigndir "`execute INSTALLDIR:S/IniFileGet "{0}" "{1}" "{2}"`"' -f 'SYSTEMDIR:Prefs/HstWB-Installer/Packages/Assigns.ini', $assignSectionName, $assignName
            $resetAssignsScriptLines += ''
            $resetAssignsScriptLines += '; Create assign path setting, if assign path exists in ini. Otherwise delete assign path setting'
            $resetAssignsScriptLines += 'IF NOT "$assigndir" eq ""'
            $resetAssignsScriptLines += ('  echo "$assigndir" >"T:{0}"' -f $assignId)
            $resetAssignsScriptLines += 'ELSE'
            $resetAssignsScriptLines += ('  IF EXISTS "T:{0}"' -f $assignId)
            $resetAssignsScriptLines += ('    delete >NIL: "T:{0}"' -f $assignId)
            $resetAssignsScriptLines += '  ENDIF'
            $resetAssignsScriptLines += 'ENDIF'
        }
    }
    
    return $resetAssignsScriptLines
}


# build default assigns script lines
function BuildDefaultAssignsScriptLines($hstwb)
{
    $defaultAssignsScriptLines = @()

    # default assigns settings
    foreach ($assignSectionName in $hstwb.Assigns.keys)
    {
        $sectionAssigns = $hstwb.Assigns[$assignSectionName]

        foreach ($assignName in ($sectionAssigns.keys | Sort-Object | Where-Object { $_ -notlike 'HstWBInstallerDir' }))
        {
            $assignId = CalculateMd5FromText (("{0}.{1}" -f $assignSectionName, $assignName).ToLower())

            $defaultAssignsScriptLines += ''
            $defaultAssignsScriptLines += ("; Default assign path setting for package '{0}' and assign '{1}'" -f $assignSectionName, $assignName)
            $defaultAssignsScriptLines += ('IF EXISTS "T:{0}"' -f $assignId)
            $defaultAssignsScriptLines += ('  delete >NIL: "T:{0}"' -f $assignId)
            $defaultAssignsScriptLines += 'ENDIF'
        }
    }

    return $defaultAssignsScriptLines
}


# build install packages script lines
function BuildInstallPackagesScriptLines($hstwb, $installPackages)
{
    $installPackagesScriptLines = @()
    $installPackagesScriptLines += ""
    $installPackagesScriptLines += "echo """" >>SYS:hstwb-installer.log"

    # append skip reset settings or install packages depending on installer mode
    if (($hstwb.Settings.Installer.Mode -eq "BuildSelfInstall" -or $hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation") -and $installPackages.Count -gt 0)
    {
        $installPackagesScriptLines += "SKIP resetpackages"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += Get-Content (Join-Path $hstwb.Paths.AmigaPath -ChildPath "packages\S\SelectAssignDir")
    }
    
    # globl assigns
    $globalAssigns = $hstwb.Assigns.Get_Item('Global')

    # build global package assigns
    $addGlobalAssignScriptLines = @()
    $removeGlobalAssignScriptLines = @()
    foreach ($assignName in ($globalAssigns.keys | Sort-Object | Where-Object { $_ -notlike 'HstWBInstallerDir' }))
    {
        $assignId = CalculateMd5FromText (("{0}.{1}" -f 'Global', $assignName).ToLower())
        $assignDir = $globalAssigns.Get_Item($assignName)

        $addGlobalAssignScriptLines += BuildAddAssignScriptLines $assignId $assignName.ToUpper() $assignDir

        # append ini file set for global assign, if installer mode is build self install or build package installation
        if ($hstwb.Settings.Installer.Mode -eq "BuildSelfInstall" -or $hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation")
        {
            $addGlobalAssignScriptLines += 'execute INSTALLDIR:S/IniFileSet "{0}" "{1}" "{2}" "$assigndir"' -f 'SYSTEMDIR:Prefs/HstWB-Installer/Packages/Assigns.ini', 'Global', $assignName
        }
        
        $removeGlobalAssignScriptLines += BuildRemoveAssignScriptLines $assignId $assignName.ToUpper() $assignDir
    }


    # build install package script lines
    $installPackageScripts = @()
    $installPackageScripts += BuildInstallPackageScriptLines $hstwb $installPackages

    if (($hstwb.Settings.Installer.Mode -eq "BuildSelfInstall" -or $hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation") -and $installPackages.Count -gt 0)
    {
        $dependencyPackageNamesIndex = @{}

        foreach ($packageName in $hstwb.Packages.Keys)
        {
            $package = $hstwb.Packages[$packageName]

            if (!$package.Dependencies)
            {
                continue
            }

            foreach($dependencyPackageName in ($package.Dependencies | ForEach-Object { $_.Name.ToLower() }))
            {
                if ($dependencyPackageNamesIndex.ContainsKey($dependencyPackageName))
                {
                    $dependencyPackageNames = $dependencyPackageNamesIndex.Get_Item($dependencyPackageName)
                }
                else
                {
                    $dependencyPackageNames = @()
                }

                $dependencyPackageNames += $packageName

                $dependencyPackageNamesIndex.Set_Item($dependencyPackageName, $dependencyPackageNames)
            }
        }

        $resetPackagesScriptLines = @()
        $selectAllPackagesScriptLines = @()
        $deselectAllPackagesScriptLines = @()

        # build reset, select all and deselect all packages
        foreach ($installPackageScript in $installPackageScripts)
        {
            $resetPackagesScriptLines += ''
            $resetPackagesScriptLines += ("; Reset package '{0}'" -f $installPackageScript.Package.FullName)
            $resetPackagesScriptLines += ("IF EXISTS ""T:{0}""" -f $installPackageScript.Package.Id)
            $resetPackagesScriptLines += ("  delete >NIL: ""T:{0}""" -f $installPackageScript.Package.Id)
            $resetPackagesScriptLines += "ENDIF"

            $selectAllPackagesScriptLines += ''
            $selectAllPackagesScriptLines += ("; Select package '{0}'" -f $installPackageScript.Package.FullName)
            $selectAllPackagesScriptLines += ("IF NOT EXISTS ""T:{0}""" -f $installPackageScript.Package.Id)
            $selectAllPackagesScriptLines += ("  echo """" NOLINE >""T:{0}""" -f $installPackageScript.Package.Id)
            $selectAllPackagesScriptLines += "ENDIF"

            $deselectAllPackagesScriptLines += ''
            $deselectAllPackagesScriptLines += ("; Deselect package '{0}'" -f $installPackageScript.Package.FullName)
            $deselectAllPackagesScriptLines += ("IF EXISTS ""T:{0}""" -f $installPackageScript.Package.Id)
            $deselectAllPackagesScriptLines += ("  delete >NIL: ""T:{0}""" -f $installPackageScript.Package.Id)
            $deselectAllPackagesScriptLines += "ENDIF"
        }

        # add reset packages and assigns script lines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; Reset packages'
        $installPackagesScriptLines += '; --------------'
        $installPackagesScriptLines += 'LAB resetpackages'
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += $resetPackagesScriptLines
        $installPackagesScriptLines += BuildResetAssignsScriptLines $hstwb
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP installpackagesmenu'

        # reset assigns
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; Reset assigns'
        $installPackagesScriptLines += '; -------------'
        $installPackagesScriptLines += 'LAB resetassigns'
        $installPackagesScriptLines += BuildResetAssignsScriptLines $hstwb
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP editassignsmenu'

        # default assigns
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; Default assigns'
        $installPackagesScriptLines += '; ---------------'
        $installPackagesScriptLines += 'LAB defaultassigns'
        $installPackagesScriptLines += BuildDefaultAssignsScriptLines $hstwb
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP editassignsmenu'

        # add select all packages script lines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; Select all packages'
        $installPackagesScriptLines += '; -------------------'
        $installPackagesScriptLines += 'LAB selectallpackages'
        $installPackagesScriptLines += $selectAllPackagesScriptLines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP installpackagesmenu'

        # add deselect all packages script lines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; Deselect all packages'
        $installPackagesScriptLines += '; ---------------------'
        $installPackagesScriptLines += 'LAB deselectallpackages'
        $installPackagesScriptLines += $deselectAllPackagesScriptLines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP installpackagesmenu'

        # install packages menu label
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += "; Install packages menu"
        $installPackagesScriptLines += "; ---------------------"
        $installPackagesScriptLines += "LAB installpackagesmenu"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "echo """" NOLINE >T:installpackagesmenu"

        # add package options to menu
        foreach ($installPackageScript in $installPackageScripts)
        {
            $installPackagesScriptLines += ("IF EXISTS ""T:{0}""" -f $installPackageScript.Package.Id)
            $installPackagesScriptLines += "  echo ""Install"" NOLINE >>T:installpackagesmenu"
            $installPackagesScriptLines += "ELSE"
            $installPackagesScriptLines += "  echo ""Skip   "" NOLINE >>T:installpackagesmenu"
            $installPackagesScriptLines += "ENDIF"
            $hasDependenciesIndicator = if ($installPackageScript.Package.Dependencies.Count -gt 0) { ' (**)' } else { '' }
            $installPackagesScriptLines += ("echo "" : {0}{1}"" >>T:installpackagesmenu" -f $installPackageScript.Package.FullName, $hasDependenciesIndicator)
        }

        # add install package option and show install packages menu
        $installPackagesScriptLines += "echo ""============================================================"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Install all packages"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Skip all packages"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""View Readme"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Edit assigns"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Start package installation"" >>T:installpackagesmenu"

        if ($hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation")
        {
            $installPackagesScriptLines += "echo ""Quit"" >>T:installpackagesmenu"
        }
        else
        {
            $installPackagesScriptLines += "echo ""Skip package installation"" >>T:installpackagesmenu"
        }

        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "set installpackagesmenu """""
        $installPackagesScriptLines += "set installpackagesmenu ""``RequestList TITLE=""Package installation"" LISTFILE=""T:installpackagesmenu"" WIDTH=640 LINES=24``"""
        $installPackagesScriptLines += "delete >NIL: T:installpackagesmenu"

        # switch package options
        for($i = 0; $i -lt $installPackageScripts.Count; $i++)
        {
            $installPackageScript = $installPackageScripts[$i]

            $installPackagesScriptLines += ""
            $installPackagesScriptLines += ("; Install package menu '{0}' option" -f $package.FullName)
            $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($i + 1) + """")
            $installPackagesScriptLines += "  ; deselect package, if it's selected. Otherwise select package"
            $installPackagesScriptLines += ("  IF EXISTS ""T:{0}""" -f $installPackageScript.Package.Id)

            $packageName = $installPackageScript.Package.Name.ToLower()

            # show package dependency warning, if package has dependencies
            if ($dependencyPackageNamesIndex.ContainsKey($packageName))
            {
                $installPackagesScriptLines += "    set showdependencywarning ""0"""
                $installPackagesScriptLines += "    set dependencypackagenames """""
                
                # list selected package names that has dependencies to package
                $dependencyPackageNames = @()
                $dependencyPackageNames += $dependencyPackageNamesIndex.Get_Item($packageName)

                foreach($dependencyPackageName in $dependencyPackageNames)
                {
                    $package = $hstwb.Packages[$dependencyPackageName]

                    # add script lines to set show dependency warning, if dependency package is selected
                    $installPackagesScriptLines += ("    ; Set show dependency warning, if package '{0}' is selected" -f $package.FullName)
                    $installPackagesScriptLines += ("    IF EXISTS ""T:{0}""" -f $package.Id)
                    $installPackagesScriptLines += "      set showdependencywarning ""1"""
                    $installPackagesScriptLines += "      IF ""`$dependencypackagenames"" EQ """""
                    $installPackagesScriptLines += ("        set dependencypackagenames ""{0}""" -f $package.Name)
                    $installPackagesScriptLines += "      ELSE"
                    $installPackagesScriptLines += ("        set dependencypackagenames ""`$dependencypackagenames, {0}""" -f $package.Name)
                    $installPackagesScriptLines += "      ENDIF"
                    $installPackagesScriptLines += "    ENDIF"
                    
                }

                # add script lines to show package dependency warning, if selected packages has dependencies to it
                $installPackagesScriptLines += "    set deselectpackage ""1"""
                $installPackagesScriptLines += "    IF `$showdependencywarning EQ 1 VAL"
                $installPackagesScriptLines += ("      set deselectpackage ``RequestChoice ""Package dependency warning"" ""Warning! Package(s) '`$dependencypackagenames' has a*Ndependency to '{0}' and skipping it*Nmay cause issues when installing packages.*N*NAre you sure you want to skip*Npackage '{0}'?"" ""Yes|No""``" -f $installPackageScript.Package.Name)
                $installPackagesScriptLines += "    ENDIF"
                $installPackagesScriptLines += "    IF `$deselectpackage EQ 1 VAL"
                $installPackagesScriptLines += ("      delete >NIL: ""T:{0}""" -f $installPackageScript.Package.Id)
                $installPackagesScriptLines += "    ENDIF"
            }
            else
            {
                # deselect package, if no other packages has dependencies to it
                $installPackagesScriptLines += ("    delete >NIL: ""T:{0}""" -f $installPackageScript.Package.Id)
            }

            $installPackagesScriptLines += "  ELSE"

            $dependencyPackageNames = GetDependencyPackageNames $hstwb $installPackageScript.Package | ForEach-Object { $_.ToLower() }

            foreach($dependencyPackageName in $dependencyPackageNames)
            {
                $dependencyPackage = $hstwb.Packages[$dependencyPackageName]

                $installPackagesScriptLines += ("    ; Select dependency package '{0}'" -f $dependencyPackage.FullName)
                $installPackagesScriptLines += ("    echo """" NOLINE >""T:{0}""" -f $dependencyPackage.Id)
            }
            
            $installPackagesScriptLines += ("    ; Select package '{0}'" -f $installPackageScript.Package.FullName)
            $installPackagesScriptLines += ("    echo """" NOLINE >""T:{0}""" -f $installPackageScript.Package.Id)
            $installPackagesScriptLines += "  ENDIF"
            $installPackagesScriptLines += "ENDIF"
        }

        # install packages option and skip back to install packages menu 
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($installPackageScripts.Count + 2) + """")
        $installPackagesScriptLines += "  SKIP BACK selectallpackages"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($installPackageScripts.Count + 3) + """")
        $installPackagesScriptLines += "  SKIP BACK deselectallpackages"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($installPackageScripts.Count + 4) + """")
        $installPackagesScriptLines += "  SKIP viewreadmemenu"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($installPackageScripts.Count + 5) + """")
        $installPackagesScriptLines += "  SKIP editassignsmenu"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($installPackageScripts.Count + 6) + """")
        $installPackagesScriptLines += "  set selectedpackagescount 0"
        foreach ($installPackageScript in $installPackageScripts)
        {
            $installPackagesScriptLines += ("  IF EXISTS ""T:{0}""" -f $installPackageScript.Package.Id)
            $installPackagesScriptLines += "    set selectedpackagescount ``eval `$selectedpackagescount + 1``"
            $installPackagesScriptLines += "  ENDIF"
        }
        $installPackagesScriptLines += "  set confirm ``RequestChoice ""Start package installation"" ""Do you want to install `$selectedpackagescount package(s)?"" ""Yes|No""``"
        $installPackagesScriptLines += "  IF ""`$confirm"" EQ ""1"""
        $installPackagesScriptLines += "    SKIP installpackages"
        $installPackagesScriptLines += "  ENDIF"
        $installPackagesScriptLines += "ENDIF"

        $installPackagesScriptLines += ""
        if ($hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation")
        {
            $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($installPackageScripts.Count + 7) + """")
            $installPackagesScriptLines += "  SKIP end"
            $installPackagesScriptLines += "ENDIF"
        }
        else
        {
            $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($installPackageScripts.Count + 7) + """")
            $installPackagesScriptLines += "  set confirm ``RequestChoice ""Skip package installation"" ""Do you want to skip package installation?"" ""Yes|No""``"
            $installPackagesScriptLines += "  IF ""`$confirm"" EQ ""1"""
            $installPackagesScriptLines += "    SKIP end"
            $installPackagesScriptLines += "  ENDIF"
            $installPackagesScriptLines += "ENDIF"
        }

        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "SKIP BACK installpackagesmenu"


        # view readme
        # -----------
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "; View readme menu"
        $installPackagesScriptLines += "; ----------------"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "LAB viewreadmemenu"
        $installPackagesScriptLines += "echo """" NOLINE >T:viewreadmemenu"

        # add package options to view readme menu
        foreach ($installPackageScript in $installPackageScripts)
        {
            $installPackagesScriptLines += ("echo ""{0}"" >>T:viewreadmemenu" -f $installPackageScript.Package.FullName)
        }

        # add back option to view readme menu
        $installPackagesScriptLines += "echo ""============================================================"" >>T:viewreadmemenu"
        $installPackagesScriptLines += "echo ""Back"" >>T:viewreadmemenu"

        $installPackagesScriptLines += "set viewreadmemenu """""
        $installPackagesScriptLines += "set viewreadmemenu ""``RequestList TITLE=""View Readme"" LISTFILE=""T:viewreadmemenu"" WIDTH=640 LINES=24``"""
        $installPackagesScriptLines += "delete >NIL: T:viewreadmemenu"

        # switch package options
        for($i = 0; $i -lt $installPackageScripts.Count; $i++)
        {
            $installPackageScript = $installPackageScripts[$i]

            $installPackagesScriptLines += ""
            $installPackagesScriptLines += ("IF ""`$viewreadmemenu"" eq """ + ($i + 1) + """")
            $installPackagesScriptLines += ("  IF EXISTS ""PACKAGESDIR:{0}/README.guide""" -f $installPackageScript.Package.Id)
            $installPackagesScriptLines += ("    cd ""PACKAGESDIR:{0}""" -f $installPackageScript.Package.Id)
            $installPackagesScriptLines += "    multiview README.guide"
            $installPackagesScriptLines += "    cd ""PACKAGESDIR:"""
            $installPackagesScriptLines += "  ELSE"
            $installPackagesScriptLines += ("    REQUESTCHOICE ""No Readme"" ""Package '{0}' doesn't have a readme file!"" ""OK"" >NIL:" -f $installPackageScript.Package.FullName)
            $installPackagesScriptLines += "  ENDIF"
            $installPackagesScriptLines += "ENDIF"
        }

        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$viewreadmemenu"" eq """ + ($installPackageScripts.Count + 2) + """")
        $installPackagesScriptLines += "  SKIP BACK installpackagesmenu"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "SKIP BACK viewreadmemenu"


        # edit assigns
        # ------------
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "; Edit assigns menu"
        $installPackagesScriptLines += ";------------------"
        $installPackagesScriptLines += "LAB editassignsmenu"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "echo """" NOLINE >T:editassignsmenu"

        $assignSectionNames = @('Global')
        $assignSectionNames += $hstwb.Assigns.keys | Where-Object { $_ -notlike 'Global' } | Sort-Object


        $editAssignsMenuOption = 0
        $editAssignsMenuOptionScriptLines = @()

        foreach($assignSectionName in $assignSectionNames)
        {
            # add menu option to show assign section name
            $installPackagesScriptLines += ("echo ""| {0} |"" >>T:editassignsmenu" -f $assignSectionName)

            # increase menu option
            $editAssignsMenuOption += 1

            # get section assigns
            $sectionAssigns = $hstwb.Assigns[$assignSectionName]

            foreach ($assignName in ($sectionAssigns.keys | Sort-Object))
            {
                # skip hstwb installer assign name for global assigns
                if ($assignSectionName -like 'Global' -and $assignName -like 'HstWBInstallerDir')
                {
                    continue
                }

                # increase menu option
                $editAssignsMenuOption++

                $assignId = CalculateMd5FromText (("{0}.{1}" -f $assignSectionName, $assignName).ToLower())
                $assignDir = $sectionAssigns[$assignName]

                # add menu option showing and editing assign witnin section
                $installPackagesScriptLines += ""
                $installPackagesScriptLines += ("IF EXISTS ""T:{0}""" -f $assignId)
                $installPackagesScriptLines += ("  echo ""{0}: = '``type ""T:{1}""``'"" >>T:editassignsmenu" -f $assignName, $assignId)
                $installPackagesScriptLines += "ELSE"
                $installPackagesScriptLines += ("  Assign >NIL: EXISTS ""{0}""" -f $assignDir)
                $installPackagesScriptLines += "  IF WARN"
                $installPackagesScriptLines += ("    echo ""{0}: = ?"" >>T:editassignsmenu" -f $assignName)
                $installPackagesScriptLines += "  ELSE"
                $installPackagesScriptLines += ("    echo ""{0}: = '{1}'"" >>T:editassignsmenu" -f $assignName, $assignDir)
                $installPackagesScriptLines += "  ENDIF"
                $installPackagesScriptLines += "ENDIF"

                $editAssignsMenuOptionScriptLines += ""
                $editAssignsMenuOptionScriptLines += ("IF ""`$editassignsmenu"" eq """ + $editAssignsMenuOption + """")
                $editAssignsMenuOptionScriptLines += ("  set assignid ""{0}""" -f $assignId)
                $editAssignsMenuOptionScriptLines += ("  set assignname ""{0}""" -f $assignName)
                $editAssignsMenuOptionScriptLines += ("  IF EXISTS ""T:{0}""" -f $assignId)
                $editAssignsMenuOptionScriptLines += ("    set assigndir ""``type ""T:{0}""``""" -f $assignId)
                $editAssignsMenuOptionScriptLines += "  ELSE"
                $editAssignsMenuOptionScriptLines += ("    set assigndir ""{0}""" -f $assignDir)
                $editAssignsMenuOptionScriptLines += "  ENDIF"
                $editAssignsMenuOptionScriptLines += "  set returnlab ""editassignsmenu"""
                $editAssignsMenuOptionScriptLines += "  SKIP BACK selectassigndir"
                $editAssignsMenuOptionScriptLines += "ENDIF"
            }
        }

        # add back option to view readme menu
        $installPackagesScriptLines += "echo ""============================================================"" >>T:editassignsmenu"
        $installPackagesScriptLines += "echo ""Reset assigns"" >>T:editassignsmenu"
        $installPackagesScriptLines += "echo ""Default assigns"" >>T:editassignsmenu"
        $installPackagesScriptLines += "echo ""Back"" >>T:editassignsmenu"

        $installPackagesScriptLines += "set editassignsmenu """""
        $installPackagesScriptLines += "set editassignsmenu ""``RequestList TITLE=""Edit assigns"" LISTFILE=""T:editassignsmenu"" WIDTH=640 LINES=24``"""
        $installPackagesScriptLines += "delete >NIL: T:editassignsmenu"

        # add edit assigns menu options script lines
        $editAssignsMenuOptionScriptLines | ForEach-Object { $installPackagesScriptLines += $_ }

        # add back option to edit assigns menu
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$editassignsmenu"" eq """ + ($editAssignsMenuOption + 2) + """")
        $installPackagesScriptLines += "  set confirm ``RequestChoice ""Confirm"" ""Are you sure you want to reset assigns?"" ""Yes|No""``"
        $installPackagesScriptLines += "  IF ""`$confirm"" EQ ""1"""
        $installPackagesScriptLines += "    SKIP BACK resetassigns"
        $installPackagesScriptLines += "  ENDIF"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$editassignsmenu"" eq """ + ($editAssignsMenuOption + 3) + """")
        $installPackagesScriptLines += "  set confirm ``RequestChoice ""Confirm"" ""Are you sure you want to use default assigns?"" ""Yes|No""``"
        $installPackagesScriptLines += "  IF ""`$confirm"" EQ ""1"""
        $installPackagesScriptLines += "    SKIP BACK defaultassigns"
        $installPackagesScriptLines += "  ENDIF"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$editassignsmenu"" eq """ + ($editAssignsMenuOption + 4) + """")
        $installPackagesScriptLines += "  SKIP BACK installpackagesmenu"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "SKIP BACK editassignsmenu"
    }

    # install packages
    # ----------------
    $installPackagesScriptLines += ""
    $installPackagesScriptLines += "; Install packages"
    $installPackagesScriptLines += "; ----------------"
    $installPackagesScriptLines += "LAB installpackages"
    $installPackagesScriptLines += ''
    $installPackagesScriptLines += "IF ""{validate}"" EQ """""
    $installPackagesScriptLines += "  echo ""*ec"" NOLINE"
    $installPackagesScriptLines += "  echo ""*e[32m"" NOLINE"
    $installPackagesScriptLines += "  echo ""Package Installation"""
    $installPackagesScriptLines += "  echo ""*e[0m*e[1m"" NOLINE"
    $installPackagesScriptLines += "  echo ""--------------------"""
    $installPackagesScriptLines += "  echo ""*e[0m"" NOLINE"
    $installPackagesScriptLines += ''
    $installPackagesScriptLines += "  ; Create HstWB Installer prefs directory, if it doesn't exist"
    $installPackagesScriptLines += '  IF NOT EXISTS "SYSTEMDIR:Prefs/HstWB-Installer/Packages"'
    $installPackagesScriptLines += '    MakePath "SYSTEMDIR:Prefs/HstWB-Installer/Packages" >NIL:'
    $installPackagesScriptLines += '  ENDIF'
    $installPackagesScriptLines += "ELSE"
    $installPackagesScriptLines += "  echo ""*e[1mValidating assigns for packages...*e[0m"""
    $installPackagesScriptLines += "ENDIF"
    $installPackagesScriptLines += ''
    $installPackagesScriptLines += '; Validate assigns'
    $installPackagesScriptLines += 'Set assignsvalid 1'
    
    # get assign section names
    $assignSectionNames = @('Global')
    $assignSectionNames += $hstwb.Assigns.keys | Where-Object { $_ -notlike 'Global' } | Sort-Object

    # build validate assigns
    foreach($assignSectionName in $assignSectionNames)
    {
        # get section assigns
        $sectionAssigns = $hstwb.Assigns[$assignSectionName]

        foreach ($assignName in ($sectionAssigns.keys | Sort-Object))
        {
            # skip hstwb installer assign name for global assigns
            if ($assignSectionName -like 'Global' -and $assignName -like 'HstWBInstallerDir')
            {
                continue
            }

            $assignId = CalculateMd5FromText (("{0}.{1}" -f $assignSectionName, $assignName).ToLower())
            $assignDir = $sectionAssigns[$assignName]

            $installPackagesScriptLines += ""
            $installPackagesScriptLines += ("; Validate assign '{0}'" -f $assignName)
            $installPackagesScriptLines += BuildAssignDirScriptLines $assignId $assignDir
            $installPackagesScriptLines += "IF ""`$assigndir"" eq """""

            if ($assignSectionName -like 'Global')
            {
                $installPackagesScriptLines += ("  echo ""*e[1mError: Global assign '{0}' is not defined!*e[0m""" -f $assignName)
            }
            else
            {
                $installPackagesScriptLines += ("  echo ""*e[1mError: Assign '{0}' is not defined for package '{1}'!*e[0m""" -f $assignName, $installPackageScript.Package.FullName)
            }

            $installPackagesScriptLines += "  Set assignsvalid 0"
            $installPackagesScriptLines += "ENDIF"
            $installPackagesScriptLines += "; Get device name from assigndir by replacing colon with newline and get 1st line with device name"
            $installPackagesScriptLines += "echo ""`$assigndir"" >T:_assigndir1"
            $installPackagesScriptLines += "rep T:_assigndir1 "":"" ""*N"""
            $installPackagesScriptLines += "sed ""1q;d"" T:_assigndir1 >T:_assigndir2"
            $installPackagesScriptLines += "set devicename ""``type T:_assigndir2``"""
            $installPackagesScriptLines += "Assign >NIL: EXISTS ""`$devicename:"""
            $installPackagesScriptLines += "IF WARN"
            $installPackagesScriptLines += "  echo ""*e[1mError: Device name '`$devicename:' in assign dir '`$assigndir' doesn't exist for package '{0}'!*e[0m""" -f $installPackageScript.Package.FullName
            $installPackagesScriptLines += "  Set assignsvalid 0"
            $installPackagesScriptLines += "ENDIF"
        }
    }

    $installPackagesScriptLines += ''
    $installPackagesScriptLines += "IF ""{validate}"" EQ """""
    $installPackagesScriptLines += "  IF `$assignsvalid EQ 0 VAL"
    $installPackagesScriptLines += ("   echo ""Error: Validate assigns failed"" >>SYS:hstwb-installer.log" -f $assignName)
    $installPackagesScriptLines += "    echo ""*e[1mError: Validate assigns failed!*e[0m"""
    $installPackagesScriptLines += "    echo """""
    $installPackagesScriptLines += "    ask ""Press ENTER to continue"""
    $installPackagesScriptLines += "    SKIP BACK installpackagesmenu"
    $installPackagesScriptLines += "  ENDIF"
    $installPackagesScriptLines += "ELSE"
    $installPackagesScriptLines += "  IF `$assignsvalid EQ 1 VAL"
    $installPackagesScriptLines += "    echo ""Done"""
    $installPackagesScriptLines += "    SKIP end"
    $installPackagesScriptLines += "  ELSE"
    $installPackagesScriptLines += ("   echo ""Error: Validate assigns failed"" >>SYS:hstwb-installer.log" -f $assignName)
    $installPackagesScriptLines += "    echo ""*e[1mError: Validate assigns failed!*e[0m"""
    $installPackagesScriptLines += "    quit 20"
    $installPackagesScriptLines += "  ENDIF"
    $installPackagesScriptLines += "ENDIF"
    $installPackagesScriptLines += ''
    
    # append add global assign script lines
    if ($addGlobalAssignScriptLines.Count -gt 0)
    {
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += $addGlobalAssignScriptLines
    }

    # add install package script for each package
    foreach ($installPackageScript in $installPackageScripts)
    {
        $installPackagesScriptLines += ""
        
        if (($hstwb.Settings.Installer.Mode -eq "BuildSelfInstall" -or $hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation") -and $installPackages.Count -gt 0)
        {
            $installPackagesScriptLines += ("IF EXISTS T:" + $installPackageScript.Package.Id)
            $installPackagesScriptLines += '  execute INSTALLDIR:S/IniFileSet "{0}" "{1}" "{2}" "{3}"' -f 'SYSTEMDIR:Prefs/HstWB-Installer/Packages/Packages.ini', $installPackageScript.Package.Name, 'Version', $installPackageScript.Package.Version
            $installPackageScript.Lines | ForEach-Object { $installPackagesScriptLines += ("  " + $_) }
            $installPackagesScriptLines += "ENDIF"

            if ($hstwb.Settings.Installer.Mode -eq "BuildSelfInstall")
            {
                $installPackagesScriptLines += ("; Remove package '{0}' install files" -f $installPackageScript.Package.FullName)
                $installPackagesScriptLines += "echo """""
                $installPackagesScriptLines += ("echo ""*e[1mRemoving package '{0}' install files...*e[0m""" -f $installPackageScript.Package.FullName)
                $installPackagesScriptLines += ("Delete >NIL: ""PACKAGESDIR:{0}"" ALL" -f $installPackageScript.Package.Id)            
                $installPackagesScriptLines += "echo ""Done"""
            }
        }
        else
        {
            $installPackageScript.Lines | ForEach-Object { $installPackagesScriptLines += $_ }
        }
    }

    # append remove global assign script lines
    if ($removeGlobalAssignScriptLines.Count -gt 0)
    {
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += $removeGlobalAssignScriptLines
    }

    return $installPackagesScriptLines
}


# build winuae image harddrives config text
function BuildFsUaeHarddrivesConfigText($hstwb, $disableBootableHarddrives)
{
    # hstwb image json file
    $hstwbImageJsonFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath 'hstwb-image.json'

    # fail, if hstwb image json file doesn't exist
    if (!(Test-Path -Path $hstwbImageJsonFile))
    {
        Fail $hstwb ("Error: HstWB image file '" + $hstwbImageJsonFile + "' doesn't exist!")
    }

    # read hstwb image json file
    $image = Get-Content $hstwbImageJsonFile -Raw | ConvertFrom-Json

    # build fs-uae image harddrive config lines
    $fsUaeImageHarddrivesConfigLines = @()
    $index = 0
    foreach($harddrive in $image.Harddrives)
    {
        # harddrive path
        $harddrivePath = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath $harddrive.Path

        # fail, if harddrive path doesn't exist
        if (!(Test-Path -Path $harddrivePath))
        {
            Fail $hstwb ("Error: Harddrive path '" + $harddrivePath + "' doesn't exist!")
        }
        
        # boot priority
        $bootPriority = if ($disableBootableHarddrives) { -128 } else { $harddrive.BootPriority }

        # fs-uae harddrive config lines
        $fsUaeImageHarddrivesConfigLines += "hard_drive_{0} = {1}" -f $index, ($harddrivePath.Replace('\', '/'))
        $fsUaeImageHarddrivesConfigLines += "hard_drive_{0}_label = {1}" -f $index, $harddrive.Device
        $fsUaeImageHarddrivesConfigLines += "hard_drive_{0}_priority = {1}" -f $index, $bootPriority

        # add read only to fs-uae harddrive config lines, if harddrive is read only configured
        if ($harddrive.ReadOnly -match "ro")
        {
            $fsUaeImageHarddrivesConfigLines += "hard_drive_{0}_read_only" -f $index
        }

        # add file system to fs-uae harddrive config lines, if harddrive has file system configured
        if ($harddrive.FileSystem)
        {
            $fileSystem = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath $harddrive.FileSystem
            $fsUaeImageHarddrivesConfigLines += "hard_drive_{0}_file_system = {1}" -f $index, ($fileSystem.Replace('\', '/'))
        }

        $index++
    }

    return $fsUaeImageHarddrivesConfigLines -join "`r`n"
}


# build fs-uae install harddrives config text
function BuildFsUaeInstallHarddrivesConfigText($hstwb, $installDir, $packagesDir, $os39Dir, $userPackagesDir, $boot)
{
    # build fs-uae image harddrives config
    $fsUaeImageHarddrivesConfigText = BuildFsUaeHarddrivesConfigText $hstwb $boot

    # get harddrive index of last hard drive config from fs-uae image harddrives config
    $harddriveIndex = 0
    $fsUaeImageHarddrivesConfigText -split "`r`n" | ForEach-Object { $_ | Select-String -Pattern '^hard_drive_(\d+)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $harddriveIndex = $_.Groups[1].Value.Trim() } }

    # fs-uae  harddrives config file
    if ($boot)
    {
        $fsUaeHarddrivesConfigFile = Join-Path $hstwb.Paths.FsUaePath -ChildPath "harddrives_boot.fs-uae"
    }
    else
    {
        $fsUaeHarddrivesConfigFile = Join-Path $hstwb.Paths.FsUaePath -ChildPath "harddrives_noboot.fs-uae"
    }

    # fail, if fs-uae harddrives config file doesn't exist
    if (!(Test-Path -Path $fsUaeHarddrivesConfigFile))
    {
        Fail $hstwb ("Error: FS-UAE harddrives config file '" + $fsUaeHarddrivesConfigFile + "' doesn't exist!")
    }
    
    # read fs-uae harddrives config file
    $fsUaeHarddrivesConfigText = [System.IO.File]::ReadAllText($fsUaeHarddrivesConfigFile)

    # replace winuae install harddrives placeholders
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Replace('[$InstallDir]', $installDir.Replace('\', '/'))
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Replace('[$InstallHarddriveIndex]', [int]$harddriveIndex + 1)
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Replace('[$PackagesDir]', $packagesDir.Replace('\', '/'))
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Replace('[$PackagesHarddriveIndex]', [int]$harddriveIndex + 2)
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Replace('[$Os39Dir]', $os39Dir.Replace('\', '/'))
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Replace('[$Os39HarddriveIndex]', [int]$harddriveIndex + 3)
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Replace('[$UserPackagesDir]', $userPackagesDir.Replace('\', '/'))
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Replace('[$UserPackagesHarddriveIndex]', [int]$harddriveIndex + 4)
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Trim()
    
    # return winuae image and install harddrives config
    return $fsUaeImageHarddrivesConfigText + "`r`n" + $fsUaeHarddrivesConfigText    
}


# build fs-uae self install harddrives config text
function BuildFsUaeSelfInstallHarddrivesConfigText($hstwb, $workbenchDir, $kickstartDir, $os39Dir, $userPackagesDir)
{
    # build fs-uae image harddrives config
    $fsUaeImageHarddrivesConfigText = BuildFsUaeHarddrivesConfigText $hstwb $false

    # get harddrive index of last hard drive config from fs-uae image harddrives config
    $harddriveIndex = 0
    $fsUaeImageHarddrivesConfigText -split "`r`n" | ForEach-Object { $_ | Select-String -Pattern '^hard_drive_(\d+)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $harddriveIndex = $_.Groups[1].Value.Trim() } }

    $fsUaeSelfInstallHarddrivesConfigFile = [System.IO.Path]::Combine($fsUaePath, "harddrives_selfinstall.fs-uae")

    # fail, if fs-uae self install harddrives config file doesn't exist
    if (!(Test-Path -Path $fsUaeSelfInstallHarddrivesConfigFile))
    {
        Fail $hstwb ("Error: Self install harddrives config file '" + $fsUaeSelfInstallHarddrivesConfigFile + "' doesn't exist!")
    }

    # read fs-uae self install harddrives config file
    $fsUaeSelfInstallHarddrivesConfigText = [System.IO.File]::ReadAllText($fsUaeSelfInstallHarddrivesConfigFile)

    # replace winuae self install harddrives placeholders
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$WorkbenchDir]', $workbenchDir.Replace('\', '/'))
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$WorkbenchHarddriveIndex]', [int]$harddriveIndex + 1)
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$KickstartDir]', $kickstartDir.Replace('\', '/'))
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$KickstartHarddriveIndex]', [int]$harddriveIndex + 2)
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$Os39Dir]', $os39Dir.Replace('\', '/'))
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$Os39HarddriveIndex]', [int]$harddriveIndex + 3)
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$UserPackagesDir]', $userPackagesDir.Replace('\', '/'))
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$UserPackagesHarddriveIndex]', [int]$harddriveIndex + 4)
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Trim()

    # return fs-uae image and self install harddrives config
    return $fsUaeImageHarddrivesConfigText + "`r`n" + $fsUaeSelfInstallHarddrivesConfigText
}


# build winuae image harddrives config text
function BuildWinuaeImageHarddrivesConfigText($hstwb, $disableBootableHarddrives)
{
    # hstwb image json file
    $hstwbImageJsonFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath 'hstwb-image.json'

    # fail, if hstwb image json file doesn't exist
    if (!(Test-Path -Path $hstwbImageJsonFile))
    {
        Fail $hstwb ("Error: HstWB image file '" + $hstwbImageJsonFile + "' doesn't exist!")
    }

    # read hstwb image json file
    $image = Get-Content $hstwbImageJsonFile -Raw | ConvertFrom-Json

    # build winuae image harddrive config lines
    $winuaeImageHarddrivesConfigLines = @()
    $index = 0
    foreach($harddrive in $image.Harddrives)
    {
        # harddrive paths
        $harddrivePath = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath $harddrive.Path
        $harddrivePathEscaped = $harddrivePath.Replace('\', '\\')

        # fail, if harddrive path doesn't exist
        if (!(Test-Path -Path $harddrivePath))
        {
            Fail $hstwb ("Error: Harddrive path '" + $harddrivePath + "' doesn't exist!")
        }
        
        # boot priority
        $bootPriority = if ($disableBootableHarddrives) { -128 } else { $harddrive.BootPriority }

        # file system
        $fileSystem = if ($harddrive.FileSystem) { Join-Path $hstwb.Settings.Image.ImageDir -ChildPath $harddrive.FileSystem } else { "" }

        if ($harddrive.Type -match 'hdf')
        {
            # hdf winuae harddrive config lines
            $winuaeImageHarddrivesConfigLines += "hardfile2={0},{1}:{2},{3},{4},{5},{6},{7},{8},uae" -f `
                $harddrive.ReadOnly, `
                $harddrive.Device,  `
                $harddrivePath, `
                $harddrive.Sectors, `
                $harddrive.Surfaces, `
                $harddrive.Reserved, `
                $harddrive.BlockSize, `
                $bootPriority,
                $fileSystem
            $winuaeImageHarddrivesConfigLines += "uaehf{0}=hdf,{1},{2}:""{3}"",{4},{5},{6},{7},{8},{9},uae" -f `
                $index, `
                $harddrive.ReadOnly, `
                $harddrive.Device,  `
                $harddrivePathEscaped, `
                $harddrive.Sectors, `
                $harddrive.Surfaces, `
                $harddrive.Reserved, `
                $harddrive.BlockSize, `
                $bootPriority,
                $fileSystem
        }
        elseif($harddrive.Type -match 'dir')
        {
            # set volume, if not defined set it to device
            $volume = if ($harddrive.Volume) { $harddrive.Volume } else { $harddrive.Device }

            # directory winuae harddrive config lines
            $winuaeImageHarddrivesConfigLines += "filesystem2={0},{1}:{2}:{3},{4}" -f `
                $harddrive.ReadOnly, `
                $harddrive.Device, `
                $volume, `
                $harddrivePath, `
                $bootPriority
            $winuaeImageHarddrivesConfigLines += "uaehf{0}=dir,{1},{2}:{3}:""{4}"",{5}" -f `
                $index, `
                $harddrive.ReadOnly, `
                $harddrive.Device, `
                $volume, `
                $harddrivePath, `
                $bootPriority
        }

        $index++
    }

    return $winuaeImageHarddrivesConfigLines -join "`r`n"
}


# build winuae install harddrives config text
function BuildWinuaeInstallHarddrivesConfigText($hstwb, $installDir, $packagesDir, $os39Dir, $userPackagesDir, $boot)
{
    # build winuae image harddrives config
    $winuaeImageHarddrivesConfigText = BuildWinuaeImageHarddrivesConfigText $hstwb $boot

    # get uaehf index of last uaehf config from winuae image harddrives config
    $uaehfIndex = 0
    $winuaeImageHarddrivesConfigText -split "`r`n" | ForEach-Object { $_ | Select-String -Pattern '^uaehf(\d+)=' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $uaehfIndex = $_.Groups[1].Value.Trim() } }

    # winuae install harddrives config file
    if ($boot)
    {
        $winuaeInstallHarddrivesConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "harddrives_boot.uae")
    }
    else
    {
        $winuaeInstallHarddrivesConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "harddrives_noboot.uae")
    }

    # fail, if winuae install harddrives config file doesn't exist
    if (!(Test-Path -Path $winuaeInstallHarddrivesConfigFile))
    {
        Fail $hstwb ("Error: Install harddrives config file '" + $winuaeInstallHarddrivesConfigFile + "' doesn't exist!")
    }

    # read winuae install harddrives config file
    $winuaeInstallHarddrivesConfigText = [System.IO.File]::ReadAllText($winuaeInstallHarddrivesConfigFile)

    # replace winuae install harddrives placeholders
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$InstallDir]', $installDir)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$InstallUaehfIndex]', [int]$uaehfIndex + 1)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$PackagesDir]', $packagesDir)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$PackagesUaehfIndex]', [int]$uaehfIndex + 2)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$Os39Dir]', $os39Dir)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$Os39UaehfIndex]', [int]$uaehfIndex + 3)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$UserPackagesDir]', $userPackagesDir)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$UserPackagesUaehfIndex]', [int]$uaehfIndex + 4)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$Cd0UaehfIndex]', [int]$uaehfIndex + 5)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Trim()

    # return winuae image and install harddrives config
    return $winuaeImageHarddrivesConfigText + "`r`n" + $winuaeInstallHarddrivesConfigText
}


# build winuae self install harddrives config text
function BuildWinuaeSelfInstallHarddrivesConfigText($hstwb, $workbenchDir, $kickstartDir, $os39Dir, $userPackagesDir)
{
    # build winuae image harddrives config
    $winuaeImageHarddrivesConfigText = BuildWinuaeImageHarddrivesConfigText $hstwb $false

    # get uaehf index of last uaehf config from winuae image harddrives config
    $uaehfIndex = 0
    $winuaeImageHarddrivesConfigText -split "`r`n" | ForEach-Object { $_ | Select-String -Pattern '^uaehf(\d+)=' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $uaehfIndex = $_.Groups[1].Value.Trim() } }

    $winuaeSelfInstallHarddrivesConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "harddrives_selfinstall.uae")

    # fail, if winuae self install harddrives config file doesn't exist
    if (!(Test-Path -Path $winuaeSelfInstallHarddrivesConfigFile))
    {
        Fail $hstwb ("Error: Self install harddrives config file '" + $winuaeSelfInstallHarddrivesConfigFile + "' doesn't exist!")
    }

    # read winuae self install harddrives config file
    $winuaeSelfInstallHarddrivesConfigText = [System.IO.File]::ReadAllText($winuaeSelfInstallHarddrivesConfigFile)

    # replace winuae self install harddrives placeholders
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$WorkbenchDir]', $workbenchDir)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$WorkbenchUaehfIndex]', [int]$uaehfIndex + 1)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$KickstartDir]', $kickstartDir)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$KickstartUaehfIndex]', [int]$uaehfIndex + 2)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$Os39Dir]', $os39Dir)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$Os39UaehfIndex]', [int]$uaehfIndex + 3)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$UserPackagesDir]', $userPackagesDir)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$UserPackagesUaehfIndex]', [int]$uaehfIndex + 4)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$Cd0UaehfIndex]', [int]$uaehfIndex + 5)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Trim()

    # return winuae image and self install harddrives config
    return $winuaeImageHarddrivesConfigText + "`r`n" + $winuaeSelfInstallHarddrivesConfigText
}


# build winuae run harddrives config text
function BuildWinuaeRunHarddrivesConfigText($hstwb)
{
    # build winuae image harddrives config
    $winuaeImageHarddrivesConfigText = BuildWinuaeImageHarddrivesConfigText $hstwb $false

    # get uaehf index of last uaehf config from winuae image harddrives config
    $uaehfIndex = 0
    $winuaeImageHarddrivesConfigText -split "`r`n" | ForEach-Object { $_ | Select-String -Pattern '^uaehf(\d+)=' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $uaehfIndex = $_.Groups[1].Value.Trim() } }

    $winuaeRunHarddrivesConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "harddrives_run.uae")

    # fail, if winuae run harddrives config file doesn't exist
    if (!(Test-Path -Path $winuaeRunHarddrivesConfigFile))
    {
        Fail $hstwb ("Error: Run harddrives config file '" + $winuaeRunHarddrivesConfigFile + "' doesn't exist!")
    }

    # read winuae run harddrives config file
    $winuaeRunHarddrivesConfigText = [System.IO.File]::ReadAllText($winuaeRunHarddrivesConfigFile)

    # replace winuae self install harddrives placeholders
    $winuaeRunHarddrivesConfigText = $winuaeRunHarddrivesConfigText.Replace('[$Cd0UaehfIndex]', [int]$uaehfIndex + 1)
    $winuaeRunHarddrivesConfigText = $winuaeRunHarddrivesConfigText.Trim()

    # return winuae image and self install harddrives config
    return $winuaeImageHarddrivesConfigText + "`r`n" + $winuaeRunHarddrivesConfigText
}


# show large harddrive warning
function ShowLargeHarddriveWarning($hstwb)
{
    # build winuae image harddrives config
    $winuaeImageHarddrivesConfigText = BuildWinuaeImageHarddrivesConfigText $hstwb $false

    # get hdf files from winuae image harddrives config text
    $hdfFiles = @()
    $winuaeImageHarddrivesConfigText -split "`r`n" | ForEach-Object { $_ | Select-String -Pattern '^hardfile\d+=[^,]*,[^:]*:([^,]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $hdfFiles += $_.Groups[1].Value.Trim() } }

    # get first large harddrive
    $largeHarddrive = $hdfFiles | Where-Object { (Test-Path -Path $_) -and (Get-Item $_).Length -gt 4000000000 } | Select-Object -First 1

    # return, if no large harddrives are present
    if (!$largeHarddrive)
    {
        return
    }

    # show warning
    Write-Host ""
    Write-Host "Warning: Image uses harddrive(s) larger than 4GB and might become corrupt depending on scsi.device and filesystem used." -ForegroundColor "Yellow"
    Write-Host "It's recommended to use tools to check and repair harddrive integrity, e.g. pfsdoctor for partitions with PFS\3 filesystem." -ForegroundColor "Yellow"
}


# run test
function RunTest($hstwb)
{
    # Build and set emulator config file
    # ----------------------------------
    $emulatorArgs = ''
    if ($hstwb.Settings.Emulator.EmulatorFile -match 'fs-uae\.exe$')
    {
        # install hstwb installer fs-uae theme
        InstallHstwbInstallerFsUaeTheme $hstwb

        # build fs-uae harddrives config
        $fsUaeHarddrivesConfigText = BuildFsUaeHarddrivesConfigText $hstwb $false
        
        # read fs-uae hstwb installer config file
        $fsUaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.FsUaePath, "hstwb-installer.fs-uae")
        $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

        # replace hstwb installer fs-uae configuration placeholders
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $fsUaeHarddrivesConfigText)
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
        
        # write fs-uae hstwb installer config file to temp dir
        $tempFsUaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.TempPath, "hstwb-installer.fs-uae")
        [System.IO.File]::WriteAllText($tempFsUaeHstwbInstallerConfigFile, $fsUaeHstwbInstallerConfigText)
    
        # emulator args for fs-uae
        $emulatorArgs = """$tempFsUaeHstwbInstallerConfigFile"""
    }
    elseif ($hstwb.Settings.Emulator.EmulatorFile -match '(winuae\.exe|winuae64\.exe)$')
    {
        # build winuae image harddrives config text
        $winuaeImageHarddrivesConfigText = BuildWinuaeImageHarddrivesConfigText $hstwb $false

        # read winuae hstwb installer config file
        $winuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "hstwb-installer.uae")
        $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)

        # replace winuae test config placeholders
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$Harddrives]', $winuaeImageHarddrivesConfigText)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$IsoFile]', '')
    
        # write winuae hstwb installer config file to temp dir
        $tempWinuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.TempPath, "hstwb-installer.uae")
        [System.IO.File]::WriteAllText($tempWinuaeHstwbInstallerConfigFile, $winuaeHstwbInstallerConfigText)

        # emulator args for winuae
        $emulatorArgs = "-f ""$tempWinuaeHstwbInstallerConfigFile"""
    }
    else
    {
        Fail $hstwb ("Emulator file '{0}' is not supported" -f $hstwb.Settings.Emulator.EmulatorFile)
    }


    # show large harddrive warning
    ShowLargeHarddriveWarning $hstwb


    # print starting emulator message
    Write-Host ""
    Write-Host ("Starting emulator '{0}' to test image..." -f $hstwb.Emulator)

    # fail, if emulator doesn't return error code 0
    $emulatorProcess = Start-Process $hstwb.Settings.Emulator.EmulatorFile $emulatorArgs -Wait -NoNewWindow
    if ($emulatorProcess -and $emulatorProcess.ExitCode -ne 0)
    {
        Fail $hstwb ("Failed to run '" + $hstwb.Settings.Emulator.EmulatorFile + "' with arguments '$emulatorArgs'")
    }
}


# run install
function RunInstall($hstwb)
{
    # print preparing install message
    Write-Host ""
    Write-Host "Preparing install..."


    # copy amiga install dir
    $amigaInstallDir = Join-Path $hstwb.Paths.AmigaPath -ChildPath "install"
    Copy-Item -Path $amigaInstallDir $hstwb.Paths.TempPath -recurse -force


    # set temp install and packages dir
    $tempInstallDir = Join-Path $hstwb.Paths.TempPath -ChildPath "install"
    $tempWorkbenchDir = Join-Path $tempInstallDir -ChildPath "Workbench"
    $tempKickstartDir = Join-Path $tempInstallDir -ChildPath "Kickstart"
    $tempPackagesDir = Join-Path $hstwb.Paths.TempPath -ChildPath "packages"
    $tempOs39Dir = Join-Path $hstwb.Paths.TempPath -ChildPath "os39"
    $tempUserPackagesDir = Join-Path $hstwb.Paths.TempPath -ChildPath "userpackages"

    # create temp workbench path
    if(!(test-path -path $tempWorkbenchDir))
    {
        mkdir $tempWorkbenchDir | Out-Null
    }

    # create temp kickstart path
    if(!(test-path -path $tempKickstartDir))
    {
        mkdir $tempKickstartDir | Out-Null
    }

    # create temp packages path
    if(!(test-path -path $tempPackagesDir))
    {
        mkdir $tempPackagesDir | Out-Null
    }

    # create temp os39 path
    if(!(test-path -path $tempOs39Dir))
    {
        mkdir $tempOs39Dir | Out-Null
    }
    
    # create temp os39 path
    if(!(test-path -path $tempUserPackagesDir))
    {
        mkdir $tempUserPackagesDir | Out-Null
    }

    # temp and image hstwb installer log files
    $tempHstwbInstallerLogFile = Join-Path $tempInstallDir -ChildPath 'hstwb-installer.log'
    $imageHstwbInstallerLogFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath 'hstwb-installer.log'
    
    # backup existing hstwb installer log file
    if (Test-Path -Path $imageHstwbInstallerLogFile)
    {
        $backupImageHstwbInstallerLogCount = 0;
        $backupImageHstwbInstallerLogFilename = ''
        do
        {
            $backupImageHstwbInstallerLogCount++;
            $backupImageHstwbInstallerLogFilename = 'hstwb-installer_{0}.log' -f $backupImageHstwbInstallerLogCount
        } while (Test-Path -Path (Join-Path $hstwb.Settings.Image.ImageDir -ChildPath $backupImageHstwbInstallerLogFilename))

        Rename-Item -Path $imageHstwbInstallerLogFile -NewName $backupImageHstwbInstallerLogFilename
    }


    # copy large harddisk to install directory
    $largeHarddiskDir = Join-Path $hstwb.Paths.AmigaPath -ChildPath "largeharddisk\Install-LargeHarddisk"
    Copy-Item -Path "$largeHarddiskDir\*" $tempInstallDir -recurse -force
    $largeHarddiskDir = Join-Path $hstwb.Paths.AmigaPath -ChildPath "largeharddisk"
    Copy-Item -Path "$largeHarddiskDir\*" $tempInstallDir -recurse -force

    # copy amiga shared dir
    $amigaSharedDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "shared")
    Copy-Item -Path "$amigaSharedDir\*" $tempInstallDir -recurse -force

    # copy workbench to install directory
    $amigaWorkbenchDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "workbench")
    Copy-Item -Path "$amigaWorkbenchDir\*" $tempInstallDir -recurse -force

    # copy kickstart to install directory
    $amigaKickstartDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "kickstart")
    Copy-Item -Path "$amigaKickstartDir\*" $tempInstallDir -recurse -force

    # copy generic to install directory
    $amigaGenericDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "generic")
    Copy-Item -Path "$amigaGenericDir\*" $tempInstallDir -recurse -force
    
    # copy amiga packages dir
    $amigaPackagesDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "packages")
    Copy-Item -Path "$amigaPackagesDir\*" $tempInstallDir -recurse -force

    # copy amiga user packages dir
    $amigaUserPackagesDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "userpackages")
    Copy-Item -Path "$amigaUserPackagesDir\*" $tempInstallDir -recurse -force


    # create prefs directory
    $prefsDir = [System.IO.Path]::Combine($tempInstallDir, "Prefs")
    if(!(test-path -path $prefsDir))
    {
        mkdir $prefsDir | Out-Null
    }


    # create uae prefs file
    $uaePrefsFile = Join-Path $prefsDir -ChildPath 'UAE'
    Set-Content $uaePrefsFile -Value ""


    # prepare install workbench
    if ($hstwb.Settings.Workbench.InstallWorkbench -eq 'Yes' -and ($hstwb.WorkbenchAdfHashes | Where-Object { $_.File }).Count -gt 0)
    {
        # create install workbench prefs file
        $installWorkbenchFile = Join-Path $prefsDir -ChildPath 'Install-Workbench'
        Set-Content $installWorkbenchFile -Value ""
        
        # copy workbench adf set files to temp install dir
        Write-Host "Copying Workbench adf files to temp install dir"
        $hstwb.WorkbenchAdfHashes | Where-Object { $_.File } | ForEach-Object { Copy-Item -Literalpath $_.File -Destination (Join-Path $tempWorkbenchDir -ChildPath $_.Filename) -Force }
    }


    # prepare install kickstart
    if ($hstwb.Settings.Kickstart.InstallKickstart -eq 'Yes' -and ($hstwb.KickstartRomHashes | Where-Object { $_.File }).Count -gt 0 )
    {
        # create install kickstart prefs file
        $installKickstartFile = Join-Path $prefsDir -ChildPath 'Install-Kickstart'
        Set-Content $installKickstartFile -Value ""
        
        # copy kickstart rom set files to temp install dir
        Write-Host "Copying Kickstart rom files to temp install dir"

        $hstwb.KickstartRomHashes | Where-Object { $_.File } | ForEach-Object { Copy-Item -Literalpath $_.File -Destination (Join-Path $tempKickstartDir -ChildPath $_.Filename) -Force }

        # get first kickstart rom hash
        $installKickstartRomHash = $hstwb.KickstartRomHashes | Where-Object { $_.File } | Select-Object -First 1

        # kickstart rom key
        $installKickstartRomKeyFile = Join-Path (Split-Path $installKickstartRomHash.File -Parent) -ChildPath "rom.key"

        # copy kickstart rom key file to temp install dir, if kickstart roms are encrypted
        if ($installKickstartRomHash.Encrypted -eq 'Yes' -and (test-path -path $installKickstartRomKeyFile))
        {
            Copy-Item -Literalpath $installKickstartRomKeyFile -Destination (Join-Path -Path $tempKickstartDir -ChildPath "rom.key") -Force
        }
    }

    # find packages to install
    $installPackages = FindPackagesToInstall $hstwb


    # build assign hstwb installers script lines
    $assignHstwbInstallerScriptLines = BuildAssignHstwbInstallerScriptLines $hstwb $true

    # write assign hstwb installer to install dir
    $userAssignFile = [System.IO.Path]::Combine($tempInstallDir, "S\Assign-HstWB-Installer")
    WriteAmigaTextLines $userAssignFile $assignHstwbInstallerScriptLines 


    $packagesIniLines = @()


    $installPackagesReboot = $false

    # extract packages and write install packages script, if there's packages to install
    if ($installPackages.Count -gt 0)
    {
        $installPackagesReboot = $true

        # create install packages prefs file
        $installPackagesFile = Join-Path $prefsDir -ChildPath 'Install-Packages'
        Set-Content $installPackagesFile -Value ""

        # extract packages to temp packages dir
        ExtractPackages $hstwb $installPackages $tempPackagesDir

        # extract packages to package directory
        foreach($installPackage in $installPackages)
        {
            $package = $hstwb.Packages[$installPackage.ToLower()]
            $packagesIniLines += "[{0}]" -f $package.Name
            $packagesIniLines += "Version={0}" -f $package.Version
        }

        # build install package script lines
        $installPackagesScriptLines = @()
        $installPackagesScriptLines += ".KEY validate/s"
        $installPackagesScriptLines += ".BRA {"
        $installPackagesScriptLines += ".KET }"
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += "; Install Packages"
        $installPackagesScriptLines += "; ----------------"
        $installPackagesScriptLines += "; Author: Henrik Noerfjand Stengaard"
        $installPackagesScriptLines += ("; Date: {0}" -f (Get-Date -format "yyyy-MM-dd"))
        $installPackagesScriptLines += ";"
        $installPackagesScriptLines += "; An install packages script generated by HstWB Installer to install configured packages."
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += BuildInstallPackagesScriptLines $hstwb $installPackages
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += "echo """""
        $installPackagesScriptLines += "echo ""Package installation is complete."""
        $installPackagesScriptLines += "echo """""
        $installPackagesScriptLines += "ask ""Press ENTER to continue"""
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += "; End"
        $installPackagesScriptLines += "LAB end"
        

        # write install packages script
        $installPackagesFile = [System.IO.Path]::Combine($tempInstallDir, "S\Install-Packages")
        WriteAmigaTextLines $installPackagesFile $installPackagesScriptLines 
    }

    # add empty line to packages ini
    $packagesIniLines += ''

    # get user packages
    $installUserPackageNames = @()
    foreach($installUserPackageKey in ($hstwb.Settings.UserPackages.Keys | Sort-Object | Where-Object { $_ -match 'InstallUserPackage\d+' }))
    {
        $userPackageName = $hstwb.Settings.UserPackages.Get_Item($installUserPackageKey.ToLower())
        $userPackage = $hstwb.UserPackages.Get_Item($userPackageName)
        $installUserPackageNames += $userPackage.Name
    }

    # set user packages dir
    $userPackagesDir = $hstwb.Settings.UserPackages.UserPackagesDir

    # set user packages dir to temp user packages dir, if user packages dir is not defined or doesn't exist
    if (!$userPackagesDir -or !(Test-Path $userPackagesDir))
    {
        $userPackagesDir = $tempUserPackagesDir
    }
    
    # create instal user packages prefs file and user packages, if user packages are selected
    if ($installUserPackageNames.Count -gt 0)
    {
        # add empty line
        $installUserPackageNames += ''

        # create install user packages prefs file
        $installUserPackagesFile = Join-Path $prefsDir -ChildPath 'Install-User-Packages'
        Set-Content $installUserPackagesFile -Value ""

        # write user packages prefs file
        $userPackagesFile = Join-Path $prefsDir -ChildPath 'User-Packages'
        WriteAmigaTextLines $userPackagesFile $installUserPackageNames 
    }


    $installAmigaOs39Reboot = $false
    $installBoingBagsReboot = $false
    
    if ($hstwb.Settings.AmigaOS39.InstallAmigaOS39 -eq 'Yes' -and $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile)
    {
        $installAmigaOs39Reboot = $true

        # create install amiga os 3.9 prefs file
        $installAmigaOs39File = Join-Path $prefsDir -ChildPath 'Install-AmigaOS3.9'
        Set-Content $installAmigaOs39File -Value ""


        # get amiga os 3.9 directory and filename
        $amigaOs39IsoDir = Split-Path $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile -Parent
        $amigaOs39IsoFileName = Split-Path $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile -Leaf


        $boingBag1File = Join-Path $amigaOs39IsoDir -ChildPath 'BoingBag39-1.lha'

        if ((Test-Path $boingBag1File) -and $hstwb.Settings.AmigaOS39.InstallBoingBags -eq 'Yes')
        {
            $installBoingBagsReboot = $true
            $installBoingBagsPrefsFile = Join-Path $prefsDir -ChildPath 'Install-BoingBags'
            Set-Content $installBoingBagsPrefsFile -Value ""
        }

        # copy amiga os 3.9 dir
        $amigaOs39Dir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "amigaos3.9")
        Copy-Item -Path "$amigaOs39Dir\*" $tempInstallDir -recurse -force

        #
        $os39Dir = $amigaOs39IsoDir
        $isoFile = $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile
    }
    else
    {
        $amigaOs39IsoFileName = ''
        $os39Dir = $tempOs39Dir
        $isoFile = ''
    }


    # read mountlist
    $mountlistFile = Join-Path -Path $tempInstallDir -ChildPath "Devs\Mountlist"
    $mountlistText = [System.IO.File]::ReadAllText($mountlistFile)

    # update and write mountlist
    $mountlistText = $mountlistText.Replace('[$OS39IsoFileName]', $amigaOs39IsoFileName)
    $mountlistText = [System.IO.File]::WriteAllText($mountlistFile, $mountlistText)

    # create packages prefs directory
    $packagesPrefsDir = Join-Path $prefsDir -ChildPath "Packages"
    if(!(test-path -path $packagesPrefsDir))
    {
        mkdir $packagesPrefsDir | Out-Null
    }
    
    # write hstwb installer packages ini file
    $hstwbInstallerPackagesIniFile = Join-Path $packagesPrefsDir -ChildPath 'Packages.ini'
    WriteAmigaTextLines $hstwbInstallerPackagesIniFile $packagesIniLines

    # build hstwb installer assigns ini
    $assignsIniLines = @()

    foreach ($assignSectionName in $hstwb.Assigns.keys)
    {
        $sectionAssigns = $hstwb.Assigns[$assignSectionName]

        $sectionAssignNames = $sectionAssigns.keys | Sort-Object | Where-Object { $_ -notlike 'HstWBInstallerDir' }

        if ($sectionAssignNames.Count -eq 0)
        {
            continue
        }

        $assignsIniLines += "[{0}]" -f $assignSectionName

        foreach ($assignName in $sectionAssignNames)
        {
            $assignsIniLines += "{0}={1}" -f $assignName, $sectionAssigns.Get_Item($assignName)
        }
    }

    # add empty line to assigns ini
    $assignsIniLines += ''

    # write hstwb installer assigns ini file
    $hstwbInstallerAssignsIniFile = Join-Path $packagesPrefsDir -ChildPath 'Assigns.ini'
    WriteAmigaTextLines $hstwbInstallerAssignsIniFile $assignsIniLines

    # update version in startup sequence files
    $startupSequenceFiles = @()
    $startupSequenceFiles += Get-ChildItem -Path $tempInstallDir -Filter 'Startup-Sequence.*' -Recurse
    $startupSequenceFiles | ForEach-Object { UpdateVersionAmigaTextFile $_.FullName $hstwb.Version }
    
    # write hstwb installer log file
    $installLogLines = BuildInstallLog $hstwb
    WriteAmigaTextLines $tempHstwbInstallerLogFile $installLogLines
    
    
    # read winuae hstwb installer config file
    $winuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "hstwb-installer.uae")
    $hstwbInstallerUaeWinuaeConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)

    # build winuae run harddrives config
    $winuaeRunHarddrivesConfigText = BuildWinuaeRunHarddrivesConfigText $hstwb

    # replace hstwb installer configuration placeholders
    $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('use_gui=no', 'use_gui=yes')
    $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile)
    $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$WorkbenchAdfFile]', '')
    $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$Harddrives]', $winuaeRunHarddrivesConfigText)
    $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$IsoFile]', '')

    # write hstwb installer configuration file to image dir
    $hstwbInstallerUaeConfigFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "hstwb-installer.uae"
    [System.IO.File]::WriteAllText($hstwbInstallerUaeConfigFile, $hstwbInstallerUaeWinuaeConfigText)
    
    # read fs-uae hstwb installer config file
    $fsUaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.FsUaePath, "hstwb-installer.fs-uae")
    $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

    # build fs-uae install harddrives config
    $hstwbInstallerFsUaeInstallHarddrivesConfigText = BuildFsUaeHarddrivesConfigText $hstwb
    
    # replace hstwb installer fs-uae configuration placeholders
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile.Replace('\', '/'))
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $hstwbInstallerFsUaeInstallHarddrivesConfigText)
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', '')
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
    
    # write hstwb installer fs-uae configuration file to image dir
    $hstwbInstallerFsUaeConfigFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "hstwb-installer.fs-uae"
    [System.IO.File]::WriteAllText($hstwbInstallerFsUaeConfigFile, $fsUaeHstwbInstallerConfigText)
    

    # copy hstwb image setup to image dir
    $hstwbImageSetupDir = [System.IO.Path]::Combine($hstwb.Paths.SupportPath, "hstwb_image_setup")
    Copy-Item -Path "$hstwbImageSetupDir\*" $hstwb.Settings.Image.ImageDir -recurse -force
    

    #
    $emulatorArgs = ''
    if ($hstwb.Settings.Emulator.EmulatorFile -match 'fs-uae\.exe$')
    {
        # install hstwb installer fs-uae theme
        InstallHstwbInstallerFsUaeTheme $hstwb

        # build fs-uae install harddrives config
        $fsUaeInstallHarddrivesConfigText = BuildFsUaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $os39Dir $userPackagesDir $true

        # read fs-uae hstwb installer config file
        $fsUaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.FsUaePath, "hstwb-installer.fs-uae")
        $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

        # replace hstwb installer fs-uae configuration placeholders
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', $hstwb.Paths.WorkbenchAdfFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $fsUaeInstallHarddrivesConfigText)
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
        
        # write fs-uae hstwb installer config file to temp dir
        $tempFsUaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.TempPath, "hstwb-installer.fs-uae")
        [System.IO.File]::WriteAllText($tempFsUaeHstwbInstallerConfigFile, $fsUaeHstwbInstallerConfigText)
    
        # emulator args for fs-uae
        $emulatorArgs = """$tempFsUaeHstwbInstallerConfigFile"""
    }
    elseif ($hstwb.Settings.Emulator.EmulatorFile -match '(winuae\.exe|winuae64\.exe)$')
    {
        # build winuae install harddrives config
        $winuaeInstallHarddrivesConfigText = BuildWinuaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $os39Dir $userPackagesDir $true
    
        # read winuae hstwb installer config file
        $winuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "hstwb-installer.uae")
        $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)
    
        # replace winuae hstwb installer config placeholders
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', $hstwb.Paths.WorkbenchAdfFile)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$Harddrives]', $winuaeInstallHarddrivesConfigText)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile)
    
        # write winuae hstwb installer config file to temp install dir
        $tempWinuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.TempPath, "hstwb-installer.uae")
        [System.IO.File]::WriteAllText($tempWinuaeHstwbInstallerConfigFile, $winuaeHstwbInstallerConfigText)

        # emulator args for winuae
        $emulatorArgs = "-f ""$tempWinuaeHstwbInstallerConfigFile"""
    }
    else
    {
        Fail $hstwb ("Emulator file '{0}' is not supported" -f $hstwb.Settings.Emulator.EmulatorFile)
    }

    # print preparing installation done message
    Write-Host "Done."
    

    # show large harddrive warning
    ShowLargeHarddriveWarning $hstwb


    # print start emulator message
    Write-Host ""
    Write-Host ("Starting emulator '{0}' to run install..." -f $hstwb.Emulator)
    
    # start emulator to run install
    $emulatorProcess = Start-Process $hstwb.Settings.Emulator.EmulatorFile $emulatorArgs -Wait -NoNewWindow

    # append temp hstwb installer log file to image hstwb installer log file
    if (Test-Path -Path $tempHstwbInstallerLogFile)
    {
        Get-Content $tempHstwbInstallerLogFile | Add-Content -Path $imageHstwbInstallerLogFile
    }

    # fail, if emulator doesn't return error code 0
    if ($emulatorProcess -and $emulatorProcess.ExitCode -ne 0)
    {
        Fail $hstwb ("Failed to run '" + $hstwb.Settings.Emulator.EmulatorFile + "' with arguments '$emulatorArgs'")
    }


    # fail, if install complete prefs file doesn't exists
    $installCompletePrefsFile = Join-Path $prefsDir -ChildPath 'Install-Complete'
    if (!(Test-Path -path $installCompletePrefsFile))
    {
        Fail $hstwb "Installation failed"
    }

    
    if (!$installPackagesReboot -and !$installAmigaOs39Reboot)
    {
        return
    }


    #
    $emulatorArgs = ''
    if ($hstwb.Settings.Emulator.EmulatorFile -match 'fs-uae\.exe$')
    {
        # build fs-uae install harddrives config
        $fsUaeInstallHarddrivesConfigText = BuildFsUaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $os39Dir $userPackagesDir $false
        
        # read fs-uae hstwb installer config file
        $fsUaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.FsUaePath, "hstwb-installer.fs-uae")
        $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

        # replace hstwb installer fs-uae configuration placeholders
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $fsUaeInstallHarddrivesConfigText)
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
        
        # write fs-uae hstwb installer config file to temp dir
        $tempFsUaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.TempPath, "hstwb-installer.fs-uae")
        [System.IO.File]::WriteAllText($tempFsUaeHstwbInstallerConfigFile, $fsUaeHstwbInstallerConfigText)
    
        # emulator args for fs-uae
        $emulatorArgs = """$tempFsUaeHstwbInstallerConfigFile"""
    }
    elseif ($hstwb.Settings.Emulator.EmulatorFile -match '(winuae\.exe|winuae64\.exe)$')
    {
        # build winuae install harddrives config with boot
        $winuaeInstallHarddrivesConfigText = BuildWinuaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $os39Dir $userPackagesDir $false
        
        # read winuae hstwb installer config file
        $winuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "hstwb-installer.uae")
        $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)

        # replace winuae hstwb installer config placeholders
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$Harddrives]', $winuaeInstallHarddrivesConfigText)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile)

        # write winuae hstwb installer config file to temp dir
        $tempWinuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.TempPath, "hstwb-installer.uae")
        [System.IO.File]::WriteAllText($tempWinuaeHstwbInstallerConfigFile, $winuaeHstwbInstallerConfigText)

        # emulator args for winuae
        $emulatorArgs = "-f ""$tempWinuaeHstwbInstallerConfigFile"""
    }
    else
    {
        Fail $hstwb ("Emulator file '{0}' is not supported" -f $hstwb.Settings.Emulator.EmulatorFile)
    }
        
    
    # print start emulator message
    Write-Host ""
    $task = ""
    if ($installAmigaOs39Reboot)
    {
        $task = "Amiga OS 3.9"
    }
    if ($installBoingBagsReboot)
    {
        if ($task.Length -gt 0)
        {
            $task += ", "
        }
        $task += "Boing Bags"
    }
    if ($installPackagesReboot)
    {
        if ($task.Length -gt 0)
        {
            $task += ", "
        }
        $task += "Packages"
    }

    Write-Host ("Starting emulator '{0}' to run install {1}..." -f $hstwb.Emulator, $task)        
    
    # start emulator to run install boing bags, packages
    $emulatorProcess = Start-Process $hstwb.Settings.Emulator.EmulatorFile $emulatorArgs -Wait -NoNewWindow

    # append temp hstwb installer log file to image hstwb installer log file
    if (Test-Path -Path $tempHstwbInstallerLogFile)
    {
        Get-Content $tempHstwbInstallerLogFile | Add-Content -Path $imageHstwbInstallerLogFile
    }

    # fail, if emulator doesn't return error code 0
    if ($emulatorProcess -and $emulatorProcess.ExitCode -ne 0)
    {
        Fail $hstwb ("Failed to run '" + $hstwb.Settings.Emulator.EmulatorFile + "' with arguments '$emulatorArgs'")
    }
}


# run build self install
function RunBuildSelfInstall($hstwb)
{
    # print preparing self install message
    Write-Host ""
    Write-Host "Preparing build self install..."    


    # create temp install dir
    $tempInstallDir = Join-Path $hstwb.Paths.TempPath -ChildPath "install"
    if(!(test-path -path $tempInstallDir))
    {
        mkdir $tempInstallDir | Out-Null
    }

    # create temp licenses dir
    $tempLicensesDir = Join-Path $tempInstallDir -ChildPath "Licenses"
    if(!(test-path -path $tempLicensesDir))
    {
        mkdir $tempLicensesDir | Out-Null
    }

    # create temp packages dir
    $tempPackagesDir = Join-Path $hstwb.Paths.TempPath -ChildPath  "packages"
    if(!(test-path -path $tempPackagesDir))
    {
        mkdir $tempPackagesDir | Out-Null
    }

    # create temp os39 dir
    $tempOs39Dir = Join-Path $hstwb.Paths.TempPath -ChildPath "os39"
    if(!(test-path -path $tempOs39Dir))
    {
        mkdir $tempOs39Dir | Out-Null
    }

    # create temp user packages dir
    $tempUserPackagesDir = Join-Path $hstwb.Paths.TempPath -ChildPath "userpackages"
    if(!(test-path -path $tempUserPackagesDir))
    {
        mkdir $tempUserPackagesDir | Out-Null
    }

    # create install prefs dir
    $prefsDir = Join-Path $tempInstallDir -ChildPath "Prefs"
    if(!(test-path -path $prefsDir))
    {
        mkdir $prefsDir | Out-Null
    }


    # temp and image hstwb installer log files
    $tempHstwbInstallerLogFile = Join-Path $tempInstallDir -ChildPath 'hstwb-installer.log'
    $imageHstwbInstallerLogFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath 'hstwb-installer.log'

    # backup existing hstwb installer log file
    if (Test-Path -Path $imageHstwbInstallerLogFile)
    {
        $backupImageHstwbInstallerLogCount = 0;
        $backupImageHstwbInstallerLogFilename = ''
        do
        {
            $backupImageHstwbInstallerLogCount++;
            $backupImageHstwbInstallerLogFilename = 'hstwb-installer_{0}.log' -f $backupImageHstwbInstallerLogCount
        } while (Test-Path -Path (Join-Path $hstwb.Settings.Image.ImageDir -ChildPath $backupImageHstwbInstallerLogFilename))

        Rename-Item -Path $imageHstwbInstallerLogFile -NewName $backupImageHstwbInstallerLogFilename
    }


    # copy licenses dir
    Copy-Item -Path "$licensesPath\*" $tempLicensesDir -recurse -force
    
    # copy self install to install directory
    $amigaSelfInstallBuildDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "selfinstall")
    Copy-Item -Path "$amigaSelfInstallBuildDir\*" $tempInstallDir -recurse -force

    # copy generic to install directory
    $amigaGenericDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "generic")
    Copy-Item -Path "$amigaGenericDir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force
    
    # copy large harddisk
    $installLargeHarddiskDir = Join-Path $hstwb.Paths.AmigaPath -ChildPath "largeharddisk\Install-LargeHarddisk"
    Copy-Item -Path "$installLargeHarddiskDir\*" $tempInstallDir -recurse -force
    Copy-Item -Path "$installLargeHarddiskDir\*" "$tempInstallDir\Boot-SelfInstall" -recurse -force
    $largeHarddiskDir = Join-Path $hstwb.Paths.AmigaPath -ChildPath "largeharddisk"
    Copy-Item -Path "$largeHarddiskDir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force

    # copy large harddisk to self install directory
    $selfInstallLargeHarddiskDir = Join-Path "$tempInstallDir\Install-SelfInstall" -ChildPath "Large-Harddisk"
    if(!(test-path -path $selfInstallLargeHarddiskDir))
    {
        mkdir $selfInstallLargeHarddiskDir | Out-Null
    }
    Copy-Item -Path "$largeHarddiskDir\*" $selfInstallLargeHarddiskDir -recurse -force

    # copy shared to install directory
    $sharedDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "shared")
    Copy-Item -Path "$sharedDir\*" $tempInstallDir -recurse -force
    Copy-Item -Path "$sharedDir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force
    
    # copy amiga os 3.9 to install directory
    $amigaOs39Dir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "amigaos3.9")
    Copy-Item -Path "$amigaOs39Dir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force
    
    # copy workbench to install directory
    $amigaWorkbenchDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "workbench")
    Copy-Item -Path "$amigaWorkbenchDir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force

    # copy kickstart to install directory
    $amigaKickstartDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "kickstart")
    Copy-Item -Path "$amigaKickstartDir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force
    
    # copy amiga packages dir
    $amigaPackagesDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "packages")
    Copy-Item -Path "$amigaPackagesDir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force

    # copy amiga user packages dir
    $amigaUserPackagesDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "userpackages")
    Copy-Item -Path "$amigaUserPackagesDir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force


    # create self install prefs file
    $uaePrefsFile = Join-Path $prefsDir -ChildPath 'Self-Install'
    Set-Content $uaePrefsFile -Value ""


    # build assign hstwb installers script lines
    $assignHstwbInstallerScriptLines = @()
    $assignHstwbInstallerScriptLines += BuildAssignHstwbInstallerScriptLines $hstwb $true


    # write assign hstwb installer script for building self install
    $userAssignFile = [System.IO.Path]::Combine($tempInstallDir, "S\Assign-HstWB-Installer")
    WriteAmigaTextLines $userAssignFile $assignHstwbInstallerScriptLines


    # write assign hstwb installer script for self install
    $assignHstwbInstallerScriptLines +="Assign INSTALLDIR: ""HstWBInstallerDir:Install"""
    $assignHstwbInstallerScriptLines +="Assign PACKAGESDIR: ""HstWBInstallerDir:Packages"""
    $userAssignFile = [System.IO.Path]::Combine($tempInstallDir, "Boot-SelfInstall\S\Assign-HstWB-Installer")
    WriteAmigaTextLines $userAssignFile $assignHstwbInstallerScriptLines


    # find packages to install
    $installPackages = FindPackagesToInstall $hstwb


    # extract packages and write install packages script, if there's packages to install
    if ($installPackages.Count -gt 0)
    {
        # create install packages prefs file
        $installPackagesFile = Join-Path $prefsDir -ChildPath 'Install-Packages'
        Set-Content $installPackagesFile -Value ""

        # extract packages to temp packages dir
        ExtractPackages $hstwb $installPackages $tempPackagesDir

        # build install package script lines
        $installPackagesScriptLines = @()
        $installPackagesScriptLines += ".KEY validate/s"
        $installPackagesScriptLines += ".BRA {"
        $installPackagesScriptLines += ".KET }"
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += "; Install Packages"
        $installPackagesScriptLines += "; ----------------"
        $installPackagesScriptLines += "; Author: Henrik Noerfjand Stengaard"
        $installPackagesScriptLines += ("; Date: {0}" -f (Get-Date -format "yyyy-MM-dd"))
        $installPackagesScriptLines += ";"
        $installPackagesScriptLines += "; An install packages script generated by HstWB Installer to install configured packages."
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += BuildInstallPackagesScriptLines $hstwb $installPackages
        $installPackagesScriptLines += "echo """""
        $installPackagesScriptLines += "echo ""Package installation is complete."""
        $installPackagesScriptLines += "echo """""
        $installPackagesScriptLines += "ask ""Press ENTER to continue"""
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "; End"
        $installPackagesScriptLines += "LAB end"


        # write install packages script
        $installPackagesScriptFile = [System.IO.Path]::Combine($tempInstallDir, "Install-SelfInstall\S\Install-Packages")
        WriteAmigaTextLines $installPackagesScriptFile $installPackagesScriptLines 
    }


    $globalAssigns = $hstwb.Assigns.Get_Item('Global')

    if (!$globalAssigns)
    {
        Fail $hstwb ("Failed to run install. Global assigns doesn't exist!")
    }

    $removeHstwbInstallerScriptLines = @()
    $removeHstwbInstallerScriptLines += "; Remove INSTALLDIR: assign"
    $removeHstwbInstallerScriptLines += "Assign INSTALLDIR: ""HstWBInstallerDir:Install"" REMOVE"
    $removeHstwbInstallerScriptLines += "; Remove PACKAGESDIR: assign"
    $removeHstwbInstallerScriptLines += "Assign PACKAGESDIR: ""HstWBInstallerDir:Packages"" REMOVE"

    foreach ($assignName in $globalAssigns.keys)
    {
        # get assign path and drive
        $assignDir = $globalAssigns.Get_Item($assignName)
        
        $removeHstwbInstallerScriptLines += ("; Remove {0}: assign, if it exists" -f $assignName)
        $removeHstwbInstallerScriptLines += ("Assign >NIL: EXISTS ""{0}:""" -f $assignName)
        $removeHstwbInstallerScriptLines += "IF NOT WARN"
        $removeHstwbInstallerScriptLines += ("  Assign >NIL: {0}: ""{1}"" REMOVE" -f $assignName, $assignDir)
        $removeHstwbInstallerScriptLines += "ENDIF"
    }
    
    $hstwbInstallDirAssignName = $globalAssigns.keys | Where-Object { $_ -match 'HstWBInstallerDir' } | Select-Object -First 1

    if (!$hstwbInstallDirAssignName)
    {
        Fail $hstwb ("Failed to run install. Global assigns doesn't containassign for 'HstWBInstallerDir' exist!")
    }

    $hstwbInstallDir = $globalAssigns.Get_Item($hstwbInstallDirAssignName)

    $removeHstwbInstallerScriptLines += "; Delete hstwb installer dir, if it exists"
    $removeHstwbInstallerScriptLines += "IF EXISTS ""$hstwbInstallDir"""
    $removeHstwbInstallerScriptLines += "  Delete >NIL: ""$hstwbInstallDir"" ALL"
    $removeHstwbInstallerScriptLines += "ENDIF"

    
    # write remove hstwb installer script
    $removeHstwbInstallerScriptFile = [System.IO.Path]::Combine($tempInstallDir, "Install-SelfInstall\S\Remove-HstWBInstaller")
    WriteAmigaTextLines $removeHstwbInstallerScriptFile $removeHstwbInstallerScriptLines 


    # copy prefs to install self install
    $selfInstallDir = Join-Path $tempInstallDir -ChildPath "Install-SelfInstall"
    Copy-Item -Path $prefsDir $selfInstallDir -recurse -force

    # update version in startup sequence files
    $startupSequenceFiles = @()
    $startupSequenceFiles += Get-ChildItem -Path $tempInstallDir -Filter 'Startup-Sequence.*' -Recurse
    $startupSequenceFiles | ForEach-Object { UpdateVersionAmigaTextFile $_.FullName $hstwb.Version }

    # write hstwb installer log file
    $installLogLines = BuildInstallLog $hstwb
    WriteAmigaTextLines $tempHstwbInstallerLogFile $installLogLines


    # hstwb uae run workbench dir
    $workbenchDir = ''
    if ($hstwb.Settings.Workbench.WorkbenchAdfDir -and (Test-Path -Path $hstwb.Settings.Workbench.WorkbenchAdfDir))
    {
        $workbenchDir = $hstwb.Settings.Workbench.WorkbenchAdfDir
    }
    
    # hstwb uae kickstart dir
    $kickstartDir = ''
    if ($hstwb.Settings.Kickstart.KickstartRomDir -and (Test-Path -Path $hstwb.Settings.Kickstart.KickstartRomDir))
    {
        $kickstartDir = $hstwb.Settings.Kickstart.KickstartRomDir
    }


    # create workbench directory in image directory, if it doesn't exist
    $imageWorkbenchDir = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "workbench"
    if (!(Test-Path -Path $imageWorkbenchDir))
    {
        mkdir $imageWorkbenchDir | Out-Null
    }

    # create kickstart directory in image directory, if it doesn't exist
    $imageKickstartDir = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "kickstart"
    if (!(Test-Path -Path $imageKickstartDir))
    {
        mkdir $imageKickstartDir | Out-Null
    }

    # create os39 directory in image directory, if it doesn't exist
    $imageOs39Dir = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "os39"
    if (!(Test-Path -Path $imageOs39Dir))
    {
        mkdir $imageOs39Dir | Out-Null
    }
    
    # create userpackages directory in image directory, if it doesn't exist
    $imageUserPackagesDir = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "userpackages"
    if (!(Test-Path -Path $imageUserPackagesDir))
    {
        mkdir $imageUserPackagesDir | Out-Null
    }

    # copy hstwb image setup to image dir
    $hstwbImageSetupDir = [System.IO.Path]::Combine($hstwb.Paths.SupportPath, "hstwb_image_setup")
    Copy-Item -Path "$hstwbImageSetupDir\*" $hstwb.Settings.Image.ImageDir -recurse -force

    # copy self install to image dir
    $selfInstallDir = [System.IO.Path]::Combine($hstwb.Paths.SupportPath, "self_install")
    Copy-Item -Path "$selfInstallDir\*" $hstwb.Settings.Image.ImageDir -recurse -force

    # copy support user packages to image dir
    $supportUserPackagesDir = Join-Path $hstwb.Paths.SupportPath -ChildPath "User Packages"
    Copy-Item -Path "$supportUserPackagesDir\*" $imageUserPackagesDir -recurse -force

    

    

    # read winuae hstwb installer config file
    $winuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "hstwb-installer.uae")
    $hstwbInstallerUaeWinuaeConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)

    # build winuae self install harddrives config
    $hstwbInstallerWinuaeSelfInstallHarddrivesConfigText = BuildWinuaeSelfInstallHarddrivesConfigText $hstwb $workbenchDir $kickstartDir $imageOs39Dir $imageUserPackagesDir


    # replace hstwb installer uae winuae configuration placeholders
    $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('use_gui=no', 'use_gui=yes')
    $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile)
    $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$WorkbenchAdfFile]', '')
    $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$Harddrives]', $hstwbInstallerWinuaeSelfInstallHarddrivesConfigText)
    $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$IsoFile]', '')
    
    # write hstwb installer uae winuae configuration file to image dir
    $hstwbInstallerUaeConfigFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "hstwb-installer.uae"
    [System.IO.File]::WriteAllText($hstwbInstallerUaeConfigFile, $hstwbInstallerUaeWinuaeConfigText)


    # read fs-uae hstwb installer config file
    $fsUaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.FsUaePath, "hstwb-installer.fs-uae")
    $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

    # build fs-uae self install harddrives config
    $hstwbInstallerFsUaeSelfInstallHarddrivesConfigText = BuildFsUaeSelfInstallHarddrivesConfigText $hstwb $workbenchDir $kickstartDir $imageOs39Dir $imageUserPackagesDir
    
    # replace hstwb installer fs-uae configuration placeholders
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile.Replace('\', '/'))
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $hstwbInstallerFsUaeSelfInstallHarddrivesConfigText)
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', '')
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
    
    # write hstwb installer fs-uae configuration file to image dir
    $hstwbInstallerFsUaeConfigFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "hstwb-installer.fs-uae"
    [System.IO.File]::WriteAllText($hstwbInstallerFsUaeConfigFile, $fsUaeHstwbInstallerConfigText)
    

    # set amiga os 3.9 iso file
    $isoFile = ''
    if ($hstwb.Settings.AmigaOS39.InstallAmigaOS39 -eq 'Yes' -and $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile)
    {
        $isoFile = $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile
    }


    #
    $emulatorArgs = ''
    if ($hstwb.Settings.Emulator.EmulatorFile -match 'fs-uae\.exe$')
    {
        # install hstwb installer fs-uae theme
        InstallHstwbInstallerFsUaeTheme $hstwb

        # build fs-uae install harddrives config
        $fsUaeInstallHarddrivesConfigText = BuildFsUaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $tempOs39Dir $tempUserPackagesDir $true

        # read fs-uae hstwb installer config file
        $fsUaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.FsUaePath, "hstwb-installer.fs-uae")
        $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

        # replace hstwb installer fs-uae configuration placeholders
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', $hstwb.Paths.WorkbenchAdfFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $fsUaeInstallHarddrivesConfigText)
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
        
        # write fs-uae hstwb installer config file to temp dir
        $tempFsUaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.TempPath, "hstwb-installer.fs-uae")
        [System.IO.File]::WriteAllText($tempFsUaeHstwbInstallerConfigFile, $fsUaeHstwbInstallerConfigText)
    
        # emulator args for fs-uae
        $emulatorArgs = """$tempFsUaeHstwbInstallerConfigFile"""
    }
    elseif ($hstwb.Settings.Emulator.EmulatorFile -match '(winuae\.exe|winuae64\.exe)$')
    {
        # build winuae install harddrives config
        $winuaeInstallHarddrivesConfigText = BuildWinuaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $tempOs39Dir $tempUserPackagesDir $true
    
        # read winuae hstwb installer config file
        $winuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "hstwb-installer.uae")
        $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)
    
        # replace winuae hstwb installer config placeholders
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', $hstwb.Paths.WorkbenchAdfFile)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$Harddrives]', $winuaeInstallHarddrivesConfigText)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile)
        
        # write winuae hstwb installer config file to temp install dir
        $tempWinuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.TempPath, "hstwb-installer.uae")
        [System.IO.File]::WriteAllText($tempWinuaeHstwbInstallerConfigFile, $winuaeHstwbInstallerConfigText)
    
        # emulator args for winuae
        $emulatorArgs = "-f ""$tempWinuaeHstwbInstallerConfigFile"""
    }
    else
    {
        Fail $hstwb ("Emulator file '{0}' is not supported" -f $hstwb.Settings.Emulator.EmulatorFile)
    }

    # print preparing installation done message
    Write-Host "Done."
        

    # show large harddrive warning
    ShowLargeHarddriveWarning $hstwb


    # print starting emulator message
    Write-Host ""
    Write-Host ("Starting emulator '{0}' to build self install image..." -f $hstwb.Emulator)


    # start emulator to run build self install
    $emulatorProcess = Start-Process $hstwb.Settings.Emulator.EmulatorFile $emulatorArgs -Wait -NoNewWindow

    # append temp hstwb installer log file to image hstwb installer log file
    if (Test-Path -Path $tempHstwbInstallerLogFile)
    {
        Get-Content $tempHstwbInstallerLogFile | Add-Content -Path $imageHstwbInstallerLogFile
    }

    # fail, if emulator doesn't return error code 0
    if ($emulatorProcess -and $emulatorProcess.ExitCode -ne 0)
    {
        Fail $hstwb ("Failed to run '" + $hstwb.Settings.Emulator.EmulatorFile + "' with arguments '$emulatorArgs'")
    }


    # fail, if install complete prefs file doesn't exists
    $installCompletePrefsFile = Join-Path $prefsDir -ChildPath 'Install-Complete'
    if (!(Test-Path -path $installCompletePrefsFile))
    {
        Fail $hstwb "WinUAE installation failed"
    }
}

# run build package installation
function RunBuildPackageInstallation($hstwb)
{
    # find packages to install
    $installPackages = FindPackagesToInstall $hstwb

    # extract packages and write install packages script, if there's packages to install
    if ($installPackages.Count -eq 0)
    {
        Write-Host ""
        Write-Host "Cancelled, no packages selected!" -ForegroundColor Yellow
        return
    }

    $outputPackageInstallationPath = FolderBrowserDialog "Select new directory for package installation" ${Env:USERPROFILE} $true

    # return, if package installation directory is null
    if ($outputPackageInstallationPath -eq $null)
    {
        Write-Host ""
        Write-Host "Cancelled, no package installation directory selected!" -ForegroundColor Yellow
        return
    }

    # show confirm overwrite dialog, if package installation directory is not empty
    if ((Get-ChildItem -Path $outputPackageInstallationPath).Count -gt 0)
    {
        if (!(ConfirmDialog "Overwrite files" ("Package installation directory '" + $outputPackageInstallationPath + "' is not empty.`r`n`r`nDo you want to overwrite files?")))
        {
            Write-Host ""
            Write-Host "Cancelled, package installation directory is not empty!" -ForegroundColor Yellow
            return
        }
    }

    # create package installation directory, if it doesn't exists
    if (!(Test-Path -Path $outputPackageInstallationPath))
    {
        mkdir $outputPackageInstallationPath | Out-Null
    }

    # print building package installation message
    Write-Host ""
    Write-Host "Building package installation to '$outputPackageInstallationPath'..."    

    # extract packages to temp packages dir
    ExtractPackages $hstwb $installPackages $outputPackageInstallationPath
    
    # build install package script lines
    $packageInstallationScriptLines = @()
    $packageInstallationScriptLines += ".KEY validate/s"
    $packageInstallationScriptLines += ".BRA {"
    $packageInstallationScriptLines += ".KET }"
    $packageInstallationScriptLines += ''
    $packageInstallationScriptLines += "; Package Installation"
    $packageInstallationScriptLines += "; --------------------"
    $packageInstallationScriptLines += "; Author: Henrik Noerfjand Stengaard"
    $packageInstallationScriptLines += ("; Date: {0}" -f (Get-Date -format "yyyy-MM-dd"))
    $packageInstallationScriptLines += ";"
    $packageInstallationScriptLines += "; An package installation script generated by HstWB Installer to install selected packages."
    $packageInstallationScriptLines += ""
    $packageInstallationScriptLines += "; Add assigns and set environment variables for package installation"
    $packageInstallationScriptLines += "SetEnv packagesdir ""``CD``"""
    $packageInstallationScriptLines += "Assign PACKAGESDIR: ""`$packagesdir"""
    $packageInstallationScriptLines += "Assign INSTALLDIR: ""`$packagesdir"""
    $packageInstallationScriptLines += "Assign C: ""INSTALLDIR:C"" ADD"
    $packageInstallationScriptLines += 'Assign SYSTEMDIR: SYS:'
    $packageInstallationScriptLines += "SetEnv TZ MST7"
    $packageInstallationScriptLines += ""
    $packageInstallationScriptLines += "; Copy reqtools prefs to env, if it doesn't exist"
    $packageInstallationScriptLines += "IF NOT EXISTS ""ENV:ReqTools.prefs"""
    $packageInstallationScriptLines += "  copy >NIL: ""ReqTools.prefs"" ""ENV:"""
    $packageInstallationScriptLines += "ENDIF"
    $packageInstallationScriptLines += ""
    $packageInstallationScriptLines += BuildInstallPackagesScriptLines $hstwb $installPackages
    $packageInstallationScriptLines += ""
    $packageInstallationScriptLines += "; Remove assigns for package installation"
    $packageInstallationScriptLines += "Assign PACKAGESDIR: ""`$packagesdir"" REMOVE"
    $packageInstallationScriptLines += "Assign C: ""INSTALLDIR:C"" REMOVE"
    $packageInstallationScriptLines += "Assign INSTALLDIR: ""`$packagesdir"" REMOVE"
    $packageInstallationScriptLines += "Assign >NIL: EXISTS ""SYSTEMDIR:"""
    $packageInstallationScriptLines += "IF NOT WARN"
    $packageInstallationScriptLines += "  Assign SYSTEMDIR: SYS: REMOVE"
    $packageInstallationScriptLines += "ENDIF"
    $packageInstallationScriptLines += ""
    $packageInstallationScriptLines += "echo """""
    $packageInstallationScriptLines += "echo ""Package installation is complete."""
    $packageInstallationScriptLines += "echo """""
    $packageInstallationScriptLines += "ask ""Press ENTER to continue"""
    $packageInstallationScriptLines += ""
    $packageInstallationScriptLines += "; End"
    $packageInstallationScriptLines += "LAB end"


    # write install packages script
    $installPackagesScriptFile = [System.IO.Path]::Combine($outputPackageInstallationPath, "Package-Installation")
    WriteAmigaTextLines $installPackagesScriptFile $packageInstallationScriptLines 


    # copy amiga package installation files
    $amigaPackageInstallationDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "packageinstallation")
    Copy-Item -Path "$amigaPackageInstallationDir\*" $outputPackageInstallationPath -recurse -force


    # copy amiga packages dir
    $amigaPackagesDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "packages")
    Copy-Item -Path "$amigaPackagesDir\*" $outputPackageInstallationPath -recurse -force
}


# run build user package installation
function RunBuildUserPackageInstallation($hstwb)
{
    $outputUserPackageInstallationPath = FolderBrowserDialog "Select new directory for user package installation" ${Env:USERPROFILE} $true
    
    # return, if user package installation directory is null
    if ($outputUserPackageInstallationPath -eq $null)
    {
        Write-Host ""
        Write-Host "Cancelled, no user package installation directory selected!" -ForegroundColor Yellow
        return
    }

    # show confirm overwrite dialog, if user package installation directory is not empty
    if ((Get-ChildItem -Path $outputUserPackageInstallationPath).Count -gt 0)
    {
        if (!(ConfirmDialog "Overwrite files" ("User package installation directory '" + $outputUserPackageInstallationPath + "' is not empty.`r`n`r`nDo you want to overwrite files?")))
        {
            Write-Host ""
            Write-Host "Cancelled, user package installation directory is not empty!" -ForegroundColor Yellow
            return
        }
    }

    # create user package installation directory, if it doesn't exists
    if (!(Test-Path -Path $outputUserPackageInstallationPath))
    {
        mkdir $outputUserPackageInstallationPath | Out-Null
    }

    # print building user package installation message
    Write-Host ""
    Write-Host "Building user package installation to '$outputUserPackageInstallationPath'..."    
    
    # copy amiga packages
    $amigaPackagesDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "packages")
    Copy-Item -Path "$amigaPackagesDir\*" $outputUserPackageInstallationPath -recurse -force
    
    # copy amiga user packages
    $amigaUserPackagesDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "userpackages")
    Copy-Item -Path "$amigaUserPackagesDir\*" $outputUserPackageInstallationPath -recurse -force

    # copy amiga user package installation
    $amigaUserPackageInstallationDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "userpackageinstallation")
    Copy-Item -Path "$amigaUserPackageInstallationDir\*" $outputUserPackageInstallationPath -recurse -force
}


# save
function Save($hstwb)
{
    WriteIniFile $hstwb.Paths.SettingsFile $hstwb.Settings
    WriteIniFile $hstwb.Paths.AssignsFile $hstwb.Assigns
}


# fail
function Fail($hstwb, $message)
{
    if(test-path -path $hstwb.Paths.TempPath)
    {
        Remove-Item -Recurse -Force $hstwb.Paths.TempPath
    }

    Write-Error $message
    Write-Host ""
    Write-Host "Press enter to continue"
    Read-Host
    exit 1
}


# resolve paths
$kickstartRomHashesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("Kickstart\kickstart-rom-hashes.csv")
$workbenchAdfHashesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("Workbench\workbench-adf-hashes.csv")
$packagesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("packages")
$winuaePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("winuae")
$fsUaePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("fs-uae")
$amigaPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("amiga")
$licensesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("licenses")
$scriptsPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("scripts")
$tempPath = [System.IO.Path]::Combine($env:TEMP, "HstWB-Installer_" + [System.IO.Path]::GetRandomFileName())
$supportPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("support")

if (!$settingsDir)
{
    $settingsDir = Join-Path $env:LOCALAPPDATA -ChildPath 'HstWB Installer'
}
$settingsDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($settingsDir)
$settingsFile = Join-Path $settingsDir -ChildPath "hstwb-installer-settings.ini"
$assignsFile = Join-Path $settingsDir -ChildPath "hstwb-installer-assigns.ini"

$host.ui.RawUI.WindowTitle = "HstWB Installer Run v{0}" -f (HstwbInstallerVersion)


try
{
    # fail, if settings file doesn't exist
    if (!(test-path -path $settingsFile))
    {
        Fail $hstwb ("Error: Settings file '$settingsFile' doesn't exist!")
    }


    # fail, if assigns file doesn't exist
    if (!(test-path -path $assignsFile))
    {
        Fail $hstwb ("Error: Assigns file '$assignsFile' doesn't exist!")
    }


    $hstwb = @{
        'Version' = HstwbInstallerVersion;
        'Paths' = @{
            'KickstartRomHashesFile' = $kickstartRomHashesFile;
            'WorkbenchAdfHashesFile' = $workbenchAdfHashesFile;
            'AmigaPath' = $amigaPath;
            'WinuaePath' = $winuaePath;
            'FsUaePath' = $fsUaePath;
            'LicensesPath' = $licensesPath;
            'PackagesPath' = $packagesPath;
            'SettingsFile' = $settingsFile;
            'ScriptsPath' = $scriptsPath;
            'TempPath' = $tempPath;
            'AssignsFile' = $assignsFile;
            'SettingsDir' = $settingsDir;
            'SupportPath' = $supportPath
        };
        'Packages' = ReadPackages $packagesPath;
        'Settings' = ReadIniFile $settingsFile;
        'Assigns' = ReadIniFile $assignsFile
    }

    # read kickstart rom hashes
    if (Test-Path -Path $kickstartRomHashesFile)
    {
        $kickstartRomHashes = @()
        $kickstartRomHashes += (Import-Csv -Delimiter ';' $kickstartRomHashesFile)
        $hstwb.KickstartRomHashes = $kickstartRomHashes
    }
    else
    {
        throw ("Kickstart rom data file '{0}' doesn't exist" -f $kickstartRomHashesFile)
    }

    # read workbench adf hashes
    if (Test-Path -Path $workbenchAdfHashesFile)
    {
        $workbenchAdfHashes = @()
        $workbenchAdfHashes += (Import-Csv -Delimiter ';' $workbenchAdfHashesFile)
        $hstwb.WorkbenchAdfHashes = $workbenchAdfHashes
    }
    else
    {
        throw ("Workbench adf data file '{0}' doesn't exist" -f $workbenchAdfHashesFile)
    }
    
    # upgrade settings and assigns
    UpgradeSettings $hstwb
    UpgradeAssigns $hstwb
    
    # detect user packages
    $hstwb.UserPackages = DetectUserPackages $hstwb
    
    # find workbench adfs
    FindWorkbenchAdfs $hstwb

    # find kickstart roms
    FindKickstartRoms $hstwb
        
    # update packages and assigns
    UpdatePackages $hstwb
    UpdateUserPackages $hstwb
    UpdateAssigns $hstwb
        
    # find best matching kickstart rom set, if kickstart rom set doesn't exist
    if (($hstwb.KickstartRomHashes | Where-Object { $_.Set -eq $hstwb.Settings.Kickstart.KickstartRomSet }).Count -eq 0)
    {
        # set new kickstart rom set and save
        $hstwb.Settings.Kickstart.KickstartRomSet = FindBestMatchingKickstartRomSet $hstwb
    }

    # find best matching workbench adf set, if workbench adf set doesn't exist
    if (($hstwb.WorkbenchAdfHashes | Where-Object { $_.Set -eq $hstwb.Settings.Workbench.WorkbenchAdfSet }).Count -eq 0)
    {
        # set new workbench adf set and save
        $hstwb.Settings.Workbench.WorkbenchAdfSet = FindBestMatchingWorkbenchAdfSet $hstwb
    }
    
    # save settings and assigns
    Save $hstwb

    # set and validate emulator, is install mode is test, install or build self install
    if ($hstwb.Settings.Installer.Mode -match "^(Test|Install|BuildSelfInstall)$")
    {
        # fail, if EmulatorFile parameter doesn't exist in settings file or file doesn't exist
        if (!$hstwb.Settings.Emulator.EmulatorFile -or ($hstwb.Settings.Emulator.EmulatorFile -match '^.+$' -and !(test-path -path $hstwb.Settings.Emulator.EmulatorFile)))
        {
            Fail $hstwb "Error: EmulatorFile parameter doesn't exist in settings file or file doesn't exist!"
        }

        
        # emulator name
        $emulatorName = DetectEmulatorName $hstwb.Settings.Emulator.EmulatorFile
        
        # fail, if emulator file is not supported
        if (!$emulatorName)
        {
            Fail $hstwb "Error: Emulator file '{0}' is not supported!"
        }

        # set emulator to emulator name and file
        $hstwb.Emulator = "{0} ({1})" -f $emulatorName, $hstwb.Settings.Emulator.EmulatorFile
    }
    else
    {
        # set emulator
        $hstwb.Emulator = ''
    }
    
    # validate settings
    if (!(ValidateSettings $hstwb.Settings))
    {
        Fail $hstwb "Validate settings failed"
    }

    # validate assigns
    if (!(ValidateAssigns $hstwb.Assigns))
    {
        Fail $hstwb "Validate assigns failed"
    }

    # change kickstart rom hashes to kickstart rom set hashes
    $kickstartRomSetHashes = @()
    $kickstartRomSetHashes += $hstwb.KickstartRomHashes | Where-Object { $_.Set -eq $hstwb.Settings.Kickstart.KickstartRomSet }
    $hstwb.KickstartRomHashes = $kickstartRomSetHashes
    
    # change workbench adf hashes to workbench adf set hashes
    $workbenchAdfSetHashes = @()
    $workbenchAdfSetHashes += $hstwb.WorkbenchAdfHashes | Where-Object { $_.Set -eq $hstwb.Settings.Workbench.WorkbenchAdfSet }
    $hstwb.WorkbenchAdfHashes = $workbenchAdfSetHashes

    # fail, if kickstart rom hashes is empty 
    if ($hstwb.KickstartRomHashes.Count -eq 0)
    {
        Fail ("Kickstart rom set '" + $hstwb.Settings.Kickstart.KickstartRomSet + "' doesn't exist!")
    }
    
    # fail, if workbench adf hashes is empty 
    if ($hstwb.WorkbenchAdfHashes.Count -eq 0)
    {
        Fail ("Workbench adf set '" + $hstwb.Settings.Workbench.WorkbenchAdfSet + "' doesn't exist!")
    }

    # print title and settings
    $versionPadding = new-object System.String('-', ($hstwb.Version.Length + 2))
    Write-Host ("-------------------{0}" -f $versionPadding) -foregroundcolor "Yellow"
    Write-Host ("HstWB Installer Run v{0}" -f $hstwb.Version) -foregroundcolor "Yellow"
    Write-Host ("-------------------{0}" -f $versionPadding) -foregroundcolor "Yellow"
    Write-Host ""
    PrintSettings $hstwb
    Write-Host ""
        
    # find workbench 3.1 adf and a1200 kickstart rom file, is install mode is test, install or build self install
    if ($hstwb.Settings.Installer.Mode -match "^(Test|Install|BuildSelfInstall)$")
    {
        # find kickstart 3.1 a1200 rom
        $kickstartRomHash = $hstwb.KickstartRomHashes | Where-Object { $_.Name -eq 'Kickstart 3.1 (40.068) (A1200) Rom' -and $_.File } | Select-Object -First 1

        # fail, if kickstart rom hash doesn't exist
        if (!$kickstartRomHash)
        {
            Fail $hstwb ("Kickstart set '" + $hstwb.Settings.Kickstart.KickstartRomSet + "' doesn't have Kickstart 3.1 (40.068) (A1200) rom!")
        }

        # set kickstart rom file
        $hstwb.Paths.KickstartRomFile = $kickstartRomHash.File

        # print kickstart rom hash file
        Write-Host ("Using Kickstart 3.1 (40.068) (A1200) rom: '" + $kickstartRomHash.File + "'")

        # kickstart rom key
        $kickstartRomKeyFile = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($kickstartRomHash.File), "rom.key")

        # fail, if kickstart rom hash is encrypted and kickstart rom key file doesn't exist
        if ($kickstartRomHash.Encrypted -eq 'Yes' -and !(test-path -path $kickstartRomKeyFile))
        {
            Fail $hstwb ("Kickstart set '" + $hstwb.Settings.Kickstart.KickstartRomSet + "' doesn't have rom.key!")
        }


        $amigaOS39Iso = $false
        $workbench31Adf = $false
        
        if ($hstwb.Settings.AmigaOS39.InstallAmigaOS39 -match 'Yes')
        {
            if ($hstwb.Settings.AmigaOS39.AmigaOS39IsoFile -and (Test-Path -Path $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile))
            {
                $amigaOS39Iso = $true
                Write-Host ("Using Amiga OS 3.9 iso file for loading Workbench system files: '{0}'" -f $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile)
            }
            else
            {
                Fail $hstwb ("Amiga OS 3.9 iso file '{0}' doesn't exist!" -f $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile)
            }
        }

        # find and set workbench adf set hashes, if installing workbench
        if ($hstwb.Settings.Workbench.InstallWorkbench -eq 'Yes' -and !$amigaOS39Iso)
        {
                # find workbench 3.1 workbench disk
            $workbenchAdfHash = $hstwb.WorkbenchAdfHashes | Where-Object { $_.Name -eq 'Workbench 3.1 Workbench Disk' -and $_.File } | Select-Object -First 1
            
            if ($workbenchAdfHash)
            {
                $workbench31Adf = $true

                # set workbench adf file
                $hstwb.Paths.WorkbenchAdfFile = $workbenchAdfHash.File

                # print workbench adf hash file
                Write-Host ("Using Workbench 3.1 Workbench Disk adf file for loading Workbench system files: '" + $workbenchAdfHash.File + "'")
            }
            else
            {
                Fail $hstwb ("Workbench set '" + $hstwb.Settings.Workbench.WorkbenchAdfSet + "' doesn't have Workbench 3.1 Workbench Disk!")
            }
        }
        else
        {
            $hstwb.Paths.WorkbenchAdfFile = ''
        }

        # fail, if neither amiga os 3.9 iso file or workbench 3.1 adf file is present
        if (!$amigaOS39Iso -and !$workbench31Adf)
        {
            Fail $hstwb "Amiga OS 3.9 iso file or Workbench 3.1 adf file is required to run HstWB Installer!"
        }
    }


    # create temp path
    if(!(test-path -path $hstwb.Paths.TempPath))
    {
        mkdir $hstwb.Paths.TempPath | Out-Null
    }


    # installer mode
    switch ($hstwb.Settings.Installer.Mode)
    {
        "Test" { RunTest $hstwb }
        "Install" { RunInstall $hstwb }
        "BuildSelfInstall" { RunBuildSelfInstall $hstwb }
        "BuildPackageInstallation" { RunBuildPackageInstallation $hstwb }
        "BuildUserPackageInstallation" { RunBuildUserPackageInstallation $hstwb }
    }


    # remove temp path
    Remove-Item -Recurse -Force $hstwb.Paths.TempPath


    # print done message 
    Write-Host ""
    Write-Host "Done."
    Write-Host ""
    Write-Host "Press enter to continue"
    Read-Host
}
catch
{
    # remove temp path
    if (Test-Path -Path $hstwb.Paths.TempPath)
    {
        Remove-Item -Recurse -Force $hstwb.Paths.TempPath
    }

    $errorFormatingString = "{0} : {1}`n{2}`n" +
    "    + CategoryInfo          : {3}`n" +
    "    + FullyQualifiedErrorId : {4}`n"

    $errorFields = $_.InvocationInfo.MyCommand.Name,
    $_.ErrorDetails.Message,
    $_.InvocationInfo.PositionMessage,
    $_.CategoryInfo.ToString(),
    $_.FullyQualifiedErrorId

    $message = $errorFormatingString -f $errorFields
    $logFile = Join-Path $settingsDir -ChildPath "hstwb_installer.log"
    Add-Content $logFile ("{0} | ERROR | {1}" -f (Get-Date -Format s), $message) -Encoding UTF8
    Write-Host ""
    Write-Error "HstWB Installer Setup Failed: $message"
    Write-Host ""
    Write-Host "Press enter to continue"
    Read-Host
}