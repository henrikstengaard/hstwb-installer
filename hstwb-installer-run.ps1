# HstWB Installer Run
# -------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-03-23
#
# A powershell script to run HstWB Installer automating installation of workbench, kickstart roms and packages to an Amiga HDF file.


Param(
	[Parameter(Mandatory=$true)]
	[string]$settingsDir
)


Import-Module (Resolve-Path('modules\HstwbInstaller-Config.psm1'))
Import-Module (Resolve-Path('modules\HstwbInstaller-Dialog.psm1'))
Import-Module (Resolve-Path('modules\HstwbInstaller-Data.psm1'))


Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Windows.Forms


# http://stackoverflow.com/questions/8982782/does-anyone-have-a-dependency-graph-and-topological-sorting-code-snippet-for-pow
function Get-TopologicalSort {
  param(
      [Parameter(Mandatory = $true, Position = 0)]
      [hashtable] $edgeList
  )

  # Make sure we can use HashSet
  Add-Type -AssemblyName System.Core

  # Clone it so as to not alter original
  $currentEdgeList = [hashtable] (Get-ClonedObject $edgeList)

  # algorithm from http://en.wikipedia.org/wiki/Topological_sorting#Algorithms
  $topologicallySortedElements = New-Object System.Collections.ArrayList
  $setOfAllNodesWithNoIncomingEdges = New-Object System.Collections.Queue

  $fasterEdgeList = @{}

  # Keep track of all nodes in case they put it in as an edge destination but not source
  $allNodes = New-Object -TypeName System.Collections.Generic.HashSet[object] -ArgumentList (,[object[]] $currentEdgeList.Keys)

  foreach($currentNode in $currentEdgeList.Keys) {
      $currentDestinationNodes = [array] $currentEdgeList[$currentNode]
      if($currentDestinationNodes.Length -eq 0) {
          $setOfAllNodesWithNoIncomingEdges.Enqueue($currentNode)
      }

      foreach($currentDestinationNode in $currentDestinationNodes) {
          if(!$allNodes.Contains($currentDestinationNode)) {
              [void] $allNodes.Add($currentDestinationNode)
          }
      }

      # Take this time to convert them to a HashSet for faster operation
      $currentDestinationNodes = New-Object -TypeName System.Collections.Generic.HashSet[object] -ArgumentList (,[object[]] $currentDestinationNodes )
      [void] $fasterEdgeList.Add($currentNode, $currentDestinationNodes)        
  }

  # Now let's reconcile by adding empty dependencies for source nodes they didn't tell us about
  foreach($currentNode in $allNodes) {
      if(!$currentEdgeList.ContainsKey($currentNode)) {
          [void] $currentEdgeList.Add($currentNode, (New-Object -TypeName System.Collections.Generic.HashSet[object]))
          $setOfAllNodesWithNoIncomingEdges.Enqueue($currentNode)
      }
  }

  $currentEdgeList = $fasterEdgeList

  while($setOfAllNodesWithNoIncomingEdges.Count -gt 0) {        
      $currentNode = $setOfAllNodesWithNoIncomingEdges.Dequeue()
      [void] $currentEdgeList.Remove($currentNode)
      [void] $topologicallySortedElements.Add($currentNode)

      foreach($currentEdgeSourceNode in $currentEdgeList.Keys) {
          $currentNodeDestinations = $currentEdgeList[$currentEdgeSourceNode]
          if($currentNodeDestinations.Contains($currentNode)) {
              [void] $currentNodeDestinations.Remove($currentNode)

              if($currentNodeDestinations.Count -eq 0) {
                  [void] $setOfAllNodesWithNoIncomingEdges.Enqueue($currentEdgeSourceNode)
              }                
          }
      }
  }

  if($currentEdgeList.Count -gt 0) {
      throw "Graph has at least one cycle!"
  }

  return $topologicallySortedElements
}


# Idea from http://stackoverflow.com/questions/7468707/deep-copy-a-dictionary-hashtable-in-powershell 
function Get-ClonedObject {
    param($DeepCopyObject)
    $memStream = new-object IO.MemoryStream
    $formatter = new-object Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $formatter.Serialize($memStream,$DeepCopyObject)
    $memStream.Position=0
    $formatter.Deserialize($memStream)
}


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


# write text file encoded for Amiga
function WriteAmigaTextLines($path, $lines)
{
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
	$utf8 = [System.Text.Encoding]::UTF8;

	$amigaTextBytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $utf8.GetBytes($lines -join "`n"))
	[System.IO.File]::WriteAllText($path, $iso88591.GetString($amigaTextBytes), $iso88591)
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
function FindPackagesToInstall()
{
    # get package files in packages directory
    $packageFiles = @()
    $packageFiles += Get-ChildItem -Path $packagesPath -filter *.zip


    # get install packages defined in settings packages section
    $packageFileNames = @()
    if ($settings.Packages.InstallPackages -and $settings.Packages.InstallPackages -ne '')
    {
        $packageFileNames += $settings.Packages.InstallPackages.ToLower() -split ',' | Where-Object { $_ }
    }


    $packageNames = @{}
    $packageDetails = @{}
    $packageDependencies = @{}

    foreach ($packageFileName in $packageFileNames)
    {
        # get package file for package
        $packageFile = $packageFiles | Where-Object { $_.Name -eq ($packageFileName + ".zip") } | Select-Object -First 1


        # write warning and skip, if package file doesn't exist
        if (!$packageFile)
        {
            Fail ("Package '$packageFileName' doesn't exist in packages directory '$packagesPath'")
        }


        # read package ini text file from package file
        $packageIniText = ReadZipEntryTextFile $packageFile.FullName 'package.ini$'

        # return, if harddrives uae text doesn't exist
        if (!$packageIniText)
        {
            Fail ("Package '" + $packageFile.FullName + "' doesn't contain a package.ini file")
        }


        # read package ini file
        $packageIni = ReadIniText $packageIniText


        # fail, if package name doesn't exist
        if (!$packageIni.Package.Name -or $packageIni.Package.Name -eq '')
        {
            Fail ("Package '$packageFileName' doesn't contain name in package.ini file")
        }


        # package name
        $packageName = $packageIni.Package.Name


        # package full name
        $packageFullName = "{0} v{1}" -f $packageIni.Package.Name, $packageIni.Package.Version


        # add package details
        $packageDetails.Set_Item($packageName, @{ "Name" = $packageName; "FullName" = $packageFullName; "Package" = $packageFileName; "PackageFile" = $packageFile.FullName })


        # add package dependencies
        $dependencies = @()
        $dependencies += $packageIni.Package.Dependencies -split ',' | Where-Object { $_ }
        $packageDependencies.Set_Item($packageName, $dependencies)
    }


    $installPackages = @()


    # write install packages script, if there are any packages to install
    if ($packageFileNames.Count -gt 0)
    {
        $packagesSortedByDependencies = Get-TopologicalSort $packageDependencies

        foreach($packageName in $packagesSortedByDependencies)
        {
            # skip package from dependencies, if not part of packages that should be installed
            if (!$packageDetails.ContainsKey($packageName))
            {
                continue
            }

            $installPackages += $packageDetails.Get_Item($packageName)
        }
    }


    return $installPackages
}


# build user assign script lines
function BuildUserAssignScriptLines($createDirectories)
{
    $hstwbInstallerAssigns = $assigns.Get_Item('HstWB Installer')

    $userAssignScriptLines = @()

    foreach ($assignName in $hstwbInstallerAssigns.keys)
    {
        # skip, if assign name is 'HstWBInstallerDir' and installer mode is build package installation
        if ($assignName -match 'HstWBInstallerDir' -and $settings.Installer.Mode -eq "BuildPackageInstallation")
        {
            continue
        }

        # get assign path and drive
        $assignPath = $hstwbInstallerAssigns.Get_Item($assignName)
        $assignDrive = $assignPath -replace '^([^:]+:).*', '$1'

        # add package assign lines
        $userAssignScriptLines += "; Add assign for '$assignName' to '$assignPath'"
        $userAssignScriptLines += "Assign >NIL: EXISTS ""$assignDrive"""
        $userAssignScriptLines += "IF WARN"
        $userAssignScriptLines += "  echo ""Error: Drive '$assignDrive' doesn't exist for assign '$assignPath'!"""
        $userAssignScriptLines += "  ask ""Press ENTER to exit"""
        $userAssignScriptLines += "  QUIT 5"
        $userAssignScriptLines += "ELSE"

        # create directory for assignpath or check if path exist
        if ($createDirectories)
        {
            $userAssignScriptLines += ("  makepath """ + $assignPath + """")
            $userAssignScriptLines += ("  Assign " + $assignName + ": """ + $assignPath + """")
        }
        else
        {
            $userAssignScriptLines += ("  IF EXISTS """ + $assignPath + """")
            $userAssignScriptLines += ("    Assign " + $assignName + ": """ + $assignPath + """")
            $userAssignScriptLines += "  ELSE"
            $userAssignScriptLines += "    echo ""Error: Path '$assignPath' doesn't exist for assign!"""
            $userAssignScriptLines += "    ask ""Press ENTER to exit"""
            $userAssignScriptLines += "    QUIT 5"
            $userAssignScriptLines += "  ENDIF"
        }

        $userAssignScriptLines += "ENDIF"
    }

    return $userAssignScriptLines
}


# build install package script lines
function BuildInstallPackageScriptLines($packageNames)
{
    $hstwbInstallerAssigns = $assigns.Get_Item("HstWB Installer")

    $installPackageScripts = @()

    foreach ($packageName in $packageNames)
    {
        # add package assigns
        $package = $packages.Get_Item($packageName.ToLower())


        # build package assigns
        $packageAssigns = @{}            
        if ($assigns.ContainsKey($package.Package.Name))
        {
            $tempPackageAssigns = $assigns.Get_Item($package.Package.Name)
            $tempPackageAssigns.keys | ForEach-Object { $packageAssigns.Set_Item($_.ToUpper(), $tempPackageAssigns.Get_Item($_)) }
        }


        $name = ($package.Package.Name + " v" + $package.Package.Version)

        # add package installation lines to install packages script
        $installPackageLines = @()
        $installPackageLines += ("; Install package "+ $name)
        $installPackageLines += "echo """""
        $installPackageLines += ("echo ""Package '" + $name + "'""")

        $removePackageAssignLines = @()

        # get package assign names
        $packageAssignNames = @()
        if ($package.Package.Assigns)
        {
            $packageAssignNames += $package.Package.Assigns -split ',' | Where-Object { $_ } | ForEach-Object { $_.ToUpper() }
        }


        # build global assign names from hstwb installer and package assigns
        $globalAssignNames = @{}
        $hstwbInstallerAssigns.keys | ForEach-Object { $globalAssignNames.Set_Item($_.ToUpper(), $true) }
        $packageAssigns.keys | ForEach-Object { $globalAssignNames.Set_Item($_.ToUpper(), $true) }


        # add package assigns, if assigns exist for package and any are defined
        if ($packageAssignNames.Count -gt 0)
        {
            foreach ($packageAssignName in $packageAssignNames)
            {
                # fail, if package assign name doesn't exist in either hstwb installer or package assigns
                if (!$globalAssignNames.ContainsKey($packageAssignName))
                {
                    Fail ("Error: Package '" + $package.Package.Name + "' doesn't have assign defined for '$packageAssignName' in either hstwb installer or package assigns!")
                }

                # skip, if package assign name is not part of package assigns
                if (!$packageAssigns.ContainsKey($packageAssignName))
                {
                    continue
                }

                # get assign path and drive
                $assignPath = $packageAssigns.Get_Item($packageAssignName)
                $assignDrive = $assignPath -replace '^([^:]+:).*', '$1'

                # add package assign lines
                $installPackageLines += "; Add package assign for '$packageAssignName' to '$assignPath'"
                $installPackageLines += "Assign >NIL: EXISTS ""$assignDrive"""
                $installPackageLines += "IF WARN"
                $installPackageLines += "  echo ""Error: '$assignDrive' doesn't exist and is required by package!"""
                $installPackageLines += "  ask ask ""Press ENTER to continue"""
                $installPackageLines += "ELSE"
                $installPackageLines += ("  makepath """ + $assignPath + """")
                $installPackageLines += ("  Assign " + $packageAssignName + ": """ + $assignPath + """")
                $installPackageLines += "ENDIF"

                # remove package assign lines
                $removePackageAssignLines += ("Assign " + $packageAssignName + ": """ + $assignPath + """ REMOVE")
            }
        }


        # add assign package dir and execute package install
        $installPackageLines += "; Assign package dir and execute install script"
        $installPackageLines += ("Assign PACKAGEDIR: ""PACKAGES:" + $packageName + """")
        $installPackageLines += "execute ""PACKAGEDIR:Install"""
        $installPackageLines += ("Assign PACKAGEDIR: ""PACKAGES:" + $packageName + """ REMOVE")


        # add remove package assign lines, if there are any
        if ($removePackageAssignLines.Count -gt 0)
        {
            $installPackageLines += "; Remove package assigns"
            $installPackageLines += $removePackageAssignLines
        }

        $installPackageScripts += @{ "Id" = [guid]::NewGuid().ToString().Replace('-',''); "Name" = $name; "Lines" = $installPackageLines; "PackageName" = $packageName }
    }

    return $installPackageScripts
}


# build install packages script lines
function BuildInstallPackagesScriptLines($installPackages)
{
    # install packages title message
    $installPackagesScriptLines = @()
    $installPackagesScriptLines += "echo ""*ec"""
    $installPackagesScriptLines += "echo ""Package Installation"""
    $installPackagesScriptLines += "echo ""--------------------"""

    # build install package script lines
    $installPackageScripts = @()
    $installPackageScripts += BuildInstallPackageScriptLines ($installPackages | ForEach-Object { $_.Package })

    if (($settings.Installer.Mode -eq "BuildSelfInstall" -or $settings.Installer.Mode -eq "BuildPackageInstallation") -and $installPackages.Count -gt 0)
    {
        # get install package name padding
        $installPackageNamesPadding = ($installPackages | ForEach-Object { $_.FullName } | Sort-Object @{expression={$_.Length};Ascending=$false} | Select-Object -First 1).Length

        # install packages label
        $installPackagesScriptLines += "LAB installpackagesmenu"
        $installPackagesScriptLines += "echo """" NOLINE >T:installpackagesmenu"

        # add package options to menu
        foreach ($installPackageScript in $installPackageScripts)
        {
            $installPackagesScriptLines += (("echo ""{0,-" + $installPackageNamesPadding + "} : "" NOLINE >>T:installpackagesmenu") -f $installPackageScript.Name)
            $installPackagesScriptLines += ("IF EXISTS T:" + $installPackageScript.Id)
            $installPackagesScriptLines += "  echo ""NO "" >>T:installpackagesmenu"
            $installPackagesScriptLines += "ELSE"
            $installPackagesScriptLines += "  echo ""YES"" >>T:installpackagesmenu"
            $installPackagesScriptLines += "ENDIF"
        }

        # add install package option and show install packages menu
        $installPackagesScriptLines += "echo """ + (new-object System.String('-', ($installPackageNamesPadding + 6))) + """ >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""View Readme"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Edit assigns"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Install packages"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "set installpackagesmenu ````"
        $installPackagesScriptLines += "set installpackagesmenu ``ReqList CLONERT I=T:installpackagesmenu H=""Select packages to install"" PAGE=18``"
        $installPackagesScriptLines += "delete >NIL: T:installpackagesmenu"

        # switch package options
        for($i = 0; $i -lt $installPackageScripts.Count; $i++)
        {
            $installPackageScript = $installPackageScripts[$i]

            $installPackagesScriptLines += ""
            $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($i + 1) + """")
            $installPackagesScriptLines += ("  IF EXISTS T:" + $installPackageScript.Id)
            $installPackagesScriptLines += ("    delete >NIL: T:" + $installPackageScript.Id)
            $installPackagesScriptLines += "  ELSE"
            $installPackagesScriptLines += ("    echo """" NOLINE >T:" + $installPackageScript.Id)
            $installPackagesScriptLines += "  ENDIF"
            $installPackagesScriptLines += "ENDIF"
        }

        # install packages option and skip back to install packages menu 
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($installPackageScripts.Count + 2) + """")
        $installPackagesScriptLines += "  SKIP viewreadmemenu"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($installPackageScripts.Count + 3) + """")
        $installPackagesScriptLines += "  SKIP editassignsmenu"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($installPackageScripts.Count + 4) + """")
        $installPackagesScriptLines += "  SKIP installpackages"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "SKIP BACK installpackagesmenu"



        # view readme
        # -----------
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "LAB viewreadmemenu"
        $installPackagesScriptLines += "echo """" NOLINE >T:viewreadmemenu"

        # add package options to view readme menu
        foreach ($installPackageScript in $installPackageScripts)
        {
            $installPackagesScriptLines += (("echo ""{0,-" + $installPackageNamesPadding + "}"" >>T:viewreadmemenu") -f $installPackageScript.Name)
        }

        # add back option to view readme menu
        $installPackagesScriptLines += "echo """ + (new-object System.String('-', $installPackageNamesPadding)) + """ >>T:viewreadmemenu"
        $installPackagesScriptLines += "echo ""Back"" >>T:viewreadmemenu"

        $installPackagesScriptLines += "set viewreadmemenu ````"
        $installPackagesScriptLines += "set viewreadmemenu ``ReqList CLONERT I=T:viewreadmemenu H=""View Readme"" PAGE=18``"
        $installPackagesScriptLines += "delete >NIL: T:viewreadmemenu"

        # switch package options
        for($i = 0; $i -lt $installPackageScripts.Count; $i++)
        {
            $installPackageScript = $installPackageScripts[$i]

            $installPackagesScriptLines += ""
            $installPackagesScriptLines += ("IF ""`$viewreadmemenu"" eq """ + ($i + 1) + """")
            $installPackagesScriptLines += ("  IF EXISTS PACKAGES:{0}/README.guide" -f $installPackageScript.PackageName)
            $installPackagesScriptLines += ("    cd PACKAGES:" + $installPackageScript.PackageName)
            $installPackagesScriptLines += "    multiview README.guide"
            $installPackagesScriptLines += "    cd PACKAGES:"
            $installPackagesScriptLines += "  ELSE"
            $installPackagesScriptLines += ("    REQUESTCHOICE ""No Readme"" ""Package '{0}' doesn't have a readme file!"" ""OK"" >NIL:" -f $installPackageScript.Name)
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
        $installPackagesScriptLines += "LAB editassignsmenu"
        $installPackagesScriptLines += "REQUESTCHOICE ""Not implemented"" ""Edit assigns is not implemented yet!"" ""OK"" >NIL:"
        $installPackagesScriptLines += "SKIP BACK installpackagesmenu"


        # install packages
        # ----------------
        $installPackagesScriptLines += "LAB installpackages"

        # add install package script for each package
        foreach ($installPackageScript in $installPackageScripts)
        {
            $installPackagesScriptLines += ""
            $installPackagesScriptLines += ("IF NOT EXISTS T:" + $installPackageScript.Id)
            $installPackageScript.Lines | ForEach-Object { $installPackagesScriptLines += ("  " + $_) }
            $installPackagesScriptLines += "ENDIF"
        }
    }
    else 
    {
        # add install package script for each package
        foreach ($installPackageScript in $installPackageScripts)
        {
            $installPackageScript.Lines | ForEach-Object { $installPackagesScriptLines += $_ }
        }
    }

    return $installPackagesScriptLines
}


# build winuae image harddrives config text
function BuildWinuaeImageHarddrivesConfigText($disableBootableHarddrives)
{
    # winuae image harddrives config file
    $winuaeImageHarddrivesUaeConfigFile = [System.IO.Path]::Combine($settings.Image.ImageDir, "harddrives.uae")

    # fail, if winuae image harddrives config file doesn't exist
    if (!(Test-Path -Path $winuaeImageHarddrivesUaeConfigFile))
    {
        Fail ("Error: Image harddrives config file '" + $winuaeImageHarddrivesUaeConfigFile + "' doesn't exist!")
    }

    # read winuae image harddrives config text
    $winuaeImageHarddrivesConfigText = [System.IO.File]::ReadAllText($winuaeImageHarddrivesUaeConfigFile)

    # replace imagedir placeholders
    $winuaeImageHarddrivesConfigText = $winuaeImageHarddrivesConfigText.Replace('[$ImageDir]', $settings.Image.ImageDir)
    $winuaeImageHarddrivesConfigText = $winuaeImageHarddrivesConfigText.Replace('[$ImageDirEscaped]', $settings.Image.ImageDir.Replace('\', '\\'))
    $winuaeImageHarddrivesConfigText = $winuaeImageHarddrivesConfigText.Trim()

    if ($disableBootableHarddrives)
    {
        $winuaeImageHarddrivesConfigText = ($winuaeImageHarddrivesConfigText -split "`r`n" | ForEach-Object { $_ -replace ',-?\d+$', ',-128' -replace ',-?\d+,,uae$', ',-128,,uae' }) -join "`r`n"
    }

    return $winuaeImageHarddrivesConfigText
}


# build winuae install harddrives config text
function BuildWinuaeInstallHarddrivesConfigText($installDir, $packagesDir)
{
    # build winuae image harddrives config
    $winuaeImageHarddrivesConfigText = BuildWinuaeImageHarddrivesConfigText $true

    # get uaehf index of last uaehf config from winuae image harddrives config
    $uaehfIndex = 0
    $winuaeImageHarddrivesConfigText -split "`r`n" | ForEach-Object { $_ | Select-String -Pattern '^uaehf(\d+)=' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $uaehfIndex = $_.Groups[1].Value.Trim() } }

    # winuae install harddrives config file
    $winuaeInstallHarddrivesConfigFile = [System.IO.Path]::Combine($winuaePath, "harddrives.uae")

    # fail, if winuae install harddrives config file doesn't exist
    if (!(Test-Path -Path $winuaeInstallHarddrivesConfigFile))
    {
        Fail ("Error: Install harddrives config file '" + $winuaeInstallHarddrivesConfigFile + "' doesn't exist!")
    }

    # read winuae install harddrives config file
    $winuaeInstallHarddrivesConfigText = [System.IO.File]::ReadAllText($winuaeInstallHarddrivesConfigFile)

    # replace winuae install harddrives placeholders
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$InstallDir]', $installDir)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$InstallUaehfIndex]', [int]$uaehfIndex + 1)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$PackagesDir]', $packagesDir)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Replace('[$PackagesUaehfIndex]', [int]$uaehfIndex + 2)
    $winuaeInstallHarddrivesConfigText = $winuaeInstallHarddrivesConfigText.Trim()

    # return winuae image and install harddrives config
    return $winuaeImageHarddrivesConfigText + "`r`n" + $winuaeInstallHarddrivesConfigText
}


# run test
function RunTest
{
    # build winuae image harddrives config text
    $winuaeImageHarddrivesConfigText = BuildWinuaeImageHarddrivesConfigText $false

    # read winuae test config file
    $winuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($winuaePath, "hstwb-installer.uae")
    $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)

    # replace winuae test config placeholders
    $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KICKSTARTROMFILE]', $kickstartRomHash.File)
    $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WORKBENCHADFFILE]', '')
    $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$HARDDRIVES]', $winuaeImageHarddrivesConfigText)

    # write winuae test config file to temp dir
    $tempWinuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($tempPath, "hstwb-installer.uae")
    [System.IO.File]::WriteAllText($tempWinuaeHstwbInstallerConfigFile, $winuaeHstwbInstallerConfigText)


    # print launching winuae message
    Write-Host ""
    Write-Host "Launching WinUAE to test image..."


    # winuae args
    $winuaeArgs = "-f ""$tempWinuaeHstwbInstallerConfigFile"""

    # exit, if winuae fails
    if ((StartProcess $settings.Winuae.WinuaePath $winuaeArgs $directory) -ne 0)
    {
        Fail ("Failed to run '" + $settings.Winuae.WinuaePath + "' with arguments '$winuaeArgs'")
    }
}


# run install
function RunInstall()
{
    # print preparing install message
    Write-Host ""
    Write-Host "Preparing install..."


    # copy winuae install dir
    $winuaeInstallDir = [System.IO.Path]::Combine($winuaePath, "install")
    Copy-Item -Path $winuaeInstallDir $tempPath -recurse -force


    # set temp install and packages dir
    $tempInstallDir = [System.IO.Path]::Combine($tempPath, "install")
    $tempPackagesDir = [System.IO.Path]::Combine($tempPath, "packages")


    # copy winuae shared dir
    $winuaeSharedDir = [System.IO.Path]::Combine($winuaePath, "shared")
    Copy-Item -Path "$winuaeSharedDir\*" $tempInstallDir -recurse -force


    # create temp packages path
    if(!(test-path -path $tempPackagesDir))
    {
        md $tempPackagesDir | Out-Null
    }


    # prepare install workbench
    if ($settings.Workbench.InstallWorkbench -eq 'Yes')
    {
        # copy workbench adf set files to temp install dir
        Write-Host "Copying Workbench adf files to temp install dir"
        $workbenchAdfSetHashes | Where { $_.File } | % { Copy-Item -Path $_.File -Destination ([System.IO.Path]::Combine($tempInstallDir, $_.Filename)) }
    }
    else
    {
        # delete install workbench file in install dir
        $installWorkbenchFile = [System.IO.Path]::Combine($tempInstallDir, "S\Install-Workbench")
        Remove-Item $installWorkbenchFile
    }


    # prepare install kickstart
    if ($settings.Kickstart.InstallKickstart -eq 'Yes')
    {
        # copy kickstart rom set files to temp install dir
        Write-Host "Copying Kickstart rom files to temp install dir"
        $kickstartRomSetHashes | Where { $_.File } | % { Copy-Item -Path $_.File -Destination ([System.IO.Path]::Combine($tempInstallDir, $_.Filename)) }

        # copy kickstart rom key file  to temp install dir, if kickstart roms are encrypted
        if ($kickstartRomHash.Encrypted)
        {
            Copy-Item -Path $kickstartRomKeyFile -Destination ([System.IO.Path]::Combine($tempInstallDir, "rom.key"))
        }
    }
    else
    {
        # delete install kickstart file in install dir
        $installKickstartFile = [System.IO.Path]::Combine($tempInstallDir, "S\Install-Kickstart")
        Remove-Item $installKickstartFile
    }


    # find packages to install
    $installPackages = FindPackagesToInstall


    # build user assigns script lines
    $userAssignScriptLines = BuildUserAssignScriptLines $true

    # write user assign to install dir
    $userAssignFile = [System.IO.Path]::Combine($tempInstallDir, "S\User-Assign")
    WriteAmigaTextLines $userAssignFile $userAssignScriptLines 


    # extract packages and write install packages script, if there's packages to install
    if ($installPackages.Count -gt 0)
    {
        $installPackagesLines = @()

        foreach($installPackage in $installPackages)
        {
            # extract package file to package directory
            Write-Host ("Extracting '" + $installPackage.Package + "' package to temp install dir")
            $packageDir = [System.IO.Path]::Combine($tempPackagesDir, $installPackage.Package)

            if(!(test-path -path $packageDir))
            {
                mkdir $packageDir | Out-Null
            }

            [System.IO.Compression.ZipFile]::ExtractToDirectory($installPackage.PackageFile, $packageDir)
        }

        # build install package script lines
        $installPackagesScriptLines = BuildInstallPackagesScriptLines $installPackages

        # write install packages script
        $installPackagesFile = [System.IO.Path]::Combine($tempInstallDir, "S\Install-Packages")
        WriteAmigaTextLines $installPackagesFile $installPackagesScriptLines 
    }


    # build winuae install harddrives config
    $winuaeInstallHarddrivesConfigText = BuildWinuaeInstallHarddrivesConfigText $tempInstallDir $tempPackagesDir


    # read winuae hstwb installer config file
    $winuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($winuaePath, "hstwb-installer.uae")
    $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)


    # replace winuae hstwb installer config placeholders
    $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KICKSTARTROMFILE]', $kickstartRomHash.File)
    $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WORKBENCHADFFILE]', $workbenchAdfHash.File)
    $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$HARDDRIVES]', $winuaeInstallHarddrivesConfigText)


    # write winuae hstwb installer config file to temp install dir
    $tempWinuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($tempPath, "hstwb-installer.uae")
    [System.IO.File]::WriteAllText($tempWinuaeHstwbInstallerConfigFile, $winuaeHstwbInstallerConfigText)


    # write installing file in install dir. should be deleted by winuae and is used to verify if installation process succeeded
    $installingFile = [System.IO.Path]::Combine($tempInstallDir, "S\Installing")
    [System.IO.File]::WriteAllText($installingFile, "")


    # print preparing installation done message
    Write-Host "Done."


    # print launching winuae message
    Write-Host ""
    Write-Host "Launching WinUAE to install image..."


    # winuae args
    $winuaeArgs = "-f ""$tempWinuaeHstwbInstallerConfigFile"""

    # exit, if winuae fails
    if ((StartProcess $settings.Winuae.WinuaePath $winuaeArgs $directory) -ne 0)
    {
        Fail ("Failed to run '" + $settings.Winuae.WinuaePath + "' with arguments '$winuaeArgs'")
    }


    # fail, if installing file exists
    if (Test-Path -path $installingFile)
    {
        Fail "WinUAE installation failed"
    }
}


# run build self install
function RunBuildSelfInstall()
{
    # print preparing self install message
    Write-Host ""
    Write-Host "Preparing build self install..."    


    # create temp install path
    $tempInstallDir = [System.IO.Path]::Combine($tempPath, "install")
    if(!(test-path -path $tempInstallDir))
    {
        md $tempInstallDir | Out-Null
    }


    # create temp packages path
    $tempPackagesDir = [System.IO.Path]::Combine($tempPath, "packages")
    if(!(test-path -path $tempPackagesDir))
    {
        md $tempPackagesDir | Out-Null
    }


    # copy winuae self install build dir
    $winuaeSelfInstallBuildDir = [System.IO.Path]::Combine($winuaePath, "selfinstall")
    Copy-Item -Path "$winuaeSelfInstallBuildDir\*" $tempInstallDir -recurse -force


    # copy winuae shared dir
    $winuaeSharedDir = [System.IO.Path]::Combine($winuaePath, "shared")
    Copy-Item -Path "$winuaeSharedDir\*" $tempInstallDir -recurse -force
    Copy-Item -Path "$winuaeSharedDir\*" "$tempInstallDir\System" -recurse -force


    # build user assigns script lines
    $userAssignScriptLines = @()
    $userAssignScriptLines += BuildUserAssignScriptLines $true

    # write user assign script for building self install
    $userAssignFile = [System.IO.Path]::Combine($tempInstallDir, "S\User-Assign")
    WriteAmigaTextLines $userAssignFile $userAssignScriptLines

    # write user assign script for self install
    $userAssignScriptLines +="Assign PACKAGES: ""HstWBInstallerDir:Packages"""
    $userAssignFile = [System.IO.Path]::Combine($tempInstallDir, "System\S\User-Assign")
    WriteAmigaTextLines $userAssignFile $userAssignScriptLines


    # find packages to install
    $installPackages = FindPackagesToInstall


    # extract packages and write install packages script, if there's packages to install
    if ($installPackages.Count -gt 0)
    {
        foreach($installPackage in $installPackages)
        {
            # extract package file to package directory
            Write-Host ("Extracting '" + $installPackage.Package + "' package to temp install dir")
            $packageDir = [System.IO.Path]::Combine($tempPackagesDir, $installPackage.Package)

            if(!(test-path -path $packageDir))
            {
                mkdir $packageDir | Out-Null
            }

            [System.IO.Compression.ZipFile]::ExtractToDirectory($installPackage.PackageFile, $packageDir)
        }
    }


    # build install package script lines
    $installPackagesScriptLines = @()
    $installPackagesScriptLines += BuildInstallPackagesScriptLines $installPackages
    $installPackagesScriptLines += "echo """""
    $installPackagesScriptLines += "echo ""Package installation is complete."""
    $installPackagesScriptLines += "echo """""
    $installPackagesScriptLines += "ask ""Press ENTER to continue"""


    # write install packages script
    $installPackagesScriptFile = [System.IO.Path]::Combine($tempInstallDir, "HstWBInstaller\Install-Packages")
    WriteAmigaTextLines $installPackagesScriptFile $installPackagesScriptLines 


    $hstwbInstallerAssigns = $assigns.Get_Item("HstWB Installer")

    if (!$hstwbInstallerAssigns)
    {
        Fail ("Failed to run install. HstWB Installer assigns doesn't exist!")
    }


    $hstwbInstallAssignName = $hstwbInstallerAssigns.keys | Where-Object { $_ -match 'HstWBInstallerDir' } | Select-Object -First 1

    if (!$hstwbInstallerAssigns)
    {
        Fail ("Failed to run install. HstWB Installer assigns doesn't containassign for 'HstWBInstallerDir' exist!")
    }

    $hstwbInstallDir = $hstwbInstallerAssigns.Get_Item($hstwbInstallAssignName)

    $removeHstwbInstallerScriptLines = @()
    $removeHstwbInstallerScriptLines += "Assign PACKAGES: ""HstWBInstallerDir:Packages"" REMOVE"
    $removeHstwbInstallerScriptLines += "Assign >NIL: EXISTS ""HSTWBINSTALLERDIR:"""
    $removeHstwbInstallerScriptLines += "IF NOT WARN"
    $removeHstwbInstallerScriptLines += "  Assign >NIL: HSTWBINSTALLERDIR: ""$hstwbInstallDir"" REMOVE"
    $removeHstwbInstallerScriptLines += "  IF EXISTS ""$hstwbInstallDir"""
    $removeHstwbInstallerScriptLines += "    delete >NIL: ""$hstwbInstallDir"" ALL"
    $removeHstwbInstallerScriptLines += "  ENDIF"
    $removeHstwbInstallerScriptLines += "ENDIF"
    
    # write remove hstwb installer script
    $removeHstwbInstallerScriptFile = [System.IO.Path]::Combine($tempInstallDir, "System\S\Remove-HstWBInstaller")
    WriteAmigaTextLines $removeHstwbInstallerScriptFile $removeHstwbInstallerScriptLines 


    # build winuae install harddrives config
    $winuaeInstallHarddrivesConfigText = BuildWinuaeInstallHarddrivesConfigText $tempInstallDir $tempPackagesDir


    # read winuae hstwb installer config file
    $winuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($winuaePath, "hstwb-installer.uae")
    $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)


    # replace winuae hstwb installer config placeholders
    $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KICKSTARTROMFILE]', $kickstartRomHash.File)
    $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WORKBENCHADFFILE]', $workbenchAdfHash.File)
    $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$HARDDRIVES]', $winuaeInstallHarddrivesConfigText)


    # write winuae hstwb installer config file to temp install dir
    $tempWinuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($tempPath, "hstwb-installer.uae")
    [System.IO.File]::WriteAllText($tempWinuaeHstwbInstallerConfigFile, $winuaeHstwbInstallerConfigText)


    # write installing file in install dir. should be deleted by winuae and is used to verify if installation process succeeded
    $installingFile = [System.IO.Path]::Combine($tempInstallDir, "S\Installing")
    [System.IO.File]::WriteAllText($installingFile, "")


    # print preparing installation done message
    Write-Host "Done."


    # print launching winuae message
    Write-Host ""
    Write-Host "Launching WinUAE to build self install image..."


    # winuae args
    $winuaeArgs = "-f ""$tempWinuaeHstwbInstallerConfigFile"""

    # exit, if winuae fails
    if ((StartProcess $settings.Winuae.WinuaePath $winuaeArgs $directory) -ne 0)
    {
        Fail ("Failed to run '" + $settings.Winuae.WinuaePath + "' with arguments '$winuaeArgs'")
    }


    # fail, if installing file exists
    if (Test-Path -path $installingFile)
    {
        Fail "WinUAE installation failed"
    }
}

# run build package installation
function RunBuildPackageInstallation()
{
    $outputPackageInstallationPath = FolderBrowserDialog "Select new directory for package installation" ${Env:USERPROFILE} $true

    # return, if package installation directory is null
    if ($outputPackageInstallationPath -eq $null)
    {
        Write-Host ""
        Write-Host "Cancelled, no package installation directory selected!" -ForegroundColor Yellow
        return
    }


    # print building package installation message
    Write-Host ""
    Write-Host "Building package installation..."    


    # find packages to install
    $installPackages = FindPackagesToInstall


    # extract packages and write install packages script, if there's packages to install
    if ($installPackages.Count -gt 0)
    {
        foreach($installPackage in $installPackages)
        {
            # extract package file to package directory
            Write-Host ("Extracting '" + $installPackage.Package + "' package to package installation path")
            $packageDir = [System.IO.Path]::Combine($outputPackageInstallationPath, $installPackage.Package)

            if(!(test-path -path $packageDir))
            {
                mkdir $packageDir | Out-Null
            }

            [System.IO.Compression.ZipFile]::ExtractToDirectory($installPackage.PackageFile, $packageDir)
        }
    }


    # build install package script lines
    $packageInstallationScriptLines = @()
    $packageInstallationScriptLines += BuildUserAssignScriptLines $false
    $packageInstallationScriptLines += "Assign PACKAGES: ""``CD``"""
    $packageInstallationScriptLines += "SetEnv TZ MST7"
    $packageInstallationScriptLines += BuildInstallPackagesScriptLines $installPackages
    $packageInstallationScriptLines += "echo """""
    $packageInstallationScriptLines += "echo ""Package installation is complete."""
    $packageInstallationScriptLines += "echo """""
    $packageInstallationScriptLines += "ask ""Press ENTER to continue"""


    # write install packages script
    $installPackagesScriptFile = [System.IO.Path]::Combine($outputPackageInstallationPath, "Package Installation")
    WriteAmigaTextLines $installPackagesScriptFile $packageInstallationScriptLines 


    # copy package installation files
    Copy-Item -Path "$packageInstallationPath\*" $outputPackageInstallationPath -recurse -force
}


# fail
function Fail($message)
{
    if(test-path -path $tempPath)
    {
        Remove-Item -Recurse -Force $tempPath
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
$packageInstallationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("packageinstallation")
$tempPath = [System.IO.Path]::Combine($env:TEMP, "HstWB-Installer_" + [System.IO.Path]::GetRandomFileName())
$settingsDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($settingsDir)

$settingsFile = [System.IO.Path]::Combine($settingsDir, "hstwb-installer-settings.ini")
$assignsFile = [System.IO.Path]::Combine($settingsDir, "hstwb-installer-assigns.ini")


# fail, if settings file doesn't exist
if (!(test-path -path $settingsFile))
{
    Fail ("Error: Settings file '$settingsFile' doesn't exist!")
}


# fail, if assigns file doesn't exist
if (!(test-path -path $assignsFile))
{
    Fail ("Error: Assigns file '$assignsFile' doesn't exist!")
}


# read packages, settings and assigns files
$packages = ReadPackages $packagesPath
$settings = ReadIniFile $settingsFile
$assigns = ReadIniFile $assignsFile


# set default installer mode, if not present
if (!$settings.Installer -or !$settings.Installer.Mode)
{
    $settings.Installer = @{}
    $settings.Installer.Mode = "Install"
}


# print title and settings 
Write-Host "-------------------" -foregroundcolor "Yellow"
Write-Host "HstWB Installer Run" -foregroundcolor "Yellow"
Write-Host "-------------------" -foregroundcolor "Yellow"
Write-Host ""
PrintSettings
Write-Host ""


# validate settings
if (!(ValidateSettings $settings))
{
    Fail "Validate settings failed"
}


# validate assigns
if (!(ValidateAssigns $assigns))
{
    Fail "Validate assigns failed"
}


# find workbench adf set hashes 
$workbenchAdfSetHashes = FindWorkbenchAdfSetHashes $settings $workbenchAdfHashesFile

# find workbench 3.1 workbench disk
$workbenchAdfHash = $workbenchAdfSetHashes | Where { $_.Name -eq 'Workbench 3.1 Workbench Disk' -and $_.File } | Select-Object -First 1

# fail, if workbench adf hash doesn't exist
if (!$workbenchAdfHash)
{
    Fail ("Workbench set '" + $settings.Workbench.WorkbenchAdfSet + "' doesn't have Workbench 3.1 Workbench Disk!")
}


# print workbench adf hash file
Write-Host ("Using Workbench 3.1 Workbench Disk: '" + $workbenchAdfHash.File + "'")


# find kickstart rom set hashes
$kickstartRomSetHashes = FindKickstartRomSetHashes $settings $kickstartRomHashesFile


# find kickstart 3.1 a1200 rom
$kickstartRomHash = $kickstartRomSetHashes | Where { $_.Name -eq 'Kickstart 3.1 (40.068) (A1200) Rom' -and $_.File } | Select-Object -First 1


# fail, if kickstart rom hash doesn't exist
if (!$kickstartRomHash)
{
    Fail ("Kickstart set '" + $settings.Kickstart.KickstartRomSet + "' doesn't have Kickstart 3.1 (40.068) (A1200) rom!")
}


# print kickstart rom hash file
Write-Host ("Using Kickstart 3.1 (40.068) (A1200) rom: '" + $kickstartRomHash.File + "'")


# kickstart rom key
$kickstartRomKeyFile = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($kickstartRomHash.File), "rom.key")

# fail, if kickstart rom hash is encrypted and kickstart rom key file doesn't exist
if ($kickstartRomHash.Encrypted -eq 'Yes' -and !(test-path -path $kickstartRomKeyFile))
{
    Fail ("Kickstart set '" + $settings.Kickstart.KickstartRomSet + "' doesn't have rom.key!")
}


# create temp path
if(!(test-path -path $tempPath))
{
	md $tempPath | Out-Null
}


# installer mode
switch ($settings.Installer.Mode)
{
    "Test" { RunTest }
    "Install" { RunInstall }
    "BuildSelfInstall" { RunBuildSelfInstall }
    "BuildSelfInstallPackageSelection" { RunBuildSelfInstall }
    "BuildPackageInstallation" { RunBuildPackageInstallation }
}


# remove temp path
Remove-Item -Recurse -Force $tempPath


# print done message 
Write-Host "Done."
Write-Host ""
Write-Host "Press enter to continue"
Read-Host
