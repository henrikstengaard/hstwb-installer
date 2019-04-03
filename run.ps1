# HstWB Installer Run
# -------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2019-04-03
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


function BuildPackagesMenuScriptLines($hstwb, $dependencyPackageNamesIndex, $installPackageScripts)
{
    $packagesMenuScriptLines = @()

    $packagesMenuScriptLines += "echo """" NOLINE >T:packagesmenu"
    $packagesMenuScriptLines += 'IF "$amigaosversion" EQ "All"'
    $packagesMenuScriptLines += '  set amigaostext "All Amiga OS versions"'
    $packagesMenuScriptLines += 'ELSE'
    $packagesMenuScriptLines += '  set amigaostext "Amiga OS $amigaosversion"'
    $packagesMenuScriptLines += 'ENDIF'
    $packagesMenuScriptLines += "echo ""Select package filtering: `$amigaostext"" >>T:packagesmenu"
    $packagesMenuScriptLines += "echo ""============================================================"" >>T:packagesmenu"

    foreach ($installPackageScript in $installPackageScripts)
    {
        $packagesMenuScriptLines += ("IF EXISTS ""T:{0}""" -f $installPackageScript.Package.Id)
        $packagesMenuScriptLines += "  echo ""Install"" NOLINE >>T:packagesmenu"
        $packagesMenuScriptLines += "ELSE"
        $packagesMenuScriptLines += "  echo ""Skip   "" NOLINE >>T:packagesmenu"
        $packagesMenuScriptLines += "ENDIF"
        $hasDependenciesIndicator = if ($installPackageScript.Package.Dependencies.Count -gt 0) { ' (**)' } else { '' }
        $packagesMenuScriptLines += ("echo "" : {0}{1}"" >>T:packagesmenu" -f $installPackageScript.Package.FullName, $hasDependenciesIndicator)
    }

    $packagesMenuScriptLines += "echo ""============================================================"" >>T:packagesmenu"
    $packagesMenuScriptLines += "echo ""Help"" >>T:packagesmenu"
    $packagesMenuScriptLines += "echo ""Install all packages"" >>T:packagesmenu"
    $packagesMenuScriptLines += "echo ""Skip all packages"" >>T:packagesmenu"
    $packagesMenuScriptLines += "echo ""View readme"" >>T:packagesmenu"
    $packagesMenuScriptLines += "echo ""Edit assigns"" >>T:packagesmenu"
    $packagesMenuScriptLines += "echo ""Start package installation"" >>T:packagesmenu"

    if ($hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation")
    {
        $packagesMenuScriptLines += "echo ""Quit"" >>T:packagesmenu"
    }
    else
    {
        $packagesMenuScriptLines += "echo ""Skip package installation"" >>T:packagesmenu"
    }

    $packagesMenuScriptLines += ""
    $packagesMenuScriptLines += "set packagesmenu """""
    $packagesMenuScriptLines += "set packagesmenu ""``RequestList TITLE=""Package installation"" LISTFILE=""T:packagesmenu"" WIDTH=640 LINES=24``"""
    $packagesMenuScriptLines += "delete >NIL: T:packagesmenu"

    $packageMenuOption = 1
    $packagesMenuScriptLines += ''
    $packagesMenuScriptLines += '; select package filtering option'
    $packagesMenuScriptLines += ("IF ""`$packagesmenu"" eq ""{0}""" -f $packageMenuOption)
    $packagesMenuScriptLines += "  SKIP packagefilteringmenu"
    $packagesMenuScriptLines += "ENDIF"

    $packageMenuOption++
    foreach($installPackageScript in $installPackageScripts)
    {
        $package = $installPackageScript.Package

        $packageMenuOption++
        $packagesMenuScriptLines += ""
        $packagesMenuScriptLines += ("; install package menu '{0}' option" -f $package.FullName)
        $packagesMenuScriptLines += ("IF ""`$packagesmenu"" eq ""{0}""" -f $packageMenuOption)
        $packagesMenuScriptLines += "  ; skip package, if set to install. otherwise set package to install"
        $packagesMenuScriptLines += ("  IF EXISTS ""T:{0}""" -f $installPackageScript.Package.Id)

        $packageName = $installPackageScript.Package.Name.ToLower()

        # show package dependency warning, if package has dependencies
        if ($dependencyPackageNamesIndex.ContainsKey($packageName))
        {
            $packagesMenuScriptLines += "    set showdependencywarning ""0"""
            $packagesMenuScriptLines += "    set dependencypackagenames """""
            
            # list selected package names that has dependencies to package
            $dependencyPackageNames = @()
            $dependencyPackageNames += $dependencyPackageNamesIndex.Get_Item($packageName)

            foreach($dependencyPackageName in $dependencyPackageNames)
            {
                $dependencyPackage = $hstwb.Packages[$dependencyPackageName]

                # add script lines to set show dependency warning, if dependency package is selected
                $packagesMenuScriptLines += ("    ; set show dependency warning, if package '{0}' is set to install" -f $dependencyPackage.FullName)
                $packagesMenuScriptLines += ("    IF EXISTS ""T:{0}""" -f $dependencyPackage.Id)
                $packagesMenuScriptLines += "      set showdependencywarning ""1"""
                $packagesMenuScriptLines += "      IF ""`$dependencypackagenames"" EQ """""
                $packagesMenuScriptLines += ("        set dependencypackagenames ""{0}""" -f $dependencyPackage.Name)
                $packagesMenuScriptLines += "      ELSE"
                $packagesMenuScriptLines += ("        set dependencypackagenames ""`$dependencypackagenames, {0}""" -f $dependencyPackage.Name)
                $packagesMenuScriptLines += "      ENDIF"
                $packagesMenuScriptLines += "    ENDIF"
            }

            # add script lines to show package dependency warning, if selected packages has dependencies to it
            $packagesMenuScriptLines += "    set skippackage ""1"""
            $packagesMenuScriptLines += "    IF `$showdependencywarning EQ 1 VAL"
            $packagesMenuScriptLines += ("      set skippackage ``RequestChoice ""Package dependency warning"" ""Warning! Package(s) '`$dependencypackagenames' has a*Ndependency to '{0}' and skipping it*Nmay cause issues when installing packages.*N*NAre you sure you want to skip*Npackage '{0}'?"" ""Yes|No""``" -f $installPackageScript.Package.Name)
            $packagesMenuScriptLines += "    ENDIF"
            $packagesMenuScriptLines += "    IF `$skippackage EQ 1 VAL"
            $packagesMenuScriptLines += ("      delete >NIL: ""T:{0}""" -f $installPackageScript.Package.Id)
            $packagesMenuScriptLines += "    ENDIF"
        }
        else
        {
            # deselect package, if no other packages has dependencies to it
            $packagesMenuScriptLines += ("    delete >NIL: ""T:{0}""" -f $installPackageScript.Package.Id)
        }

        $packagesMenuScriptLines += "  ELSE"

        $dependencyPackageNames = GetDependencyPackageNames $hstwb $installPackageScript.Package | ForEach-Object { $_.ToLower() }

        foreach($dependencyPackageName in $dependencyPackageNames)
        {
            $dependencyPackage = $hstwb.Packages[$dependencyPackageName]

            $packagesMenuScriptLines += ("    ; Select dependency package '{0}'" -f $dependencyPackage.FullName)
            $packagesMenuScriptLines += ("    echo """" NOLINE >""T:{0}""" -f $dependencyPackage.Id)
        }
        
        $packagesMenuScriptLines += ("    ; Select package '{0}'" -f $installPackageScript.Package.FullName)
        $packagesMenuScriptLines += ("    echo """" NOLINE >""T:{0}""" -f $installPackageScript.Package.Id)
        $packagesMenuScriptLines += "  ENDIF"
        $packagesMenuScriptLines += "ENDIF"
    }

    # install packages option and skip back to install packages menu 
    $packageMenuOption += 2
    $packagesMenuScriptLines += ''
    $packagesMenuScriptLines += '; help option'
    $packagesMenuScriptLines += ('IF "$packagesmenu" eq "{0}"' -f $packageMenuOption)
    $packagesMenuScriptLines += '  IF EXISTS "PACKAGESDIR:Help/Package-Installation.txt"'
    $packagesMenuScriptLines += '    Lister "PACKAGESDIR:Help/Package-Installation.txt" >NIL:'
    $packagesMenuScriptLines += '  ELSE'
    $packagesMenuScriptLines += '    RequestChoice "Error" "ERROR: Help file ''PACKAGESDIR:Help/Package-Installation.txt'' doesn''t exist!"'
    $packagesMenuScriptLines += '  ENDIF'
    $packagesMenuScriptLines += "  SKIP BACK installpackagesmenu"
    $packagesMenuScriptLines += "ENDIF"

    $packageMenuOption++
    $packagesMenuScriptLines += ''
    $packagesMenuScriptLines += '; install all packages option'
    $packagesMenuScriptLines += ("IF ""`$packagesmenu"" eq ""{0}""" -f $packageMenuOption)
    $packagesMenuScriptLines += "  SKIP installallpackages"
    $packagesMenuScriptLines += "ENDIF"

    $packageMenuOption++
    $packagesMenuScriptLines += ''
    $packagesMenuScriptLines += '; skip all packages option'
    $packagesMenuScriptLines += ("IF ""`$packagesmenu"" eq ""{0}""" -f $packageMenuOption)
    $packagesMenuScriptLines += "  SKIP skipallpackages"
    $packagesMenuScriptLines += "ENDIF"

    $packageMenuOption++
    $packagesMenuScriptLines += ''
    $packagesMenuScriptLines += '; view readme option'
    $packagesMenuScriptLines += ("IF ""`$packagesmenu"" eq ""{0}""" -f $packageMenuOption)
    $packagesMenuScriptLines += "  SKIP viewreadmemenu"
    $packagesMenuScriptLines += "ENDIF"

    $packageMenuOption++
    $packagesMenuScriptLines += ''
    $packagesMenuScriptLines += '; edit assigns option'
    $packagesMenuScriptLines += ("IF ""`$packagesmenu"" eq ""{0}""" -f $packageMenuOption)
    $packagesMenuScriptLines += "  SKIP editassignsmenu"
    $packagesMenuScriptLines += "ENDIF"

    $packageMenuOption++
    $packagesMenuScriptLines += ''
    $packagesMenuScriptLines += '; install packages option'
    $packagesMenuScriptLines += ("IF ""`$packagesmenu"" eq ""{0}""" -f $packageMenuOption)
    $packagesMenuScriptLines += "  set selectedpackagescount 0"
    foreach ($installPackageScript in $installPackageScripts)
    {
        $packagesMenuScriptLines += ("  IF EXISTS ""T:{0}""" -f $installPackageScript.Package.Id)
        $packagesMenuScriptLines += "    set selectedpackagescount ``eval `$selectedpackagescount + 1``"
        $packagesMenuScriptLines += "  ENDIF"
    }
    $packagesMenuScriptLines += "  set confirm ``RequestChoice ""Start package installation"" ""Do you want to install `$selectedpackagescount package(s)?"" ""Yes|No""``"
    $packagesMenuScriptLines += "  IF ""`$confirm"" EQ ""1"""
    $packagesMenuScriptLines += "    SKIP installpackages"
    $packagesMenuScriptLines += "  ENDIF"
    $packagesMenuScriptLines += "ENDIF"

    $packageMenuOption++
    $packagesMenuScriptLines += ""
    if ($hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation")
    {
        $packagesMenuScriptLines += ("IF ""`$packagesmenu"" eq ""{0}""" -f $packageMenuOption)
        $packagesMenuScriptLines += "  SKIP end"
        $packagesMenuScriptLines += "ENDIF"
    }
    else
    {
        $packagesMenuScriptLines += ("IF ""`$packagesmenu"" eq ""{0}""" -f $packageMenuOption)
        $packagesMenuScriptLines += "  set confirm ``RequestChoice ""Skip package installation"" ""Do you want to skip package installation?"" ""Yes|No""``"
        $packagesMenuScriptLines += "  IF ""`$confirm"" EQ ""1"""
        $packagesMenuScriptLines += "    SKIP end"
        $packagesMenuScriptLines += "  ENDIF"
        $packagesMenuScriptLines += "ENDIF"
    }

    $packagesMenuScriptLines += ""
    $packagesMenuScriptLines += "SKIP BACK installpackagesmenu"
    
    return $packagesMenuScriptLines
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
        $installPackagesScriptLines += Get-Content (Join-Path $hstwb.Paths.AmigaPath -ChildPath "packages\S\Detect-AmigaOS")
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += Get-Content (Join-Path $hstwb.Paths.AmigaPath -ChildPath "packages\S\SelectAssignDir")
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
    }
    
    # global assigns
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
        # build dependency package names index
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

        # build amiga os versions
        $amigaOsVersionsIndex = @{}
        foreach ($installPackageScript in ($installPackageScripts | Where-Object { $_.Package.AmigaOsVersions }))
        {
            $installPackageScript.Package.AmigaOsVersions | ForEach-Object { $amigaOsVersionsIndex[$_] = $true }
        }
        $amigaOsVersions = @("All") + ($amigaOsVersionsIndex.Keys | Sort-Object -Descending)


        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; verify amiga os'
        $installPackagesScriptLines += '; ---------------'
        $installPackagesScriptLines += 'LAB verifyamigaos'
        $installPackagesScriptLines += ''

        foreach ($amigaOsVersion in ($amigaOsVersions | Where-Object { $_ -notmatch 'All' }))
        {
            $installPackagesScriptLines += ('IF "$amigaosversion" EQ "{0}"' -f $amigaOsVersion)
            $installPackagesScriptLines += '  SKIP resetpackages'
            $installPackagesScriptLines += 'ENDIF'
        }

        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; set amiga os version to ''All'''
        $installPackagesScriptLines += 'set amigaosversion "All"'
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; show auto-detect amiga os version warning'
        $installPackagesScriptLines += 'RequestChoice "Auto-detect Amiga OS version" "WARNING: Package installation could not auto-detect*NAmiga OS version or the detected Amiga OS version*Ndoesn''t have any packages filtering.*NAmiga OS package filtering is therefore set*Nto all Amiga OS versions.*NThis means that not all packages may work*Ncorrectly with the Amiga OS installed.*NUse *"Select package filtering*" to*Nshow only packages that matches the*NAmiga OS installed." "OK"'
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP resetpackages'



        $packagesMenuScriptLines = @()

        $resetPackagesLines = @()

        foreach($installPackageScript in $installPackageScripts)
        {
            $resetPackagesLines += ("; Reset package '{0}'" -f $installPackageScript.Package.FullName)
            $resetPackagesLines += ("IF EXISTS ""T:{0}""" -f $installPackageScript.Package.Id)
            $resetPackagesLines += ("  delete >NIL: ""T:{0}""" -f $installPackageScript.Package.Id)
            $resetPackagesLines += "ENDIF"
        }
    
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; Install packages menu'
        $installPackagesScriptLines += '; ---------------------'
        $installPackagesScriptLines += 'LAB installpackagesmenu'
        $installPackagesScriptLines += ''

        $installAllPackagesLines = @()
        $skipAllPackagesLines = @()
        
        foreach ($amigaOsVersion in $amigaOsVersions)
        {
            $amigaOsMenuId = CalculateMd5FromText ("AmigaOsMenu:{0}" -f $amigaOsVersion)
            $installPackagesScriptLines += ('IF "$amigaosversion" EQ "{0}"' -f $amigaOsVersion)
            $installPackagesScriptLines += ('  SKIP {0}' -f $amigaOsMenuId)
            $installPackagesScriptLines += 'ENDIF'

            $installAllPackagesLines += ''
            $installAllPackagesLines += ('; install all packages ''{0}''' -f $amigaOsVersion)
            $installAllPackagesLines += ('IF "$amigaosversion" EQ "{0}"' -f $amigaOsVersion)

            $skipAllPackagesLines += ''
            $skipAllPackagesLines += ('; skip all packages ''{0}''' -f $amigaOsVersion)
            $skipAllPackagesLines += ('IF "$amigaosversion" EQ "{0}"' -f $amigaOsVersion)

            $packagesMenuScriptLines += ""
            $packagesMenuScriptLines += ('; amiga os menu ''{0}''' -f $amigaOsVersion)
            $packagesMenuScriptLines += ('LAB {0}' -f $amigaOsMenuId)

            $amigaOsVersionPackageScripts = @()
            $amigaOsVersionPackageScripts += $installPackageScripts | Where-Object { $amigaOsVersion -eq 'All' -or ($_.Package.AmigaOsVersions -and $_.Package.AmigaOsVersions -contains $amigaOsVersion) }

            # build reset, install all and skip all packages
            foreach ($packageScript in $amigaOsVersionPackageScripts)
            {
                $installAllPackagesLines += ("  ; install package '{0}'" -f $packageScript.Package.FullName)
                $installAllPackagesLines += ("  IF NOT EXISTS ""T:{0}""" -f $packageScript.Package.Id)
                $installAllPackagesLines += ("    echo """" NOLINE >""T:{0}""" -f $packageScript.Package.Id)
                $installAllPackagesLines += "  ENDIF"

                $skipAllPackagesLines += ("  ; skip package '{0}'" -f $packageScript.Package.FullName)
                $skipAllPackagesLines += ("  IF EXISTS ""T:{0}""" -f $packageScript.Package.Id)
                $skipAllPackagesLines += ("    delete >NIL: ""T:{0}""" -f $packageScript.Package.Id)
                $skipAllPackagesLines += "  ENDIF"
            }

            $installAllPackagesLines += 'ENDIF'
            $skipAllPackagesLines += 'ENDIF'

            $packagesMenuScriptLines += BuildPackagesMenuScriptLines $hstwb $dependencyPackageNamesIndex $amigaOsVersionPackageScripts
        }

        $installPackagesScriptLines += $packagesMenuScriptLines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; select package filtering'
        $installPackagesScriptLines += '; ------------------------'
        $installPackagesScriptLines += 'LAB packagefilteringmenu'
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'echo "" NOLINE >T:packagefilteringmenu'

        $selectPackageFilteringLines = @()
        $selectPackageFilteringOption = 0
        foreach ($amigaOsVersion in $amigaOsVersions)
        {
            $amigaOsVersionText = if ($amigaOsVersion -eq "All") { "All Amiga OS versions" } else { ("Amiga OS {0}" -f $amigaOsVersion) }
            $installPackagesScriptLines += ('echo "{0}" >>T:packagefilteringmenu' -f $amigaOsVersionText)

            $selectPackageFilteringOption++
            $selectPackageFilteringLines += ''
            $selectPackageFilteringLines += ('; select package filtering option ''{0}''' -f $selectPackageFilteringOption)
            $selectPackageFilteringLines += ('IF "$packagefilteringmenu" eq "{0}"' -f $selectPackageFilteringOption)
            $selectPackageFilteringLines += ('  set confirm `RequestChoice "Select package filtering" "Do you want to filter packages for*N''{0}''?*N*NThis will reset selected packages and changed assigns." "Yes|No"`' -f $amigaOsVersionText)
            $selectPackageFilteringLines += '  IF "$confirm" EQ "1"'
            $selectPackageFilteringLines += '    set amigaosversion "{0}"' -f $amigaOsVersion
            $selectPackageFilteringLines += '    SKIP resetpackages'
            $selectPackageFilteringLines += '  ENDIF'
            $selectPackageFilteringLines += '  SKIP BACK packagefilteringmenu'
            $selectPackageFilteringLines += 'ENDIF'
        }

        $selectPackageFilteringOption += 2
        $selectPackageFilteringLines += ''
        $selectPackageFilteringLines += '; help option'
        $selectPackageFilteringLines += ('IF "$packagefilteringmenu" eq "{0}"' -f $selectPackageFilteringOption)
        $selectPackageFilteringLines += '  IF EXISTS "PACKAGESDIR:Help/Select-Package-Filtering.txt"'
        $selectPackageFilteringLines += '    Lister "PACKAGESDIR:Help/Select-Package-Filtering.txt" >NIL:'
        $selectPackageFilteringLines += '  ELSE'
        $selectPackageFilteringLines += '    RequestChoice "Error" "ERROR: Help file ''PACKAGESDIR:Help/Select-Package-Filtering.txt'' doesn''t exist!"'
        $selectPackageFilteringLines += '  ENDIF'
        $selectPackageFilteringLines += "  SKIP BACK packagefilteringmenu"
        $selectPackageFilteringLines += "ENDIF"

        $selectPackageFilteringOption++
        $selectPackageFilteringLines += ''
        $selectPackageFilteringLines += '; detect amiga os version option'
        $selectPackageFilteringLines += ('IF "$packagefilteringmenu" eq "{0}"' -f $selectPackageFilteringOption)
        $selectPackageFilteringLines += '  set confirm `RequestChoice "Auto-detect Amiga OS version" "Do you want to auto-detect Amiga OS version?*N*NThis will reset selected packages and changed assigns." "Yes|No"`'
        $selectPackageFilteringLines += '  IF "$confirm" EQ "1"'
        $selectPackageFilteringLines += '    SKIP BACK detectamigaos'
        $selectPackageFilteringLines += '  ENDIF'
        $selectPackageFilteringLines += '  SKIP BACK packagefilteringmenu'
        $selectPackageFilteringLines += 'ENDIF'

        $selectPackageFilteringOption++
        $selectPackageFilteringLines += ''
        $selectPackageFilteringLines += '; back option'
        $selectPackageFilteringLines += ('IF "$packagefilteringmenu" eq "{0}"' -f $selectPackageFilteringOption)
        $selectPackageFilteringLines += '  SKIP BACK installpackagesmenu'
        $selectPackageFilteringLines += 'ENDIF'

        $installPackagesScriptLines += 'echo "============================================================" >>T:packagefilteringmenu'
        $installPackagesScriptLines += 'echo "Help" >>T:packagefilteringmenu'
        $installPackagesScriptLines += 'echo "Auto-detect Amiga OS version" >>T:packagefilteringmenu'
        $installPackagesScriptLines += 'echo "Back" >>T:packagefilteringmenu'
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'set packagefilteringmenu ""'
        $installPackagesScriptLines += 'set packagefilteringmenu "`RequestList TITLE="Select package filtering" LISTFILE="T:packagefilteringmenu" WIDTH=640 LINES=24`"'
        $installPackagesScriptLines += "delete >NIL: T:packagefilteringmenu"
        $installPackagesScriptLines += $selectPackageFilteringLines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP BACK packagefilteringmenu'
        
        # add reset packages and assigns script lines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; reset packages'
        $installPackagesScriptLines += '; --------------'
        $installPackagesScriptLines += 'LAB resetpackages'
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += $resetPackagesLines
        $installPackagesScriptLines += BuildResetAssignsScriptLines $hstwb
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP BACK installpackagesmenu'

        # reset assigns
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; reset assigns'
        $installPackagesScriptLines += '; -------------'
        $installPackagesScriptLines += 'LAB resetassigns'
        $installPackagesScriptLines += BuildResetAssignsScriptLines $hstwb
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP BACK editassignsmenu'

        # default assigns
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; default assigns'
        $installPackagesScriptLines += '; ---------------'
        $installPackagesScriptLines += 'LAB defaultassigns'
        $installPackagesScriptLines += BuildDefaultAssignsScriptLines $hstwb
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP BACK editassignsmenu'

        # add select all packages script lines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; install all packages'
        $installPackagesScriptLines += '; -------------------'
        $installPackagesScriptLines += 'LAB installallpackages'
        $installPackagesScriptLines += $installAllPackagesLines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP BACK installpackagesmenu'

        # add deselect all packages script lines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; skip all packages'
        $installPackagesScriptLines += '; -----------------'
        $installPackagesScriptLines += 'LAB skipallpackages'
        $installPackagesScriptLines += $skipAllPackagesLines
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'SKIP BACK installpackagesmenu'


        # view readme
        # -----------
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; view readme menu'
        $installPackagesScriptLines += '; ----------------'
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += 'LAB viewreadmemenu'

        $viewReadmeMenuLines = @()
        foreach ($amigaOsVersion in $amigaOsVersions)
        {
            $amigaOsVersionPackageScripts = @()
            $amigaOsVersionPackageScripts += $installPackageScripts | Where-Object { $amigaOsVersion -eq 'All' -or ($_.Package.AmigaOsVersions -and $_.Package.AmigaOsVersions -contains $amigaOsVersion) }

            $viewReadmeMenuId = CalculateMd5FromText ("ViewReadmeMenu:{0}" -f $amigaOsVersion)
            $installPackagesScriptLines += ('IF "$amigaosversion" EQ "{0}"' -f $amigaOsVersion)
            $installPackagesScriptLines += ('  SKIP {0}' -f $viewReadmeMenuId)
            $installPackagesScriptLines += 'ENDIF'

            $viewReadmeMenuLines += ''
            $viewReadmeMenuLines += ('; view readme menu ''{0}''' -f $amigaOsVersion)
            $viewReadmeMenuLines += ('LAB {0}' -f $viewReadmeMenuId)
            $viewReadmeMenuLines += 'echo "" NOLINE >T:viewreadmemenu'
            
            $viewReadmeOptionIndex = 0
            $viewReadmeOptionLines = @()
            foreach ($amigaOsVersionPackageScript in $amigaOsVersionPackageScripts)
            {
                $viewReadmeMenuLines += ("echo ""{0}"" >>T:viewreadmemenu" -f $amigaOsVersionPackageScript.Package.FullName)

                $viewReadmeOptionIndex++
                $viewReadmeOptionLines += ''
                $viewReadmeOptionLines += ('IF "$viewreadmemenu" eq "{0}"' -f $viewReadmeOptionIndex)
                $viewReadmeOptionLines += ('  IF EXISTS "PACKAGESDIR:{0}/README.guide"' -f $amigaOsVersionPackageScript.Package.Id)
                $viewReadmeOptionLines += ('    cd "PACKAGESDIR:{0}"' -f $amigaOsVersionPackageScript.Package.Id)
                $viewReadmeOptionLines += '    multiview README.guide'
                $viewReadmeOptionLines += '    cd "PACKAGESDIR:"'
                $viewReadmeOptionLines += '  ELSE'
                $viewReadmeOptionLines += ('    REQUESTCHOICE "No Readme" "Package ''{0}'' doesn''t have a readme file!" "OK" >NIL:' -f $amigaOsVersionPackageScript.Package.FullName)
                $viewReadmeOptionLines += '  ENDIF'
                $viewReadmeOptionLines += 'ENDIF'
            }

            $viewReadmeMenuLines += 'echo "============================================================" >>T:viewreadmemenu'
            $viewReadmeMenuLines += 'echo "Help" >>T:viewreadmemenu'
            $viewReadmeMenuLines += 'echo "Back" >>T:viewreadmemenu'
            $viewReadmeMenuLines += ''
            $viewReadmeMenuLines += 'set viewreadmemenu ""'
            $viewReadmeMenuLines += 'set viewreadmemenu "`RequestList TITLE="View readme" LISTFILE="T:viewreadmemenu" WIDTH=640 LINES=24`"'
            $viewReadmeMenuLines += 'delete >NIL: T:viewreadmemenu'
            $viewReadmeMenuLines += $viewReadmeOptionLines

            $viewReadmeOptionIndex += 2
            $viewReadmeMenuLines += ''
            $viewReadmeMenuLines += '; help option'
            $viewReadmeMenuLines += ('IF "$viewreadmemenu" eq "{0}"' -f $viewReadmeOptionIndex)
            $viewReadmeMenuLines += '  IF EXISTS "PACKAGESDIR:Help/View-Readme.txt"'
            $viewReadmeMenuLines += '    Lister "PACKAGESDIR:Help/View-Readme.txt" >NIL:'
            $viewReadmeMenuLines += '  ELSE'
            $viewReadmeMenuLines += '    RequestChoice "Error" "ERROR: Help file ''PACKAGESDIR:Help/View-Readme.txt'' doesn''t exist!"'
            $viewReadmeMenuLines += '  ENDIF'
            $viewReadmeMenuLines += "  SKIP BACK viewreadmemenu"
            $viewReadmeMenuLines += "ENDIF"

            $viewReadmeOptionIndex++
            $viewReadmeMenuLines += ''
            $viewReadmeMenuLines += '; back option'
            $viewReadmeMenuLines += ('IF "$viewreadmemenu" eq "{0}"' -f $viewReadmeOptionIndex)
            $viewReadmeMenuLines += '  SKIP BACK installpackagesmenu'
            $viewReadmeMenuLines += 'ENDIF'
            $viewReadmeMenuLines += ''
            $viewReadmeMenuLines += 'SKIP BACK viewreadmemenu'
        }

        $installPackagesScriptLines += $viewReadmeMenuLines


        # edit assigns
        # ------------
        $installPackagesScriptLines += ''
        $installPackagesScriptLines += '; Edit assigns menu'
        $installPackagesScriptLines += ';------------------'
        $installPackagesScriptLines += 'LAB editassignsmenu'
        $installPackagesScriptLines += ''

        $editAssignsMenuLines = @()
        foreach ($amigaOsVersion in $amigaOsVersions)
        {
            $editAssignsMenuId = CalculateMd5FromText ("EditAssignsMenu:{0}" -f $amigaOsVersion)
            $installPackagesScriptLines += ('IF "$amigaosversion" EQ "{0}"' -f $amigaOsVersion)
            $installPackagesScriptLines += ('  SKIP {0}' -f $editAssignsMenuId)
            $installPackagesScriptLines += 'ENDIF'

            $editAssignsMenuLines += ''
            $editAssignsMenuLines += ('; edit assigns menu ''{0}''' -f $amigaOsVersion)
            $editAssignsMenuLines += ('LAB {0}' -f $editAssignsMenuId)
            $editAssignsMenuLines += 'echo "" NOLINE >T:editassignsmenu'

            $editAssignsMenuOption = 0
            $editAssignsMenuOptionLines = @()
    
            $assignSectionNames = @('Global')
            $assignSectionNames += $hstwb.Assigns.keys | Where-Object { $_ -notlike 'Global' -and $hstwb.Assigns[$_].Count -gt 0 -and ($amigaOsVersion -eq 'All' -or ($hstwb.Packages[$_.ToLower()].AmigaOsVersions -and $hstwb.Packages[$_.ToLower()].AmigaOsVersions -contains $amigaOsVersion)) } | Sort-Object

            foreach($assignSectionName in $assignSectionNames)
            {
                # add menu option to show assign section name
                $editAssignsMenuLines += ("echo ""| {0} |"" >>T:editassignsmenu" -f $assignSectionName)
    
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
                    $editAssignsMenuLines += ""
                    $editAssignsMenuLines += ("IF EXISTS ""T:{0}""" -f $assignId)
                    $editAssignsMenuLines += ("  echo ""{0}: = '``type ""T:{1}""``'"" >>T:editassignsmenu" -f $assignName, $assignId)
                    $editAssignsMenuLines += "ELSE"
                    $editAssignsMenuLines += ("  Assign >NIL: EXISTS ""{0}""" -f $assignDir)
                    $editAssignsMenuLines += "  IF WARN"
                    $editAssignsMenuLines += ("    echo ""{0}: = ?"" >>T:editassignsmenu" -f $assignName)
                    $editAssignsMenuLines += "  ELSE"
                    $editAssignsMenuLines += ("    echo ""{0}: = '{1}'"" >>T:editassignsmenu" -f $assignName, $assignDir)
                    $editAssignsMenuLines += "  ENDIF"
                    $editAssignsMenuLines += "ENDIF"
    
                    $editAssignsMenuOptionLines += ""
                    $editAssignsMenuOptionLines += ("IF ""`$editassignsmenu"" eq """ + $editAssignsMenuOption + """")
                    $editAssignsMenuOptionLines += ("  set assignid ""{0}""" -f $assignId)
                    $editAssignsMenuOptionLines += ("  set assignname ""{0}""" -f $assignName)
                    $editAssignsMenuOptionLines += ("  IF EXISTS ""T:{0}""" -f $assignId)
                    $editAssignsMenuOptionLines += ("    set assigndir ""``type ""T:{0}""``""" -f $assignId)
                    $editAssignsMenuOptionLines += "  ELSE"
                    $editAssignsMenuOptionLines += ("    set assigndir ""{0}""" -f $assignDir)
                    $editAssignsMenuOptionLines += "  ENDIF"
                    $editAssignsMenuOptionLines += "  set returnlab ""editassignsmenu"""
                    $editAssignsMenuOptionLines += "  SKIP BACK selectassigndir"
                    $editAssignsMenuOptionLines += "ENDIF"
                }
            }

            # add back option to view readme menu
            $editAssignsMenuLines += "echo ""============================================================"" >>T:editassignsmenu"
            $editAssignsMenuLines += "echo ""Help"" >>T:editassignsmenu"
            $editAssignsMenuLines += "echo ""Reset assigns"" >>T:editassignsmenu"
            $editAssignsMenuLines += "echo ""Default assigns"" >>T:editassignsmenu"
            $editAssignsMenuLines += "echo ""Back"" >>T:editassignsmenu"
            $editAssignsMenuLines += ""
            $editAssignsMenuLines += "set editassignsmenu """""
            $editAssignsMenuLines += "set editassignsmenu ""``RequestList TITLE=""Edit assigns"" LISTFILE=""T:editassignsmenu"" WIDTH=640 LINES=24``"""
            $editAssignsMenuLines += "delete >NIL: T:editassignsmenu"
            $editAssignsMenuLines += $editAssignsMenuOptionLines

            # add back option to edit assigns menu
            $editAssignsMenuOption += 2
            $editAssignsMenuLines += ''
            $editAssignsMenuLines += '; help option'
            $editAssignsMenuLines += ('IF "$editassignsmenu" eq "{0}"' -f $editAssignsMenuOption)
            $editAssignsMenuLines += '  IF EXISTS "PACKAGESDIR:Help/Edit-Assigns.txt"'
            $editAssignsMenuLines += '    Lister "PACKAGESDIR:Help/Edit-Assigns.txt" >NIL:'
            $editAssignsMenuLines += '  ELSE'
            $editAssignsMenuLines += '    RequestChoice "Error" "ERROR: Help file ''PACKAGESDIR:Help/Edit-Assigns.txt'' doesn''t exist!"'
            $editAssignsMenuLines += '  ENDIF'
            $editAssignsMenuLines += "  SKIP BACK editassignsmenu"
            $editAssignsMenuLines += "ENDIF"

            $editAssignsMenuOption++
            $editAssignsMenuLines += ''
            $editAssignsMenuLines += '; reset assigns option'
            $editAssignsMenuLines += ('IF "$editassignsmenu" eq "{0}"' -f $editAssignsMenuOption)
            $editAssignsMenuLines += "  set confirm ``RequestChoice ""Confirm"" ""Are you sure you want to reset assigns?"" ""Yes|No""``"
            $editAssignsMenuLines += "  IF ""`$confirm"" EQ ""1"""
            $editAssignsMenuLines += "    SKIP BACK resetassigns"
            $editAssignsMenuLines += "  ENDIF"
            $editAssignsMenuLines += "  SKIP BACK editassignsmenu"
            $editAssignsMenuLines += "ENDIF"

            $editAssignsMenuOption++
            $editAssignsMenuLines += ''
            $editAssignsMenuLines += '; default assigns option'
            $editAssignsMenuLines += ('IF "$editassignsmenu" eq "{0}"' -f $editAssignsMenuOption)
            $editAssignsMenuLines += "  set confirm ``RequestChoice ""Confirm"" ""Are you sure you want to use default assigns?"" ""Yes|No""``"
            $editAssignsMenuLines += "  IF ""`$confirm"" EQ ""1"""
            $editAssignsMenuLines += "    SKIP BACK defaultassigns"
            $editAssignsMenuLines += "  ENDIF"
            $editAssignsMenuLines += "  SKIP BACK editassignsmenu"
            $editAssignsMenuLines += "ENDIF"

            $editAssignsMenuOption++
            $editAssignsMenuLines += ''
            $editAssignsMenuLines += '; back option'
            $editAssignsMenuLines += ('IF "$editassignsmenu" eq "{0}"' -f $editAssignsMenuOption)
            $editAssignsMenuLines += "  SKIP BACK installpackagesmenu"
            $editAssignsMenuLines += "ENDIF"
            $editAssignsMenuLines += ""
            $editAssignsMenuLines += "SKIP BACK editassignsmenu"
        }

        $installPackagesScriptLines += $editAssignsMenuLines
    }

    # install packages
    # ----------------
    $installPackagesScriptLines += ''
    $installPackagesScriptLines += ''
    $installPackagesScriptLines += "; install packages"
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
function BuildFsUaeInstallHarddrivesConfigText($hstwb, $installDir, $packagesDir, $userPackagesDir, $boot)
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
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Replace('[$UserPackagesDir]', $userPackagesDir.Replace('\', '/'))
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Replace('[$UserPackagesHarddriveIndex]', [int]$harddriveIndex + 3)
    $fsUaeHarddrivesConfigText = $fsUaeHarddrivesConfigText.Trim()
    
    # return winuae image and install harddrives config
    return $fsUaeImageHarddrivesConfigText + "`r`n" + $fsUaeHarddrivesConfigText    
}


# build fs-uae self install harddrives config text
function BuildFsUaeSelfInstallHarddrivesConfigText($hstwb, $amigaOsDir, $kickstartDir, $userPackagesDir)
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
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$AmigaOsDir]', $amigaOsDir.Replace('\', '/'))
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$AmigaOsHarddriveIndex]', [int]$harddriveIndex + 1)
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$KickstartDir]', $kickstartDir.Replace('\', '/'))
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$KickstartHarddriveIndex]', [int]$harddriveIndex + 2)
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$UserPackagesDir]', $userPackagesDir.Replace('\', '/'))
    $fsUaeSelfInstallHarddrivesConfigText = $fsUaeSelfInstallHarddrivesConfigText.Replace('[$UserPackagesHarddriveIndex]', [int]$harddriveIndex + 3)
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
function BuildWinuaeInstallHarddrivesConfigText($hstwb, $installDir, $packagesDir, $userPackagesDir, $boot)
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
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$UserPackagesDir]', $userPackagesDir)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$UserPackagesUaehfIndex]', [int]$uaehfIndex + 3)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$Cd0UaehfIndex]', [int]$uaehfIndex + 4)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Trim()

    # return winuae image and install harddrives config
    return $winuaeImageHarddrivesConfigText + "`r`n" + $winuaeInstallHarddrivesConfigText
}


# build winuae self install harddrives config text
function BuildWinuaeSelfInstallHarddrivesConfigText($hstwb, $amigaOsDir, $kickstartDir, $userPackagesDir)
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
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$AmigaOsDir]', $amigaOsDir)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$AmigaOsUaehfIndex]', [int]$uaehfIndex + 1)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$KickstartDir]', $kickstartDir)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$KickstartUaehfIndex]', [int]$uaehfIndex + 2)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$UserPackagesDir]', $userPackagesDir)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$UserPackagesUaehfIndex]', [int]$uaehfIndex + 3)
    $winuaeSelfInstallHarddrivesConfigText = $winuaeSelfInstallHarddrivesConfigText.Replace('[$Cd0UaehfIndex]', [int]$uaehfIndex + 4)
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

# patch assign list
function PatchAssignList($hstwb, $assignListFile)
{
    # fail, if assign list doesn't exist
    if (!(Test-Path $assignListFile))
    {
        throw ('Assign list file ''{0}'' doesn''t exist!' -f $assignListFile)
    }

    # read assign list lines and exclude empty lines
    $assignListLines = @()
    $assignListLines += Get-Content $assignListFile | Where-Object { $_ -notmatch '^\s*$' }

    # replace placeholders in assign list lines
    for ($i = 0; $i -lt $assignListLines.Count; $i++)
    {
        $assignListLines[$i] = $assignListLines[$i].Replace('[$HstwbInstallerDir]', $hstwb.Assigns.Global.HstWBInstallerDir)
    }

    foreach ($assignName in $hstwb.Assigns.Global.keys)
    {
        # skip, if assign name is 'HstWBInstallerDir'
        if ($assignName -match 'HstWBInstallerDir')
        {
            continue
        }

        # get assign dir
        $assignDir = $hstwb.Assigns.Global[$assignName]

        $assignListLines += ("{0}: {1}" -f $assignName, $assignDir)
    }

    $assignListLines += ''

    # write assing list
    WriteAmigaTextLines $assignListFile $assignListLines
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
        $fsUaeHstwbInstallerFileName = "hstwb-installer_{0}.fs-uae" -f $hstwb.Paths.KickstartEntry.Model.ToLower()
        $fsUaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.FsUaePath -ChildPath $fsUaeHstwbInstallerFileName
        if (!(Test-Path $fsUaeHstwbInstallerConfigFile))
        {
            Fail $hstwb ("FS-UAE configuration file '{0}' doesn't exist for model '{1}'" -f $fsUaeHstwbInstallerConfigFile, $hstwb.Paths.KickstartEntry.Model)
        }
        $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

        # replace hstwb installer fs-uae configuration placeholders
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartEntry.File.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$InstallAdfFile]', '')
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
        $winuaeHstwbInstallerFileName = "hstwb-installer_{0}.uae" -f $hstwb.Paths.KickstartEntry.Model.ToLower()
        $winuaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.WinuaePath -ChildPath $winuaeHstwbInstallerFileName
        if (!(Test-Path $winuaeHstwbInstallerConfigFile))
        {
            Fail $hstwb ("WinUAE configuration file '{0}' doesn't exist for model '{1}'" -f $winuaeHstwbInstallerConfigFile, $hstwb.Paths.KickstartEntry.Model)
        }
        $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)

        # replace winuae test config placeholders
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartEntry.File)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$InstallAdfFile]', '')
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
    $tempInstallTempDir = Join-Path $tempInstallDir -ChildPath "Temp"
    $tempAmigaOsDir = Join-Path $tempInstallTempDir -ChildPath "Amiga-OS"
    $tempKickstartDir = Join-Path $tempInstallTempDir -ChildPath "Kickstart"
    $tempPackagesDir = Join-Path $hstwb.Paths.TempPath -ChildPath "packages"
    $tempUserPackagesDir = Join-Path $hstwb.Paths.TempPath -ChildPath "userpackages"

    # create temp amiga os path
    if(!(test-path -path $tempAmigaOsDir))
    {
        mkdir $tempAmigaOsDir | Out-Null
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

    # create temp user packages path
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

    # copy amiga os 3.9 to install directory
    $amigaOs39Dir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "amiga-os-3.9")
    Copy-Item -Path "$amigaOs39Dir\*" $tempInstallDir -recurse -force

    # copy amiga os 3.1.4 to install directory
    $amigaOs314Dir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "amiga-os-3.1.4")
    Copy-Item -Path "$amigaOs314Dir\*" $tempInstallDir -recurse -force

    # copy amiga os 3.1 to install directory
    $amigaOs31Dir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "amiga-os-3.1")
    Copy-Item -Path "$amigaOs31Dir\*" $tempInstallDir -recurse -force

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

    # copy hstwb installer theme for fs-uae
    $imageFsuaeThemeDir = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath 'fs-uae\themes\hstwb-installer'
    if (!(Test-Path -Path $imageFsuaeThemeDir))
    {
        mkdir $imageFsuaeThemeDir | Out-Null
    }
    $fsuaeThemeDir = [System.IO.Path]::Combine($hstwb.Paths.FsUaePath, 'theme\hstwb-installer')
    Copy-Item -Path "$fsuaeThemeDir\*" $imageFsuaeThemeDir -include *.png, *.conf -force


    # create uae prefs file
    $uaePrefsFile = Join-Path $prefsDir -ChildPath 'UAE'
    Set-Content $uaePrefsFile -Value ""


    $installAmigaOs39Reboot = $false
    $installBoingBagsReboot = $false

    # prepare install amiga os
    if ($hstwb.Settings.AmigaOs.InstallAmigaOs -eq 'Yes')
    {
        $amigaOsSetEntries = @()
        $amigaOsSetEntries = $hstwb.AmigaOsEntries | Where-Object { $_.Set -eq $hstwb.Settings.AmigaOs.AmigaOsSet }
    
        # find amiga os 3.9 iso in amiga os set
        $amigaOs39Iso = $amigaOsSetEntries | Where-Object { $_.File -and $_.Filename -match '^amigaos3\.9\.iso$' } | Select-Object -First 1
        if ($amigaOs39Iso)
        {
            # set install to reboot for amiga os 3.9 installation
            $installAmigaOs39Reboot = $true

            # create install amiga os 3.9 prefs file
            $installAmigaOs390PrefsFile = Join-Path $prefsDir -ChildPath 'Install-Amiga-OS-390'
            Set-Content $installAmigaOs390PrefsFile -Value ""

            for ($i = 1; $i -le 2; $i++)
            {
                # find boing bag 3.9 update lha in amiga os set
                $boingbagLha = $amigaOsSetEntries | Where-Object { $_.File -and $_.Filename -match ('^boingbag39-{0}\.lha$' -f $i) } | Select-Object -First 1
                if (!$boingbagLha)
                {
                    break
                }

                # set install to reboot for boing bag installation
                $installBoingBagsReboot = $true
                
                # create install boing bag prefs file
                $installBoingBagPrefsFile = Join-Path $prefsDir -ChildPath ('Install-Amiga-OS-390-BB{0}' -f $i)
                Set-Content $installBoingBagPrefsFile -Value ""
            }
        }

        # find amiga os 3.1.4 modules adf in amiga os set
        $amigaOs314ModulesAdf = $amigaOsSetEntries | Where-Object { $_.File -and $_.Filename -match '^amiga-os-314-modules-[^\-\.]+\.adf$' } | Select-Object -First 1
        if ($amigaOs314ModulesAdf)
        {
            # create install amiga os 3.1.4 adf prefs file
            $installAmigaOs314PrefsFile = Join-Path $prefsDir -ChildPath ('Install-Amiga-OS-314-{0}-ADF' -f $amigaOs314ModulesAdf.Model)
            Set-Content $installAmigaOs314PrefsFile -Value ""

            # find amiga os 3.1.4 icon pack lha in amiga os set
            $amigaOs314IconPackLha = $amigaOsSetEntries | Where-Object { $_.File -and $_.Filename -match '^amiga-os-314-iconpack\.lha$' } | Select-Object -First 1
            if ($amigaOs314IconPackLha)
            {
                # create install amiga os 3.1.4 icon pack prefs file
                $installAmigaOs314IconPackLhaPrefsFile = Join-Path $prefsDir -ChildPath 'Install-Amiga-OS-314-IconPack'
                Set-Content $installAmigaOs314IconPackLhaPrefsFile -Value ""
            }
        }

        # create install amiga os 3.1 prefs, if amiga os set entries contain amiga os 3.1 adf files
        $amigaOs31Adf = $amigaOsSetEntries | Where-Object { $_.File -and $_.Filename -match '^amiga-os-310-[^\-\.]+\.adf$' } | Select-Object -First 1
        if ($amigaOs31Adf)
        {
            # create install amiga os 3.1 prefs file
            $installAmigaOs310PrefsFile = Join-Path $prefsDir -ChildPath 'Install-Amiga-OS-310-ADF'
            Set-Content $installAmigaOs310PrefsFile -Value ""
        }

        # write copying amiga os files to temp install dir
        Write-Host "Copying Amiga OS files to temp install dir"

        # copy amiga os set entries to temp install dir
        $amigaOsSetEntriesFirstIndex = @{}
        foreach($amigaOsSetEntry in $amigaOsSetEntries)
        {
            if ($amigaOsSetEntriesFirstIndex.ContainsKey($amigaOsSetEntry.Name))
            {
                continue
            }

            $amigaOsSetEntriesFirstIndex[$amigaOsSetEntry.Name] = $true

            # find best matching amiga os set entry to copy
            $bestMatchingAmigaOsSetEntry = $amigaOsSetEntries | Where-Object { $_.Name -eq $amigaOsSetEntry.Name -and $_.CopyFile -eq 'True' -and $_.File } | Sort-Object @{expression={$_.MatchRank};Ascending=$true} | Select-Object -First 1

            # skip, if best matching amiga os set entry doesn't exist
            if (!$bestMatchingAmigaOsSetEntry)
            {
                continue
            }

            Copy-Item $bestMatchingAmigaOsSetEntry.File -Destination (Join-Path $tempAmigaOsDir -ChildPath $bestMatchingAmigaOsSetEntry.Filename) -Force
        }    
    }

    # prepare install kickstart
    if ($hstwb.Settings.Kickstart.InstallKickstart -eq 'Yes' -and ($hstwb.KickstartEntries | Where-Object { $_.File }).Count -gt 0 )
    {
        $kickstartSetEntries = @()
        $kickstartSetEntries = $hstwb.KickstartEntries | Where-Object { $_.Set -eq $hstwb.Settings.Kickstart.KickstartSet }

        # copy kickstart files to temp install dir
        Write-Host "Copying Kickstart files to temp install dir"

        # copy amiga os set entries to temp install dir
        $kickstartSetEntriesFirstIndex = @{}
        foreach($kickstartSetEntry in $kickstartSetEntries)
        {
            if ($kickstartSetEntriesFirstIndex.ContainsKey($kickstartSetEntry.Name))
            {
                continue
            }

            $kickstartSetEntriesFirstIndex[$kickstartSetEntry.Name] = $true

            # find best matching kickstart set entry to copy
            $bestMatchingKickstartSetEntry = $kickstartSetEntries | Where-Object { $_.Name -eq $kickstartSetEntry.Name -and $_.CopyFile -eq 'True' -and $_.File } | Sort-Object @{expression={$_.MatchRank};Ascending=$true} | Select-Object -First 1

            # skip, if best matching kickstart set entry doesn't exist
            if (!$bestMatchingKickstartSetEntry)
            {
                continue
            }

            Copy-Item $bestMatchingKickstartSetEntry.File -Destination (Join-Path $tempKickstartDir -ChildPath $bestMatchingKickstartSetEntry.Filename) -Force
        }    

        # create install kickstart prefs file
        $installKickstartFile = Join-Path $prefsDir -ChildPath 'Install-Kickstart'
        Set-Content $installKickstartFile -Value ""
    }

    # find packages to install
    $installPackages = FindPackagesToInstall $hstwb


    # patch assign list
    $assignListFile = Join-Path $tempInstallDir -ChildPath "S\AssignList"
    PatchAssignList $hstwb $assignListFile

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

        # create install packages system prefs file
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

    # update version in files
    $startupSequenceFiles = @()
    $startupSequenceFiles += Get-ChildItem -Path $tempInstallDir -Filter 'Startup-Sequence*.*' -Recurse
    $startupSequenceFiles += Get-ChildItem -Path $tempInstallDir -Filter 'WBStartup-*.*' -Recurse
    $startupSequenceFiles | ForEach-Object { UpdateVersionAmigaTextFile $_.FullName $hstwb.Version }
    
    # write hstwb installer log file
    $installLogLines = BuildInstallLog $hstwb
    WriteAmigaTextLines $tempHstwbInstallerLogFile $installLogLines
    

    foreach ($model in $hstwb.Models)
    {
        # read winuae hstwb installer model config file
        $winuaeHstwbInstallerFileName = "hstwb-installer_{0}.uae" -f $model.ToLower()
        $winuaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.WinuaePath -ChildPath $winuaeHstwbInstallerFileName
        if (!(Test-Path $winuaeHstwbInstallerConfigFile))
        {
            Fail $hstwb ("WinUAE configuration file '{0}' doesn't exist for model '{1}'" -f $winuaeHstwbInstallerConfigFile, $hstwb.Paths.KickstartEntry.Model)
        }
        $hstwbInstallerUaeWinuaeConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)

        # build winuae run harddrives config
        $winuaeRunHarddrivesConfigText = BuildWinuaeRunHarddrivesConfigText $hstwb

        # replace hstwb installer configuration placeholders
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('use_gui=no', 'use_gui=yes')
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$KickstartRomFile]', '')
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$WorkbenchAdfFile]', '')
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$InstallAdfFile]', '')
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$Harddrives]', $winuaeRunHarddrivesConfigText)
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$IsoFile]', '')

        # write hstwb installer configuration file to image dir
        $hstwbInstallerUaeConfigFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath $winuaeHstwbInstallerFileName
        [System.IO.File]::WriteAllText($hstwbInstallerUaeConfigFile, $hstwbInstallerUaeWinuaeConfigText)
        

        # read fs-uae hstwb installer config file
        $fsUaeHstwbInstallerFileName = "hstwb-installer_{0}.fs-uae" -f $model.ToLower()
        $fsUaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.FsUaePath -ChildPath $fsUaeHstwbInstallerFileName
        if (!(Test-Path $fsUaeHstwbInstallerConfigFile))
        {
            Fail $hstwb ("FS-UAE configuration file '{0}' doesn't exist for model '{1}'" -f $fsUaeHstwbInstallerConfigFile, $hstwb.Paths.KickstartEntry.Model)
        }
        $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

        # build fs-uae install harddrives config
        $hstwbInstallerFsUaeInstallHarddrivesConfigText = BuildFsUaeHarddrivesConfigText $hstwb
        
        # replace hstwb installer fs-uae configuration placeholders
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$InstallAdfFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $hstwbInstallerFsUaeInstallHarddrivesConfigText)
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
        
        # write hstwb installer fs-uae configuration file to image dir
        $hstwbInstallerFsUaeConfigFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath $fsUaeHstwbInstallerFileName
        [System.IO.File]::WriteAllText($hstwbInstallerFsUaeConfigFile, $fsUaeHstwbInstallerConfigText)
    }    

    # set and verify winuae hstwb installer model config file
    $winuaeHstwbInstallerFileName = "hstwb-installer_{0}.uae" -f $hstwb.Paths.KickstartEntry.Model.ToLower()
    $winuaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.WinuaePath -ChildPath $winuaeHstwbInstallerFileName
    if (!(Test-Path $winuaeHstwbInstallerConfigFile))
    {
        Fail $hstwb ("WinUAE configuration file '{0}' doesn't exist for model '{1}'" -f $winuaeHstwbInstallerConfigFile, $hstwb.Paths.KickstartEntry.Model)
    }

    # set and verify fs-uae hstwb installer config file
    $fsUaeHstwbInstallerFileName = "hstwb-installer_{0}.fs-uae" -f $hstwb.Paths.KickstartEntry.Model.ToLower()
    $fsUaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.FsUaePath -ChildPath $fsUaeHstwbInstallerFileName
    if (!(Test-Path $fsUaeHstwbInstallerConfigFile))
    {
        Fail $hstwb ("FS-UAE configuration file '{0}' doesn't exist for model '{1}'" -f $fsUaeHstwbInstallerConfigFile, $hstwb.Paths.KickstartEntry.Model)
    }


    # copy hstwb image setup to image dir
    $hstwbImageSetupDir = [System.IO.Path]::Combine($hstwb.Paths.SupportPath, "hstwb_image_setup")
    Copy-Item -Path "$hstwbImageSetupDir\*" $hstwb.Settings.Image.ImageDir -recurse -force
    

    # set iso file, if iso entry exists
    $isoFile = ''
    if ($hstwb.Paths.IsoEntry -and $hstwb.Paths.IsoEntry.File)
    {
        $isoFile = $hstwb.Paths.IsoEntry.File
    }

    # set workbench adf file, if workbench adf entry entry exists
    $workbenchAdfFile = ''
    if ($hstwb.Paths.WorkbenchAdfEntry -and $hstwb.Paths.WorkbenchAdfEntry.File)
    {
        $workbenchAdfFile = $hstwb.Paths.WorkbenchAdfEntry.File
    }

    # set install adf file, if install adf entry entry exists
    $installAdfFile = ''
    if ($hstwb.Paths.InstallAdfEntry -and $hstwb.Paths.InstallAdfEntry.File)
    {
        $installAdfFile = $hstwb.Paths.InstallAdfEntry.File
    }

    #
    $emulatorArgs = ''
    if ($hstwb.Settings.Emulator.EmulatorFile -match 'fs-uae\.exe$')
    {
        # install hstwb installer fs-uae theme
        InstallHstwbInstallerFsUaeTheme $hstwb

        # build fs-uae install harddrives config
        $fsUaeInstallHarddrivesConfigText = BuildFsUaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $userPackagesDir $true

        # read fs-uae hstwb installer config file
        $fsUaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.FsUaePath -ChildPath $fsUaeHstwbInstallerFileName
        $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

        # replace hstwb installer fs-uae configuration placeholders
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartEntry.File.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', $workbenchAdfFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$InstallAdfFile]', $installAdfFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $fsUaeInstallHarddrivesConfigText)
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
        
        # write fs-uae hstwb installer config file to temp dir
        $tempFsUaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.TempPath -ChildPath "hstwb-installer.fs-uae"
        [System.IO.File]::WriteAllText($tempFsUaeHstwbInstallerConfigFile, $fsUaeHstwbInstallerConfigText)
    
        # emulator args for fs-uae
        $emulatorArgs = """$tempFsUaeHstwbInstallerConfigFile"""
    }
    elseif ($hstwb.Settings.Emulator.EmulatorFile -match '(winuae\.exe|winuae64\.exe)$')
    {
        # build winuae install harddrives config
        $winuaeInstallHarddrivesConfigText = BuildWinuaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $userPackagesDir $true
    
        # read winuae hstwb installer config file
        $winuaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.WinuaePath -ChildPath $winuaeHstwbInstallerFileName
        $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)
    
        # replace winuae hstwb installer config placeholders
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartEntry.File)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', $workbenchAdfFile)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$InstallAdfFile]', $installAdfFile)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$Harddrives]', $winuaeInstallHarddrivesConfigText)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile)
    
        # write winuae hstwb installer config file to temp install dir
        $tempWinuaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.TempPath -ChildPath "hstwb-installer.uae"
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
        $fsUaeInstallHarddrivesConfigText = BuildFsUaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $userPackagesDir $false
        
        # read fs-uae hstwb installer config file
        $fsUaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.FsUaePath -ChildPath $fsUaeHstwbInstallerFileName
        $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

        # replace hstwb installer fs-uae configuration placeholders
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartEntry.File.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$InstallAdfFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $fsUaeInstallHarddrivesConfigText)
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
        
        # write fs-uae hstwb installer config file to temp dir
        $tempFsUaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.TempPath -ChildPath "hstwb-installer.fs-uae"
        [System.IO.File]::WriteAllText($tempFsUaeHstwbInstallerConfigFile, $fsUaeHstwbInstallerConfigText)
    
        # emulator args for fs-uae
        $emulatorArgs = """$tempFsUaeHstwbInstallerConfigFile"""
    }
    elseif ($hstwb.Settings.Emulator.EmulatorFile -match '(winuae\.exe|winuae64\.exe)$')
    {
        # build winuae install harddrives config with boot
        $winuaeInstallHarddrivesConfigText = BuildWinuaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $userPackagesDir $false
        
        # read winuae hstwb installer config file
        $winuaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.WinuaePath -ChildPath $winuaeHstwbInstallerFileName
        $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)

        # replace winuae hstwb installer config placeholders
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartEntry.File)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$InstallAdfFile]', '')
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$Harddrives]', $winuaeInstallHarddrivesConfigText)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile)

        # write winuae hstwb installer config file to temp dir
        $tempWinuaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.TempPath -ChildPath "hstwb-installer.uae"
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

    # create install self install directory
    $installSelfInstallDir = Join-Path $tempInstallDir -ChildPath 'Install-SelfInstall'
    if(!(test-path -path $installSelfInstallDir))
    {
        mkdir $installSelfInstallDir | Out-Null
    }

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

    # copy package installation help to packages directory
    $packageInstallationHelpDir = Join-Path $hstwb.Paths.AmigaPath -ChildPath 'packageinstallation\Help'
    $tempPackageHelpDir = Join-Path $tempPackagesDir -ChildPath 'Help'
    if(!(test-path -path $tempPackageHelpDir))
    {
        mkdir $tempPackageHelpDir | Out-Null
    }
    Copy-Item -Path "$packageInstallationHelpDir\*" "$tempPackageHelpDir" -recurse -force
    
    # copy amiga os 3.9 to install directory
    $amigaOs39Dir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "amiga-os-3.9")
    Copy-Item -Path "$amigaOs39Dir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force

    # copy amiga os 3.1.4 to install directory
    $amigaOs314Dir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "amiga-os-3.1.4")
    Copy-Item -Path "$amigaOs314Dir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force

    # copy amiga os 3.1 to install directory
    $amigaOs31Dir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "amiga-os-3.1")
    Copy-Item -Path "$amigaOs31Dir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force
    
    # copy kickstart to install directory
    $amigaKickstartDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "kickstart")
    Copy-Item -Path "$amigaKickstartDir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force
    
    # copy amiga packages dir
    $amigaPackagesDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "packages")
    Copy-Item -Path "$amigaPackagesDir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force

    # create self install user packages dir
    $selfInstallUserPackagesDir = Join-Path $installSelfInstallDir -ChildPath 'User-Packages'
    if(!(test-path -path $selfInstallUserPackagesDir))
    {
        mkdir $selfInstallUserPackagesDir | Out-Null
    }

    # copy user packages dir
    $amigaUserPackagesDir = Join-Path $hstwb.Paths.AmigaPath -ChildPath 'userpackages'
    Copy-Item -Path "$amigaUserPackagesDir\*" $selfInstallUserPackagesDir -recurse -force

    # create self install prefs file
    $selfInstallPrefsFile = Join-Path $prefsDir -ChildPath 'Self-Install'
    Set-Content $selfInstallPrefsFile -Value ""


    # patch assign list
    $assignListFile = Join-Path $tempInstallDir -ChildPath "S\AssignList"
    PatchAssignList $hstwb $assignListFile

    # patch assign list
    $assignListFile = Join-Path $tempInstallDir -ChildPath "Boot-SelfInstall\S\AssignList"
    PatchAssignList $hstwb $assignListFile



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
        # build packages prefs list
        $packagesPrefsList = @()
        $packagesPrefsList += $installPackages | Where-Object { $hstwb.Packages.ContainsKey($_) } | ForEach-Object { $hstwb.Packages[$_].FullName }
        $packagesPrefsList += ''
    
        # create packages prefs file
        $packagesPrefsFile = Join-Path $prefsDir -ChildPath 'Packages'
        WriteAmigaTextLines $packagesPrefsFile $packagesPrefsList

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

    # create default directory
    $defaultDir = Join-Path $tempInstallDir -ChildPath "Default"
    if(!(test-path -path $defaultDir))
    {
        mkdir $defaultDir | Out-Null
    }

    # copy prefs directory to default prefs directory
    Copy-Item -Path "$prefsDir\*" $defaultDir -recurse -force

    # move default directory to prefs directory
    $defaultPrefsDir = Join-Path $prefsDir -ChildPath "Default"
    Move-Item -Path $defaultDir -Destination $defaultPrefsDir

    # copy prefs to install self install
    $selfInstallDir = Join-Path $tempInstallDir -ChildPath "Install-SelfInstall"
    Copy-Item -Path $prefsDir $selfInstallDir -recurse -force


    # update version in files
    $startupSequenceFiles = @()
    $startupSequenceFiles += Get-ChildItem -Path $tempInstallDir -Filter 'Startup-Sequence*.*' -Recurse
    $startupSequenceFiles += Get-ChildItem -Path $tempInstallDir -Filter 'WBStartup-*.*' -Recurse
    $startupSequenceFiles | ForEach-Object { UpdateVersionAmigaTextFile $_.FullName $hstwb.Version }

    # write hstwb installer log file
    $installLogLines = BuildInstallLog $hstwb
    WriteAmigaTextLines $tempHstwbInstallerLogFile $installLogLines


    # create amiga os directory in image directory, if it doesn't exist
    $imageAmigaOsDir = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "amigaos"
    if (!(Test-Path -Path $imageAmigaOsDir))
    {
        mkdir $imageAmigaOsDir | Out-Null
    }

    # create kickstart directory in image directory, if it doesn't exist
    $imageKickstartDir = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "kickstart"
    if (!(Test-Path -Path $imageKickstartDir))
    {
        mkdir $imageKickstartDir | Out-Null
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

    # copy hstwb installer theme for fs-uae
    $imageFsuaeThemeDir = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath 'fs-uae\themes\hstwb-installer'
    if (!(Test-Path -Path $imageFsuaeThemeDir))
    {
        mkdir $imageFsuaeThemeDir | Out-Null
    }
    $fsuaeThemeDir = [System.IO.Path]::Combine($hstwb.Paths.FsUaePath, 'theme\hstwb-installer')
    Copy-Item -Path "$fsuaeThemeDir\*" $imageFsuaeThemeDir -include *.png, *.conf -force


    foreach ($model in $hstwb.Models)
    {
        # read winuae hstwb installer model config file
        $winuaeHstwbInstallerFileName = "hstwb-installer_{0}.uae" -f $model.ToLower()
        $winuaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.WinuaePath -ChildPath $winuaeHstwbInstallerFileName
        if (!(Test-Path $winuaeHstwbInstallerConfigFile))
        {
            Fail $hstwb ("WinUAE configuration file '{0}' doesn't exist for model '{1}'" -f $winuaeHstwbInstallerConfigFile, $model)
        }
        $hstwbInstallerUaeWinuaeConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)

        # build winuae self install harddrives config
        $hstwbInstallerWinuaeSelfInstallHarddrivesConfigText = BuildWinuaeSelfInstallHarddrivesConfigText $hstwb $imageAmigaOsDir $imageKickstartDir $imageUserPackagesDir

        # replace hstwb installer uae winuae configuration placeholders
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('use_gui=no', 'use_gui=yes')
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$KickstartRomFile]', '')
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$WorkbenchAdfFile]', '')
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$InstallAdfFile]', '')
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$Harddrives]', $hstwbInstallerWinuaeSelfInstallHarddrivesConfigText)
        $hstwbInstallerUaeWinuaeConfigText = $hstwbInstallerUaeWinuaeConfigText.Replace('[$IsoFile]', '')
        
        # write hstwb installer uae winuae configuration file to image dir
        $hstwbInstallerUaeConfigFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath $winuaeHstwbInstallerFileName
        [System.IO.File]::WriteAllText($hstwbInstallerUaeConfigFile, $hstwbInstallerUaeWinuaeConfigText)


        # read fs-uae hstwb installer config file
        $fsUaeHstwbInstallerFileName = "hstwb-installer_{0}.fs-uae" -f $model.ToLower()
        $fsUaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.FsUaePath -ChildPath $fsUaeHstwbInstallerFileName
        if (!(Test-Path $fsUaeHstwbInstallerConfigFile))
        {
            Fail $hstwb ("FS-UAE configuration file '{0}' doesn't exist for model '{1}'" -f $fsUaeHstwbInstallerConfigFile, $model)
        }
        $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

        # build fs-uae self install harddrives config
        $hstwbInstallerFsUaeSelfInstallHarddrivesConfigText = BuildFsUaeSelfInstallHarddrivesConfigText $hstwb $imageAmigaOsDir $imageKickstartDir $imageUserPackagesDir
        
        # replace hstwb installer fs-uae configuration placeholders
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$InstallAdfFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $hstwbInstallerFsUaeSelfInstallHarddrivesConfigText)
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
        
        # write hstwb installer fs-uae configuration file to image dir
        $hstwbInstallerFsUaeConfigFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath $fsUaeHstwbInstallerFileName
        [System.IO.File]::WriteAllText($hstwbInstallerFsUaeConfigFile, $fsUaeHstwbInstallerConfigText)
    }


    # set and verify winuae hstwb installer model config file
    $winuaeHstwbInstallerFileName = "hstwb-installer_{0}.uae" -f $hstwb.Paths.KickstartEntry.Model.ToLower()
    $winuaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.WinuaePath -ChildPath $winuaeHstwbInstallerFileName
    if (!(Test-Path $winuaeHstwbInstallerConfigFile))
    {
        Fail $hstwb ("WinUAE configuration file '{0}' doesn't exist for model '{1}'" -f $winuaeHstwbInstallerConfigFile, $hstwb.Paths.KickstartEntry.Model)
    }

    # set and verify fs-uae hstwb installer config file
    $fsUaeHstwbInstallerFileName = "hstwb-installer_{0}.fs-uae" -f $hstwb.Paths.KickstartEntry.Model.ToLower()
    $fsUaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.FsUaePath -ChildPath $fsUaeHstwbInstallerFileName
    if (!(Test-Path $fsUaeHstwbInstallerConfigFile))
    {
        Fail $hstwb ("FS-UAE configuration file '{0}' doesn't exist for model '{1}'" -f $fsUaeHstwbInstallerConfigFile, $hstwb.Paths.KickstartEntry.Model)
    }

    # set iso file, if amiga os 3.9 iso entry exists
    $isoFile = ''
    if ($hstwb.Paths.IsoEntry -and $hstwb.Paths.IsoEntry.File)
    {
        $isoFile = $hstwb.Paths.IsoEntry.File
    }

    # set workbench adf file, if workbench adf entry entry exists
    $workbenchAdfFile = ''
    if ($hstwb.Paths.WorkbenchAdfEntry -and $hstwb.Paths.WorkbenchAdfEntry.File)
    {
        $workbenchAdfFile = $hstwb.Paths.WorkbenchAdfEntry.File
    }

    #
    $emulatorArgs = ''
    if ($hstwb.Settings.Emulator.EmulatorFile -match 'fs-uae\.exe$')
    {
        # install hstwb installer fs-uae theme
        InstallHstwbInstallerFsUaeTheme $hstwb

        # build fs-uae install harddrives config
        $fsUaeInstallHarddrivesConfigText = BuildFsUaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $tempUserPackagesDir $true

        # read fs-uae hstwb installer config file
        $fsUaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.FsUaePath -ChildPath $fsUaeHstwbInstallerFileName
        $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

        # replace hstwb installer fs-uae configuration placeholders
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartEntry.File.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', $workbenchAdfFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$InstallAdfFile]', '')
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $fsUaeInstallHarddrivesConfigText)
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
        
        # write fs-uae hstwb installer config file to temp dir
        $tempFsUaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.TempPath -ChildPath "hstwb-installer.fs-uae"
        [System.IO.File]::WriteAllText($tempFsUaeHstwbInstallerConfigFile, $fsUaeHstwbInstallerConfigText)
    
        # emulator args for fs-uae
        $emulatorArgs = """$tempFsUaeHstwbInstallerConfigFile"""
    }
    elseif ($hstwb.Settings.Emulator.EmulatorFile -match '(winuae\.exe|winuae64\.exe)$')
    {
        # build winuae install harddrives config
        $winuaeInstallHarddrivesConfigText = BuildWinuaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $tempUserPackagesDir $true
    
        # read winuae hstwb installer config file
        $winuaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.WinuaePath -ChildPath $winuaeHstwbInstallerFileName
        $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)
    
        # replace winuae hstwb installer config placeholders
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartEntry.File)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', $workbenchAdfFile)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$InstallAdfFile]', '')
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$Harddrives]', $winuaeInstallHarddrivesConfigText)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$IsoFile]', $isoFile)
        
        # write winuae hstwb installer config file to temp install dir
        $tempWinuaeHstwbInstallerConfigFile = Join-Path $hstwb.Paths.TempPath -ChildPath "hstwb-installer.uae"
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
    Write-Error $message
    Write-Host ""
    if(test-path -path $hstwb.Paths.TempPath)
    {
        Remove-Item -Recurse -Force $hstwb.Paths.TempPath
    }

    Write-Host "Press enter to continue"
    Read-Host
    exit 1
}


# resolve paths
$kickstartEntriesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("data\kickstart-entries.csv")
$amigaOsEntriesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("data\amiga-os-entries.csv")
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
    Write-Host "Starting HstWB Installer Run..."

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
            'KickstartEntriesFile' = $kickstartEntriesFile;
            'AmigaOsEntriesFile' = $amigaOsEntriesFile;
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
        'Models' = @('A1200', 'A500');
        'Packages' = ReadPackages $packagesPath;
        'Settings' = ReadIniFile $settingsFile;
        'Assigns' = ReadIniFile $assignsFile;
        'UI' = @{
            'AmigaOs' = @{};
            'Kickstart' = @{}
        }
    }

    # upgrade settings and assigns
    UpgradeSettings $hstwb
    UpgradeAssigns $hstwb
    
    # update amiga os entries
    UpdateAmigaOsEntries $hstwb

    # update kickstart entries
    UpdateKickstartEntries $hstwb

    # detect user packages
    $hstwb.UserPackages = DetectUserPackages $hstwb
    
    # find amiga os files
    Write-Host "Finding Amiga OS sets in Amiga OS dir..."
    FindAmigaOsFiles $hstwb

    # find kickstart files
    Write-Host "Finding Kickstart sets in Kickstart dir..."
    FindKickstartFiles $hstwb
        
    # update packages and assigns
    UpdateInstallPackages $hstwb
    UpdateInstallUserPackages $hstwb
    UpdateAssigns $hstwb
        
    # find best matching kickstart rom set, if kickstart rom set doesn't exist
    if (($hstwb.KickstartEntries | Where-Object { $_.Set -eq $hstwb.Settings.Kickstart.KickstartSet }).Count -eq 0)
    {
        # set new kickstart rom set
        $hstwb.Settings.Kickstart.KickstartSet = FindBestMatchingKickstartSet $hstwb
    }

    # find best matching amiga os set, if amiga os set doesn't exist
    if (($hstwb.AmigaOsEntries | Where-Object { $_.Set -eq $hstwb.Settings.AmigaOs.AmigaOsSet }).Count -eq 0)
    {
        # set new amiga os set
        $hstwb.Settings.AmigaOs.AmigaOsSet = FindBestMatchingAmigaOsSet $hstwb
    }
    
    # save settings and assigns
    Save $hstwb

    Write-Host "Done"

    # ui amiga os set info
    UiAmigaOsSetInfo $hstwb $hstwb.Settings.AmigaOs.AmigaOsSet

    # ui kickstart set info
    UiKickstartSetInfo $hstwb $hstwb.Settings.Kickstart.KickstartSet

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
    # $kickstartRomSetHashes = @()
    # $kickstartRomSetHashes += $hstwb.KickstartEntries | Where-Object { $_.Set -eq $hstwb.Settings.Kickstart.KickstartSet }
    # $hstwb.KickstartEntries = $kickstartRomSetHashes
    
    # filter amiga os sets to only contain amiga os set defined in settings
    # $amigaOsSet = @()
    # $amigaOsSet += $hstwb.AmigaOsEntries | Where-Object { $_.Set -eq $hstwb.Settings.AmigaOs.AmigaOsSet }
    # $hstwb.AmigaOsEntries = $amigaOsSet

    # fail, if installer mode is install, build self install or test and kickstart entries is empty 
    if ($settings.Installer.Mode -match "^(Install|BuildSelfInstall|Test)$" -and $hstwb.KickstartEntries.Count -eq 0)
    {
        Fail ("Kickstart entries is empty!")
    }
    
    # fail, if installer mode is install and amiga os entries is empty 
    if ($settings.Installer.Mode -match "^Install$" -and $hstwb.AmigaOsEntries.Count -eq 0)
    {
        Fail ("Amiga OS entries is empty!")
    }

    # print title and settings
    $versionPadding = new-object System.String('-', ($hstwb.Version.Length + 2))
    Write-Host ("-------------------{0}" -f $versionPadding) -foregroundcolor "Yellow"
    Write-Host ("HstWB Installer Run v{0}" -f $hstwb.Version) -foregroundcolor "Yellow"
    Write-Host ("-------------------{0}" -f $versionPadding) -foregroundcolor "Yellow"
    Write-Host ""
    PrintSettings $hstwb
    Write-Host ""

    # find kickstart entry, is install mode is test, install or build self install
    if ($hstwb.Settings.Installer.Mode -match "^(Install|BuildSelfInstall|Test)$")
    {
        # get kickstart entry for running hstwb installer
        $kickstartEntry = $null
        foreach ($model in $hstwb.Models)
        {
            # get first run supported kickstart entry for model with detected file
            $kickstartEntry = $hstwb.KickstartEntries | Where-Object { $_.RunSupported -match 'true' -and $_.Model -match $model -and $_.File } | Select-Object -First 1

            if ($kickstartEntry)
            {
                break;
            }
        }

        # fail, if kickstart entry doesn't exist
        if (!$kickstartEntry)
        {
            Fail $hstwb ("Kickstart directory doesn't have {0} Kickstart rom file!" -f ($models -join '/'))
        }

        # set kickstart entry
        $hstwb.Paths.KickstartEntry = $kickstartEntry

        # kickstart rom key
        $kickstartRomKeyFile = Join-Path (Split-Path $kickstartEntry.File -Parent) -ChildPath 'rom.key'

        # fail, if kickstart entry is encrypted and kickstart rom key file doesn't exist
        if ($kickstartEntry.Encrypted -eq 'Yes' -and !(test-path -path $kickstartRomKeyFile))
        {
            Fail $hstwb ("Kickstart rom key file '{0}' doesn't exist!" -f $kickstartRomKeyFile)
        }

        # print kickstart entry
        Write-Host ("Kickstart rom: {0} '{1}'" -f $kickstartEntry.Name, $kickstartEntry.File)
    }

    # find amiga os 3.9 iso, amiga os 3.1.4 or 3.1 workbench and install adf entries, is install mode is install or build self install
    if ($hstwb.Settings.Installer.Mode -match "^(Install|BuildSelfInstall)$")
    {
        # find workbench adf, if installing amiga os and amiga os 3.9 iso is not present
        if ($hstwb.Settings.AmigaOs.InstallAmigaOs -eq 'Yes')
        {
            # find amiga os 3.9 iso entry
            $isoEntry = $hstwb.AmigaOsEntries | Where-Object { $_.Name -eq 'Amiga OS 3.9 Iso' -and $_.File } | Select-Object -First 1

            if ($isoEntry)
            {
                $hstwb.Paths.IsoEntry = $isoEntry

                # print amiga os 3.9 iso entry
                Write-Host ("Amiga OS 3.9 iso: {0} '{1}'" -f $isoEntry.Name, $isoEntry.File)
            }
            else
            {
                # find amiga os 3.1.4 workbench adf entry
                $amigaOs314WorkbenchAdfEntry = $hstwb.AmigaOsEntries | Where-Object { $_.Name -eq 'Amiga OS 3.1.4 Workbench Disk' -and $_.File } | Select-Object -First 1
                $amigaOs314InstallAdfEntry = $hstwb.AmigaOsEntries | Where-Object { $_.Name -eq 'Amiga OS 3.1.4 Install Disk' -and $_.File } | Select-Object -First 1

                if ($amigaOs314WorkbenchAdfEntry -and $amigaOs314InstallAdfEntry)
                {
                    $hstwb.Paths.WorkbenchAdfEntry = $amigaOs314WorkbenchAdfEntry
                    $hstwb.Paths.InstallAdfEntry = $amigaOs314InstallAdfEntry

                    # print amiga os 3.1.4 workbench adf entry
                    Write-Host ("Amiga OS 3.1.4 Workbench adf: {0} '{1}'" -f $amigaOs314WorkbenchAdfEntry.Name, $amigaOs314WorkbenchAdfEntry.File)
                    Write-Host ("Amiga OS 3.1.4 Install adf: {0} '{1}'" -f $amigaOs314InstallAdfEntry.Name, $amigaOs314InstallAdfEntry.File)
                }
                else
                {
                    # find amiga os 3.1 workbench adf entry
                    $amigaOs310WorkbenchAdfEntry = $hstwb.AmigaOsEntries | Where-Object { $_.Name -eq 'Amiga OS 3.1 Workbench Disk' -and $_.File } | Select-Object -First 1
                    if ($amigaOs310WorkbenchAdfEntry)
                    {
                        $hstwb.Paths.WorkbenchAdfEntry = $amigaOs310WorkbenchAdfEntry

                        # print amiga os 3.1 workbench adf entry
                        Write-Host ("Amiga OS 3.1 Workbench adf: {0} '{1}'" -f $amigaOs310WorkbenchAdfEntry.Name, $amigaOs310WorkbenchAdfEntry.File)
                    }
                }
            }
        }

        # fail, if iso, or workbench adf entries doesn't exist
        if (!$hstwb.Paths.IsoEntry -and !$hstwb.Paths.WorkbenchAdfEntry)
        {
            Fail $hstwb "Amiga OS 3.9 iso file, Amiga OS 3.1.4 Workbench and Install Disk adf files, or Amiga OS 3.1 Workbench Disk adf file is required to run HstWB Installer!"
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