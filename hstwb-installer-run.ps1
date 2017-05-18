# HstWB Installer Run
# -------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-05-18
#
# A powershell script to run HstWB Installer automating installation of workbench, kickstart roms and packages to an Amiga HDF file.


Param(
	[Parameter(Mandatory=$true)]
	[string]$settingsDir
)


Import-Module (Resolve-Path('modules\HstwbInstaller-Config.psm1')) -Force
Import-Module (Resolve-Path('modules\HstwbInstaller-Dialog.psm1')) -Force
Import-Module (Resolve-Path('modules\HstwbInstaller-Data.psm1')) -Force


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
    $globalAssigns = $assigns.Get_Item('Global')

    $userAssignScriptLines = @()

    foreach ($assignName in $globalAssigns.keys)
    {
        # skip, if assign name is 'HstWBInstallerDir' and installer mode is build package installation
        if ($assignName -match 'HstWBInstallerDir' -and $settings.Installer.Mode -eq "BuildPackageInstallation")
        {
            continue
        }

        # get assign path and drive
        $assignPath = $globalAssigns.Get_Item($assignName)
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


# build assign path script lines
function BuildAssignPathScriptLines($assignId, $assignPath)
{
    $assignPathScriptLines = @()
    $assignPathScriptLines += ("IF EXISTS ""T:{0}""" -f $assignId)
    $assignPathScriptLines += ("  Set assignpath ""``type ""T:{0}""``""" -f $assignId)
    $assignPathScriptLines += "ELSE"
    $assignPathScriptLines += ("  Set assignpath ""{0}""" -f $assignPath)
    $assignPathScriptLines += "ENDIF"

    return $assignPathScriptLines
}


# build add assign script lines
function BuildAddAssignScriptLines($assignId, $assignName, $assignPath)
{
    $addAssignScriptLines = @()
    $addAssignScriptLines += ("; Add assign and set variable for assign '{0}'" -f $assignName)
    $addAssignScriptLines += BuildAssignPathScriptLines $assignId $assignPath
    $addAssignScriptLines += "Assign >NIL: EXISTS ""`$assignpath"""
    $addAssignScriptLines += "IF WARN"
    $addAssignScriptLines += "  MakePath ""`$assignpath"""
    $addAssignScriptLines += "ENDIF"
    $addAssignScriptLines += ("SetEnv {0} ""`$assignpath""" -f $assignName)
    $addAssignScriptLines += ("Assign {0}: ""`$assignpath""" -f $assignName)

    return $addAssignScriptLines
}


# build remove assign script lines
function BuildRemoveAssignScriptLines($assignId, $assignName, $assignPath)
{
    $removeAssignScriptLines = @()
    $removeAssignScriptLines += ("; Remove assign and unset variable for assign '{0}'" -f $assignName)
    $removeAssignScriptLines += BuildAssignPathScriptLines $assignId $assignPath
    $removeAssignScriptLines += ("Assign {0}: ""`$assignpath"" REMOVE" -f $assignName)
    $removeAssignScriptLines += ("IF EXISTS ""ENV:{0}""" -f $assignName)
    $removeAssignScriptLines += ("  delete >NIL: ""ENV:{0}""" -f $assignName)
    $removeAssignScriptLines += "ENDIF"

    return $removeAssignScriptLines
}


# build install package script lines
function BuildInstallPackageScriptLines($packageNames)
{
    $globalAssigns = $assigns.Get_Item('Global')

    $installPackageScripts = @()
 
    foreach ($packageName in $packageNames)
    {
        # get package
        $package = $packages.Get_Item($packageName.ToLower())

        # package name
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
           $packageAssignNames += $package.Package.Assigns -split ',' | Where-Object { $_ }
        }

        # package assigns
        if ($assigns.ContainsKey($package.Package.Name))
        {
            $packageAssigns = $assigns.Get_Item($package.Package.Name)
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
                Fail ("Error: Package '" + $package.Package.Name + "' doesn't have assign defined for '$assignName' in either global or package assigns!")
            }

            # skip, if package assign name is global
            if ($matchingGlobalAssignName)
            {
                continue
            }

            # get assign path and drive
            $assignId = CalculateMd5FromText (("{0}.{1}" -f $package.Package.Name, $assignName).ToLower())
            $assignPath = $packageAssigns.Get_Item($matchingPackageAssignName)

            # append and and remove package assign
            $installPackageLines += ""
            $installPackageLines += BuildAddAssignScriptLines $assignId $assignName $assignPath
            $removePackageAssignLines += BuildRemoveAssignScriptLines $assignId $assignName $assignPath
        }


        # add package dir assign, execute package install script and remove package dir assign
        $installPackageLines += ""
        $installPackageLines += "; Add package dir assign"
        $installPackageLines += ("Assign PACKAGEDIR: ""PACKAGES:" + $packageName + """")
        $installPackageLines += ""
        $installPackageLines += "; Execute package install script"
        $installPackageLines += "execute ""PACKAGEDIR:Install"""
        $installPackageLines += ""
        $installPackageLines += "; Remove package dir assign"
        $installPackageLines += ("Assign PACKAGEDIR: ""PACKAGES:" + $packageName + """ REMOVE")


        # add remove package assign lines, if there are any
        if ($removePackageAssignLines.Count -gt 0)
        {
            $installPackageLines += ""
            $installPackageLines += $removePackageAssignLines
        }

        $installPackageScripts += @{ "Id" = [guid]::NewGuid().ToString().Replace('-',''); "Name" = $name; "Lines" = $installPackageLines; "PackageName" = $packageName }
    }

    return $installPackageScripts
}


# build install packages script lines
function BuildInstallPackagesScriptLines($installPackages)
{
    $installPackagesScriptLines = @()
    $installPackagesScriptLines += ""

    # append skip reset settings or install packages depending on installer mode
    if (($settings.Installer.Mode -eq "BuildSelfInstall" -or $settings.Installer.Mode -eq "BuildPackageInstallation") -and $installPackages.Count -gt 0)
    {
        $installPackagesScriptLines += "SKIP resetsettings"
    }
    else
    {
        $installPackagesScriptLines += "SKIP installpackages"
    }

    $installPackagesScriptLines += ""
    $installPackagesScriptLines += ""
    $installPackagesScriptLines += "; Select assign path function"
    $installPackagesScriptLines += "; ---------------------------"
    $installPackagesScriptLines += "LAB functionselectassignpath"
    $installPackagesScriptLines += ""
    $installPackagesScriptLines += "; Set assign path to SYS:, if not defined"
    $installPackagesScriptLines += "IF ""`$assignpath"" eq """""
    $installPackagesScriptLines += "  set assignpath ""SYS:"""
    $installPackagesScriptLines += "ENDIF"
    $installPackagesScriptLines += ""
    $installPackagesScriptLines += "; Set assign path to SYS:, if path doesn't exist"
    $installPackagesScriptLines += "Assign >NIL: EXISTS ""`$assignpath"""
    $installPackagesScriptLines += "IF WARN"
    $installPackagesScriptLines += "  set assignpath ""SYS:"""
    $installPackagesScriptLines += "ENDIF"
    $installPackagesScriptLines += ""
    $installPackagesScriptLines += "; Show select path for assign dialog"
    $installPackagesScriptLines += "set newassignpath """""
    $installPackagesScriptLines += "set newassignpath ``REQUESTFILE DRAWER ""`$assignpath"" TITLE ""Select '`$assignname' assign"" NOICONS DRAWERSONLY``"
    $installPackagesScriptLines += ""
    $installPackagesScriptLines += "; Return, if select path for assign dialog is cancelled"
    $installPackagesScriptLines += "IF ""`$newassignpath"" eq """""
    $installPackagesScriptLines += "  SKIP `$returnlab"
    $installPackagesScriptLines += "ENDIF"
    $installPackagesScriptLines += ""
    $installPackagesScriptLines += "; Write new assign for assign id"
    $installPackagesScriptLines += "echo ""`$newassignpath"" >""T:`$assignid"""
    $installPackagesScriptLines += ""
    $installPackagesScriptLines += "; Strip tailing slash from assign path"
    $installPackagesScriptLines += "sed ""s/\/$//"" ""T:`$assignid"" >""T:_assignpath"""
    $installPackagesScriptLines += "copy >NIL: ""T:_assignpath"" ""T:`$assignid"""
    $installPackagesScriptLines += "delete >NIL: ""T:_assignpath"""
    $installPackagesScriptLines += ""
    $installPackagesScriptLines += "SKIP `$returnlab"
    $installPackagesScriptLines += ""


    # globl assigns
    $globalAssigns = $assigns.Get_Item('Global')


    # build global package assigns
    $addGlobalAssignScriptLines = @()
    $removeGlobalAssignScriptLines = @()
    foreach ($assignName in ($globalAssigns.keys | Sort-Object | Where-Object { $_ -notlike 'HstWBInstallerDir' }))
    {
        $assignId = CalculateMd5FromText (("{0}.{1}" -f 'Global', $assignName).ToLower())
        $assignPath = $globalAssigns.Get_Item($assignName)

        $addGlobalAssignScriptLines += BuildAddAssignScriptLines $assignId $assignName.ToUpper() $assignPath
        $removeGlobalAssignScriptLines += BuildRemoveAssignScriptLines $assignId $assignName.ToUpper() $assignPath
    }


    # build install package script lines
    $installPackageScripts = @()
    $installPackageScripts += BuildInstallPackageScriptLines ($installPackages | ForEach-Object { $_.Package })

    if (($settings.Installer.Mode -eq "BuildSelfInstall" -or $settings.Installer.Mode -eq "BuildPackageInstallation") -and $installPackages.Count -gt 0)
    {
        # get install package name padding
        $installPackageNamesPadding = ($installPackages | ForEach-Object { $_.FullName } | Sort-Object @{expression={$_.Length};Ascending=$false} | Select-Object -First 1).Length

        # reset settings
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "; Reset settings"
        $installPackagesScriptLines += "; --------------"
        $installPackagesScriptLines += "LAB resetsettings"
        $installPackagesScriptLines += ""

        # reset package settings
        foreach ($installPackageScript in $installPackageScripts)
        {
            $installPackagesScriptLines += ("IF EXISTS ""T:{0}""" -f $installPackageScript.Id)
            $installPackagesScriptLines += ("  delete >NIL: ""T:{0}""" -f $installPackageScript.Id)
            $installPackagesScriptLines += "ENDIF"
        }

        # reset assigns settings
        foreach ($assignSectionName in $assigns.keys)
        {
            $sectionAssigns = $assigns[$assignSectionName]

            foreach ($assignName in ($sectionAssigns.keys | Sort-Object))
            {
                $assignId = CalculateMd5FromText (("{0}.{1}" -f $assignSectionName, $assignName).ToLower())

                $installPackagesScriptLines += ("IF EXISTS ""T:{0}""" -f $assignId)
                $installPackagesScriptLines += ("  delete >NIL: ""T:{0}""" -f $assignId)
                $installPackagesScriptLines += "ENDIF"
            }
        }

        # install packages label
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "; Install packages menu"
        $installPackagesScriptLines += "; ---------------------"
        $installPackagesScriptLines += "LAB installpackagesmenu"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "echo """" NOLINE >T:installpackagesmenu"

        # add package options to menu
        foreach ($installPackageScript in $installPackageScripts)
        {
            $installPackagesScriptLines += (("echo ""{0,-" + $installPackageNamesPadding + "} : "" NOLINE >>T:installpackagesmenu") -f $installPackageScript.Name)
            $installPackagesScriptLines += ("IF EXISTS ""T:{0}""" -f $installPackageScript.Id)
            $installPackagesScriptLines += "  echo ""YES"" >>T:installpackagesmenu"
            $installPackagesScriptLines += "ELSE"
            $installPackagesScriptLines += "  echo ""NO "" >>T:installpackagesmenu"
            $installPackagesScriptLines += "ENDIF"
        }

        # add install package option and show install packages menu
        $installPackagesScriptLines += "echo """ + (new-object System.String('=', ($installPackageNamesPadding + 6))) + """ >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""View Readme"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Edit assigns"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Install packages"" >>T:installpackagesmenu"

        if ($settings.Installer.Mode -eq "BuildPackageInstallation")
        {
            $installPackagesScriptLines += "echo ""Quit"" >>T:installpackagesmenu"
        }

        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "set installpackagesmenu ````"
        $installPackagesScriptLines += "set installpackagesmenu ``ReqList CLONERT I=T:installpackagesmenu H=""Select packages to install"" PAGE=18``"
        $installPackagesScriptLines += "delete >NIL: T:installpackagesmenu"

        # switch package options
        for($i = 0; $i -lt $installPackageScripts.Count; $i++)
        {
            $installPackageScript = $installPackageScripts[$i]

            $installPackagesScriptLines += ""
            $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($i + 1) + """")
            $installPackagesScriptLines += ("  IF EXISTS ""T:{0}""" -f $installPackageScript.Id)
            $installPackagesScriptLines += ("    delete >NIL: ""T:{0}""" -f $installPackageScript.Id)
            $installPackagesScriptLines += "  ELSE"
            $installPackagesScriptLines += ("    echo """" NOLINE >""T:{0}""" -f $installPackageScript.Id)
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
        $installPackagesScriptLines += "  set confirm ``RequestChoice ""Confirm"" ""Install selected packages?"" ""Yes|No""``"
        $installPackagesScriptLines += "  IF ""`$confirm"" EQ ""1"""
        $installPackagesScriptLines += "    SKIP installpackages"
        $installPackagesScriptLines += "  ENDIF"
        $installPackagesScriptLines += "ENDIF"

        if ($settings.Installer.Mode -eq "BuildPackageInstallation")
        {
            $installPackagesScriptLines += ""
            $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($installPackageScripts.Count + 5) + """")
            $installPackagesScriptLines += "  quit"
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
            $installPackagesScriptLines += (("echo ""{0,-" + $installPackageNamesPadding + "}"" >>T:viewreadmemenu") -f $installPackageScript.Name)
        }

        # add back option to view readme menu
        $installPackagesScriptLines += "echo """ + (new-object System.String('=', $installPackageNamesPadding)) + """ >>T:viewreadmemenu"
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
            $installPackagesScriptLines += ("  IF EXISTS ""PACKAGES:{0}/README.guide""" -f $installPackageScript.PackageName)
            $installPackagesScriptLines += ("    cd ""PACKAGES:{0}""" -f $installPackageScript.PackageName)
            $installPackagesScriptLines += "    multiview README.guide"
            $installPackagesScriptLines += "    cd ""PACKAGES:"""
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
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "; Edit assigns menu"
        $installPackagesScriptLines += ";------------------"
        $installPackagesScriptLines += "LAB editassignsmenu"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "echo """" NOLINE >T:editassignsmenu"

        $assignSectionNames = @('Global')
        $assignSectionNames += $assigns.keys | Where-Object { $_ -notlike 'Global' } | Sort-Object


        $editAssignsMenuOption = 0
        $editAssignsMenuOptionScriptLines = @()

        foreach($assignSectionName in $assignSectionNames)
        {
            # add menu option to show assign section name
            #$installPackagesScriptLines += ("echo ""{0}"" >>T:editassignsmenu" -f (new-object System.String('-', $assignSectionName.Length)))
            $installPackagesScriptLines += ("echo ""| {0} |"" >>T:editassignsmenu" -f $assignSectionName)
            #$installPackagesScriptLines += ("echo ""{0}"" >>T:editassignsmenu" -f (new-object System.String('-', $assignSectionName.Length)))

            # increase menu option
            $editAssignsMenuOption += 1

            # get section assigns
            $sectionAssigns = $assigns[$assignSectionName]

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
                $assignPath = $sectionAssigns[$assignName]

                # add menu option showing and editing assign witnin section
                $installPackagesScriptLines += ""
                $installPackagesScriptLines += ("IF EXISTS ""T:{0}""" -f $assignId)
                $installPackagesScriptLines += ("  echo ""{0}: = '``type ""T:{1}""``'"" >>T:editassignsmenu" -f $assignName, $assignId)
                $installPackagesScriptLines += "ELSE"
                $installPackagesScriptLines += ("  Assign >NIL: EXISTS ""{0}""" -f $assignPath)
                $installPackagesScriptLines += "  IF WARN"
                $installPackagesScriptLines += ("    echo ""{0}: = ?"" >>T:editassignsmenu" -f $assignName)
                $installPackagesScriptLines += "  ELSE"
                $installPackagesScriptLines += ("    echo ""{0}: = '{1}'"" >>T:editassignsmenu" -f $assignName, $assignPath)
                $installPackagesScriptLines += "  ENDIF"
                $installPackagesScriptLines += "ENDIF"

                $editAssignsMenuOptionScriptLines += ""
                $editAssignsMenuOptionScriptLines += ("IF ""`$editassignsmenu"" eq """ + $editAssignsMenuOption + """")
                $editAssignsMenuOptionScriptLines += ("  set assignid ""{0}""" -f $assignId)
                $editAssignsMenuOptionScriptLines += ("  set assignname ""{0}""" -f $assignName)
                $editAssignsMenuOptionScriptLines += ("  IF EXISTS ""T:{0}""" -f $assignId)
                $editAssignsMenuOptionScriptLines += ("    set assignpath ""``type ""T:{0}""``""" -f $assignId)
                $editAssignsMenuOptionScriptLines += "  ELSE"
                $editAssignsMenuOptionScriptLines += ("    set assignpath ""{0}""" -f $assignPath)
                $editAssignsMenuOptionScriptLines += "  ENDIF"
                $editAssignsMenuOptionScriptLines += "  set returnlab ""editassignsmenu"""
                $editAssignsMenuOptionScriptLines += "  SKIP BACK functionselectassignpath"
                $editAssignsMenuOptionScriptLines += "ENDIF"
            }
        }

        # add back option to view readme menu
        $installPackagesScriptLines += "echo ""========================================"" >>T:editassignsmenu"
        $installPackagesScriptLines += "echo ""Back"" >>T:editassignsmenu"

        $installPackagesScriptLines += "set editassignsmenu ````"
        $installPackagesScriptLines += "set editassignsmenu ``ReqList CLONERT I=T:editassignsmenu H=""Edit assigns"" PAGE=18``"
        $installPackagesScriptLines += "delete >NIL: T:editassignsmenu"

        # add edit assigns menu options script lines
        $editAssignsMenuOptionScriptLines | ForEach-Object { $installPackagesScriptLines += $_ }

        # add back option to edit assigns menu
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ("IF ""`$editassignsmenu"" eq """ + ($editAssignsMenuOption + 2) + """")
        $installPackagesScriptLines += "  SKIP BACK installpackagesmenu"
        $installPackagesScriptLines += "ENDIF"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "SKIP BACK editassignsmenu"


        # install packages
        # ----------------
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "; Install packages"
        $installPackagesScriptLines += "; ----------------"
        $installPackagesScriptLines += "LAB installpackages"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "echo ""*ec"""
        $installPackagesScriptLines += "echo ""Package Installation"""
        $installPackagesScriptLines += "echo ""--------------------"""

        # get assign section names
        $assignSectionNames = @('Global')
        $assignSectionNames += $assigns.keys | Where-Object { $_ -notlike 'Global' } | Sort-Object

        # build validate assigns
        foreach($assignSectionName in $assignSectionNames)
        {
            # get section assigns
            $sectionAssigns = $assigns[$assignSectionName]

            foreach ($assignName in ($sectionAssigns.keys | Sort-Object))
            {
                # skip hstwb installer assign name for global assigns
                if ($assignSectionName -like 'Global' -and $assignName -like 'HstWBInstallerDir')
                {
                    continue
                }

                $assignId = CalculateMd5FromText (("{0}.{1}" -f $assignSectionName, $assignName).ToLower())
                $assignPath = $sectionAssigns[$assignName]

                $installPackagesScriptLines += ""
                $installPackagesScriptLines += ("; Validate assign '{0}'" -f $assignName)
                $installPackagesScriptLines += BuildAssignPathScriptLines $assignId $assignPath
                $installPackagesScriptLines += "IF ""`$assignpath"" eq """""
                $installPackagesScriptLines += ("  REQUESTCHOICE ""Error"" ""No path is defined*Nfor assign '{0}'*Nin section '{1}'!"" ""OK"" >NIL:" -f $assignName, $assignSectionName)
                $installPackagesScriptLines += "  SKIP BACK installpackagesmenu"
                $installPackagesScriptLines += "ENDIF"
                $installPackagesScriptLines += "IF NOT EXISTS ""`$assignpath"""
                $installPackagesScriptLines += ("  REQUESTCHOICE ""Error"" ""Path '`$assignpath' doesn't exist*Nfor assign '{0}'*Nin section '{1}'!"" ""OK"" >NIL:" -f $assignName, $assignSectionName)
                $installPackagesScriptLines += "  SKIP BACK installpackagesmenu"
                $installPackagesScriptLines += "ENDIF"
            }
        }

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
            $installPackagesScriptLines += ("; Install package '{0}', if it's selected" -f $installPackageScript.Name)
            $installPackagesScriptLines += ("IF EXISTS T:" + $installPackageScript.Id)
            $installPackageScript.Lines | ForEach-Object { $installPackagesScriptLines += ("  " + $_) }
            $installPackagesScriptLines += "ENDIF"
        }

        # append remove global assign script lines
        if ($removeGlobalAssignScriptLines.Count -gt 0)
        {
            $installPackagesScriptLines += ""
            $installPackagesScriptLines += $removeGlobalAssignScriptLines
        }
    }
    else 
    {
        # install packages
        # ----------------
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "; Install packages"
        $installPackagesScriptLines += "; ----------------"
        $installPackagesScriptLines += "LAB installpackages"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "echo ""*ec"""
        $installPackagesScriptLines += "echo ""Package Installation"""
        $installPackagesScriptLines += "echo ""--------------------"""


        # append add global assign script lines
        if ($addGlobalAssignScriptLines.Count -gt 0)
        {
            $installPackagesScriptLines += ""
            $installPackagesScriptLines += $addGlobalAssignScriptLines
        }

        # add install package script for each package
        foreach ($installPackageScript in $installPackageScripts)
        {
            $installPackageScript.Lines | ForEach-Object { $installPackagesScriptLines += $_ }
        }

        # append remove global assign script lines
        if ($removeGlobalAssignScriptLines.Count -gt 0)
        {
            $installPackagesScriptLines += ""
            $installPackagesScriptLines += $removeGlobalAssignScriptLines
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


    # copy amiga install dir
    $amigaInstallDir = [System.IO.Path]::Combine($amigaPath, "install")
    Copy-Item -Path $amigaInstallDir $tempPath -recurse -force


    # set temp install and packages dir
    $tempInstallDir = [System.IO.Path]::Combine($tempPath, "install")
    $tempPackagesDir = [System.IO.Path]::Combine($tempPath, "packages")


    # copy amiga shared dir
    $amigaSharedDir = [System.IO.Path]::Combine($amigaPath, "shared")
    Copy-Item -Path "$amigaSharedDir\*" $tempInstallDir -recurse -force


    # create temp packages path
    if(!(test-path -path $tempPackagesDir))
    {
        mkdir $tempPackagesDir | Out-Null
    }


    # copy amiga packages dir
    $amigaPackagesDir = [System.IO.Path]::Combine($amigaPath, "packages")
    Copy-Item -Path "$amigaPackagesDir\*" $tempPackagesDir -recurse -force


    # prepare install workbench
    if ($settings.Workbench.InstallWorkbench -eq 'Yes')
    {
        # copy workbench adf set files to temp install dir
        Write-Host "Copying Workbench adf files to temp install dir"
        $workbenchAdfSetHashes | Where-Object { $_.File } | ForEach-Object { Copy-Item -Path $_.File -Destination ([System.IO.Path]::Combine($tempInstallDir, $_.Filename)) }
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
        $kickstartRomSetHashes | Where-Object { $_.File } | ForEach-Object { Copy-Item -Path $_.File -Destination ([System.IO.Path]::Combine($tempInstallDir, $_.Filename)) }

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
        $installPackagesScriptLines = @()
        $installPackagesScriptLines += "; Install Packages Script"
        $installPackagesScriptLines += "; -----------------------"
        $installPackagesScriptLines += "; Author: Henrik Noerfjand Stengaard"
        $installPackagesScriptLines += ("; Date: {0}" -f (Get-Date -format "yyyy.MM.dd"))
        $installPackagesScriptLines += ";"
        $installPackagesScriptLines += "; An install packages script generated by HstWB Installer to install configured packages."
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "; Clear screen"
        $installPackagesScriptLines += "echo ""*ec"""
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += BuildInstallPackagesScriptLines $installPackages
        $installPackagesScriptLines += "echo """""
        $installPackagesScriptLines += "echo ""Package installation is complete."""
        $installPackagesScriptLines += "echo """""
        $installPackagesScriptLines += "ask ""Press ENTER to continue"""

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
        mkdir $tempInstallDir | Out-Null
    }


    # create temp packages path
    $tempPackagesDir = [System.IO.Path]::Combine($tempPath, "packages")
    if(!(test-path -path $tempPackagesDir))
    {
        mkdir $tempPackagesDir | Out-Null
    }


    # copy amiga self install build dir
    $amigaSelfInstallBuildDir = [System.IO.Path]::Combine($amigaPath, "selfinstall")
    Copy-Item -Path "$amigaSelfInstallBuildDir\*" $tempInstallDir -recurse -force


    # copy amiga shared dir
    $amigaSharedDir = [System.IO.Path]::Combine($amigaPath, "shared")
    Copy-Item -Path "$amigaSharedDir\*" $tempInstallDir -recurse -force
    Copy-Item -Path "$amigaSharedDir\*" "$tempInstallDir\System" -recurse -force


    # copy amiga packages dir
    $amigaPackagesDir = [System.IO.Path]::Combine($amigaPath, "packages")
    Copy-Item -Path "$amigaPackagesDir\*" $tempPackagesDir -recurse -force


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
    $installPackagesScriptLines += "; Install Packages Script"
    $installPackagesScriptLines += "; -----------------------"
    $installPackagesScriptLines += "; Author: Henrik Noerfjand Stengaard"
    $installPackagesScriptLines += ("; Date: {0}" -f (Get-Date -format "yyyy.MM.dd"))
    $installPackagesScriptLines += ";"
    $installPackagesScriptLines += "; An install packages script generated by HstWB Installer to install configured packages."
    $installPackagesScriptLines += BuildInstallPackagesScriptLines $installPackages
    $installPackagesScriptLines += "echo """""
    $installPackagesScriptLines += "echo ""Package installation is complete."""
    $installPackagesScriptLines += "echo """""
    $installPackagesScriptLines += "ask ""Press ENTER to continue"""


    # write install packages script
    $installPackagesScriptFile = [System.IO.Path]::Combine($tempInstallDir, "HstWBInstaller\Install-Packages")
    WriteAmigaTextLines $installPackagesScriptFile $installPackagesScriptLines 


    $globalAssigns = $assigns.Get_Item('Global')

    if (!$globalAssigns)
    {
        Fail ("Failed to run install. Global assigns doesn't exist!")
    }


    $hstwbInstallDirAssignName = $globalAssigns.keys | Where-Object { $_ -match 'HstWBInstallerDir' } | Select-Object -First 1

    if (!$hstwbInstallDirAssignName)
    {
        Fail ("Failed to run install. Global assigns doesn't containassign for 'HstWBInstallerDir' exist!")
    }

    $hstwbInstallDir = $globalAssigns.Get_Item($hstwbInstallDirAssignName)

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

    # show confirm overwrite dialog, if package installation directory is not empty
    if ((Get-ChildItem -Path $outputPackageInstallationPath -Recurse).Count -gt 0)
    {
        if (!(ConfirmDialog "Overwrite files" ("Package installation directory '" + $outputPackageInstallationPath + "' is not empty.`r`n`r`nDo you want to overwrite files?")))
        {
            Write-Host ""
            Write-Host "Cancelled, package installation directory is not empty!" -ForegroundColor Yellow
            return
        }
    }

    # delete package installation directory, if it exists
    if (Test-Path $outputPackageInstallationPath)
    {
        Remove-Item -Path $outputPackageInstallationPath -Recurse -Force
    }

    # create package installation directory
    mkdir $outputPackageInstallationPath | Out-Null

    # print building package installation message
    Write-Host ""
    Write-Host "Building package installation to '$outputPackageInstallationPath'..."    


    # find packages to install
    $installPackages = FindPackagesToInstall | Sort-Object -Property 'Name'


    # extract packages and write install packages script, if there's packages to install
    if ($installPackages.Count -gt 0)
    {
        foreach($installPackage in $installPackages)
        {
            # extract package file to package directory
            Write-Host ("Extracting '" + $installPackage.Package + "' package to package installation")
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
    $packageInstallationScriptLines += "; Package Installation Script"
    $packageInstallationScriptLines += "; ---------------------------"
    $packageInstallationScriptLines += "; Author: Henrik Noerfjand Stengaard"
    $packageInstallationScriptLines += ("; Date: {0}" -f (Get-Date -format "yyyy.MM.dd"))
    $packageInstallationScriptLines += ";"
    $packageInstallationScriptLines += "; An package installation script generated by HstWB Installer to install selected packages."
    $packageInstallationScriptLines += ""
    $packageInstallationScriptLines += "; Add assign and set environment variables for package installation"
    $packageInstallationScriptLines += "SetEnv Packages ""``CD``"""
    $packageInstallationScriptLines += "Assign PACKAGES: ""`$Packages"""
    $packageInstallationScriptLines += "SetEnv TZ MST7"
    $packageInstallationScriptLines += ""
    $packageInstallationScriptLines += "; Copy reqtools prefs to env, if it doesn't exist"
    $packageInstallationScriptLines += "IF NOT EXISTS ""ENV:ReqTools.prefs"""
    $packageInstallationScriptLines += "  copy >NIL: ""ReqTools.prefs"" ""ENV:"""
    $packageInstallationScriptLines += "ENDIF"
    $packageInstallationScriptLines += ""
    $packageInstallationScriptLines += BuildInstallPackagesScriptLines $installPackages
    $packageInstallationScriptLines += ""
    $packageInstallationScriptLines += "; Remove assign for package installation"
    $packageInstallationScriptLines += "Assign PACKAGES: ""`$Packages"" REMOVE"
    $packageInstallationScriptLines += ""
    $packageInstallationScriptLines += "echo """""
    $packageInstallationScriptLines += "echo ""Package installation is complete."""
    $packageInstallationScriptLines += "echo """""
    $packageInstallationScriptLines += "ask ""Press ENTER to continue"""


    # write install packages script
    $installPackagesScriptFile = [System.IO.Path]::Combine($outputPackageInstallationPath, "Package Installation")
    WriteAmigaTextLines $installPackagesScriptFile $packageInstallationScriptLines 


    # copy amiga package installation files
    $amigaPackageInstallationDir = [System.IO.Path]::Combine($amigaPath, "packageinstallation")
    Copy-Item -Path "$amigaPackageInstallationDir\*" $outputPackageInstallationPath -recurse -force


    # copy amiga packages dir
    $amigaPackagesDir = [System.IO.Path]::Combine($amigaPath, "packages")
    Copy-Item -Path "$amigaPackagesDir\*" $outputPackageInstallationPath -recurse -force
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
$hstwbInstallerVersion = HstwbInstallerVersion
$kickstartRomHashesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("Kickstart\kickstart-rom-hashes.csv")
$workbenchAdfHashesFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("Workbench\workbench-adf-hashes.csv")
$packagesPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("packages")
$winuaePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("winuae")
$amigaPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("amiga")
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
$versionPadding = new-object System.String('-', ($hstwbInstallerVersion.Length + 2))
Write-Host ("-------------------{0}" -f $versionPadding) -foregroundcolor "Yellow"
Write-Host ("HstWB Installer Run v{0}" -f $hstwbInstallerVersion) -foregroundcolor "Yellow"
Write-Host ("-------------------{0}" -f $versionPadding) -foregroundcolor "Yellow"
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
$workbenchAdfHash = $workbenchAdfSetHashes | Where-Object { $_.Name -eq 'Workbench 3.1 Workbench Disk' -and $_.File } | Select-Object -First 1

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
$kickstartRomHash = $kickstartRomSetHashes | Where-Object { $_.Name -eq 'Kickstart 3.1 (40.068) (A1200) Rom' -and $_.File } | Select-Object -First 1


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
	mkdir $tempPath | Out-Null
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
