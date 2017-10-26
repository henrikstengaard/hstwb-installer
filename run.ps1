# HstWB Installer Run
# -------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-10-13
#
# A powershell script to run HstWB Installer automating installation of workbench, kickstart roms and packages to an Amiga HDF file.


Param(
	[Parameter(Mandatory=$true)]
	[string]$settingsDir
)


Import-Module (Resolve-Path('modules\version.psm1')) -Force
Import-Module (Resolve-Path('modules\config.psm1')) -Force
Import-Module (Resolve-Path('modules\dialog.psm1')) -Force
Import-Module (Resolve-Path('modules\data.psm1')) -Force


Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Windows.Forms


# # http://stackoverflow.com/questions/8982782/does-anyone-have-a-dependency-graph-and-topological-sorting-code-snippet-for-pow
# function Get-TopologicalSort {
#   param(
#       [Parameter(Mandatory = $true, Position = 0)]
#       [hashtable] $edgeList
#   )

#   # Make sure we can use HashSet
#   Add-Type -AssemblyName System.Core

#   # Clone it so as to not alter original
#   $currentEdgeList = [hashtable] (Get-ClonedObject $edgeList)

#   # algorithm from http://en.wikipedia.org/wiki/Topological_sorting#Algorithms
#   $topologicallySortedElements = New-Object System.Collections.ArrayList
#   $setOfAllNodesWithNoIncomingEdges = New-Object System.Collections.Queue

#   $fasterEdgeList = @{}

#   # Keep track of all nodes in case they put it in as an edge destination but not source
#   $allNodes = New-Object -TypeName System.Collections.Generic.HashSet[object] -ArgumentList (,[object[]] $currentEdgeList.Keys)

#   foreach($currentNode in $currentEdgeList.Keys) {
#       $currentDestinationNodes = [array] $currentEdgeList[$currentNode]
#       if($currentDestinationNodes.Length -eq 0) {
#           $setOfAllNodesWithNoIncomingEdges.Enqueue($currentNode)
#       }

#       foreach($currentDestinationNode in $currentDestinationNodes) {
#           if(!$allNodes.Contains($currentDestinationNode)) {
#               [void] $allNodes.Add($currentDestinationNode)
#           }
#       }

#       # Take this time to convert them to a HashSet for faster operation
#       $currentDestinationNodes = New-Object -TypeName System.Collections.Generic.HashSet[object] -ArgumentList (,[object[]] $currentDestinationNodes )
#       [void] $fasterEdgeList.Add($currentNode, $currentDestinationNodes)        
#   }

#   # Now let's reconcile by adding empty dependencies for source nodes they didn't tell us about
#   foreach($currentNode in $allNodes) {
#       if(!$currentEdgeList.ContainsKey($currentNode)) {
#           [void] $currentEdgeList.Add($currentNode, (New-Object -TypeName System.Collections.Generic.HashSet[object]))
#           $setOfAllNodesWithNoIncomingEdges.Enqueue($currentNode)
#       }
#   }

#   $currentEdgeList = $fasterEdgeList

#   while($setOfAllNodesWithNoIncomingEdges.Count -gt 0) {        
#       $currentNode = $setOfAllNodesWithNoIncomingEdges.Dequeue()
#       [void] $currentEdgeList.Remove($currentNode)
#       [void] $topologicallySortedElements.Add($currentNode)

#       foreach($currentEdgeSourceNode in $currentEdgeList.Keys) {
#           $currentNodeDestinations = $currentEdgeList[$currentEdgeSourceNode]
#           if($currentNodeDestinations.Contains($currentNode)) {
#               [void] $currentNodeDestinations.Remove($currentNode)

#               if($currentNodeDestinations.Count -eq 0) {
#                   [void] $setOfAllNodesWithNoIncomingEdges.Enqueue($currentEdgeSourceNode)
#               }                
#           }
#       }
#   }

#   if($currentEdgeList.Count -gt 0) {
#       throw "Graph has at least one cycle!"
#   }

#   return $topologicallySortedElements
# }


# # Idea from http://stackoverflow.com/questions/7468707/deep-copy-a-dictionary-hashtable-in-powershell 
# function Get-ClonedObject {
#     param($DeepCopyObject)
#     $memStream = new-object IO.MemoryStream
#     $formatter = new-object Runtime.Serialization.Formatters.Binary.BinaryFormatter
#     $formatter.Serialize($memStream,$DeepCopyObject)
#     $memStream.Position=0
#     $formatter.Deserialize($memStream)
# }


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
function FindPackagesToInstall($hstwb)
{
    $pakageNames = SortPackageNames $hstwb

    # get install packages
    $installPackageNames = @{}
    foreach($installPackageKey in ($hstwb.Settings.Packages.Keys | Where-Object { $_ -match 'InstallPackage\d+' }))
    {
        $installPackageNames.Set_Item($hstwb.Settings.Packages.Get_Item($installPackageKey.ToLower()), $true)
    }

    # build package nodes for sorting topologically
    $packageIndex = 0
    $packageNodes = @()
    foreach ($pakageName in ($pakageNames | Where-Object { $installPackageNames.ContainsKey( $_ ) }))
    {
        $package = $hstwb.Packages.Get_Item($pakageName).Latest
        $priority = if ($package.Package.Priority) { [Int32]$package.Package.Priority } else { 9999 }
        $packageIndex++
        $packageNodes += @{ 'Name'= $package.Package.Name; 'Index' = $packageIndex; 'Dependencies' = $package.PackageDependencies; 'Priority' = $priority }
    }

    # sort packages, if any are present
    $installPackages = @()
    if ($installPackageNames.Count -gt 0)
    {
        # sort packages by priority and name
        $packagesSorted = @()
        $packagesSorted += ,$packageNodes | Sort-Object @{expression={$_.Priority};Ascending=$true}, @{expression={$_.Index};Ascending=$true}

        # add topologically sorted packages to install packages
        TopologicalSort $packagesSorted | ForEach-Object { $installPackages += $_ }
    }

    return $installPackages
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
    $addAssignScriptLines += ("echo ""Add assign '`$assigndir' = '{0}'"" >>SYS:HstWB-Installer.log" -f $assignName)
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
    $removeAssignScriptLines += ("echo ""Remove assign '`$assigndir' = '{0}'"" >>SYS:HstWB-Installer.log" -f $assignName)
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
        $package = $hstwb.Packages.Get_Item($packageName.ToLower()).Latest

        # add package installation lines to install packages script
        $installPackageLines = @()
        $installPackageLines += ("; Install package '{0}'" -f $package.PackageFullName)
        $installPackageLines += "echo """""
        $installPackageLines += ("echo ""*e[1mInstalling package '{0}'*e[0m""" -f $package.PackageFullName)

        $removePackageAssignLines = @()

        # get package assign names
        $packageAssignNames = @()
        if ($package.Package.Assigns)
        {
           $packageAssignNames += $package.Package.Assigns -split ',' | Where-Object { $_ }
        }

        # package assigns
        if ($hstwb.Assigns.ContainsKey($package.Package.Name))
        {
            $packageAssigns = $hstwb.Assigns.Get_Item($package.Package.Name)
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
                Fail $hstwb ("Error: Package '" + $package.Package.Name + "' doesn't have assign defined for '$assignName' in either global or package assigns!")
            }

            # skip, if package assign name is global
            if ($matchingGlobalAssignName)
            {
                continue
            }

            # get assign path and drive
            $assignId = CalculateMd5FromText (("{0}.{1}" -f $package.Package.Name, $assignName).ToLower())
            $assignDir = $packageAssigns.Get_Item($matchingPackageAssignName)

            # append add package assign
            $installPackageLines += ""
            $installPackageLines += BuildAddAssignScriptLines $assignId $assignName $assignDir

            # append ini file set for package assignm, if installer mode is build self install or build package installation
            if ($hstwb.Settings.Installer.Mode -eq "BuildSelfInstall" -or $hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation")
            {
                $installPackageLines += 'execute PACKAGESDIR:IniFileSet "{0}/{1}" "{2}" "{3}" "$assigndir"' -f $hstwb.Paths.EnvArcDir, 'HstWB-Installer.Assigns.ini', $package.Package.Name, $assignName
            }

            # append remove package assign
            $removePackageAssignLines += BuildRemoveAssignScriptLines $assignId $assignName $assignDir
        }


        # add package dir assign, execute package install script and remove package dir assign
        $installPackageLines += ""
        $installPackageLines += "; Add package dir assign"
        $installPackageLines += ("Assign PACKAGEDIR: ""PACKAGESDIR:{0}""" -f $package.PackageDirName)
        $installPackageLines += ""
        $installPackageLines += "; Execute package install script"
        $installPackageLines += ("echo ""Running package '{0}' install script"" >>SYS:HstWB-Installer.log" -f $package.PackageDirName)
        $installPackageLines += "execute ""PACKAGEDIR:Install"""
        $installPackageLines += ""
        $installPackageLines += "; Remove package dir assign"
        $installPackageLines += ("Assign PACKAGEDIR: ""PACKAGESDIR:{0}"" REMOVE" -f $package.PackageDirName)


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
            $resetAssignsScriptLines += 'set assigndir "`execute PACKAGESDIR:IniFileGet "{0}/{1}" "{2}" "{3}"`"' -f $hstwb.Paths.EnvArcDir, 'HstWB-Installer.Assigns.ini', $assignSectionName, $assignName
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

    # append skip reset settings or install packages depending on installer mode
    if (($hstwb.Settings.Installer.Mode -eq "BuildSelfInstall" -or $hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation") -and $installPackages.Count -gt 0)
    {
        $installPackagesScriptLines += "SKIP resetpackages"
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += ""
        $installPackagesScriptLines += Get-Content (Join-Path $hstwb.Paths.AmigaPath -ChildPath "packages\SelectAssignDir")
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
            $addGlobalAssignScriptLines += 'execute PACKAGESDIR:IniFileSet "{0}/{1}" "{2}" "{3}" "$assigndir"' -f $hstwb.Paths.EnvArcDir, 'HstWB-Installer.Assigns.ini', 'Global', $assignName
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
            $package = $hstwb.Packages.Get_Item($packageName).Latest
    
            foreach($dependencyPackageName in $package.PackageDependencies)
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
            $resetPackagesScriptLines += ("; Reset package '{0}'" -f $installPackageScript.Package.PackageFullName)
            $resetPackagesScriptLines += ("IF EXISTS ""T:{0}""" -f $installPackageScript.Package.PackageId)
            $resetPackagesScriptLines += ("  delete >NIL: ""T:{0}""" -f $installPackageScript.Package.PackageId)
            $resetPackagesScriptLines += "ENDIF"

            $selectAllPackagesScriptLines += ''
            $selectAllPackagesScriptLines += ("; Select package '{0}'" -f $installPackageScript.Package.PackageFullName)
            $selectAllPackagesScriptLines += ("IF NOT EXISTS ""T:{0}""" -f $installPackageScript.Package.PackageId)
            $selectAllPackagesScriptLines += ("  echo """" NOLINE >""T:{0}""" -f $installPackageScript.Package.PackageId)
            $selectAllPackagesScriptLines += "ENDIF"

            $deselectAllPackagesScriptLines += ''
            $deselectAllPackagesScriptLines += ("; Deselect package '{0}'" -f $installPackageScript.Package.PackageFullName)
            $deselectAllPackagesScriptLines += ("IF EXISTS ""T:{0}""" -f $installPackageScript.Package.PackageId)
            $deselectAllPackagesScriptLines += ("  delete >NIL: ""T:{0}""" -f $installPackageScript.Package.PackageId)
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
            $hasDependenciesIndicator = if ($installPackageScript.Package.PackageDependencies.Count -gt 0) { ' (**)' } else { '' }
            $installPackagesScriptLines += ("echo ""{0}{1} : "" NOLINE >>T:installpackagesmenu" -f $installPackageScript.Package.PackageFullName, $hasDependenciesIndicator)
            $installPackagesScriptLines += ("IF EXISTS ""T:{0}""" -f $installPackageScript.Package.PackageId)
            $installPackagesScriptLines += "  echo ""YES"" >>T:installpackagesmenu"
            $installPackagesScriptLines += "ELSE"
            $installPackagesScriptLines += "  echo ""NO "" >>T:installpackagesmenu"
            $installPackagesScriptLines += "ENDIF"
        }

        # add install package option and show install packages menu
        $installPackagesScriptLines += "echo ""========================================"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Select all packages"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Deselect all packages"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""View Readme"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Edit assigns"" >>T:installpackagesmenu"
        $installPackagesScriptLines += "echo ""Install packages"" >>T:installpackagesmenu"

        if ($hstwb.Settings.Installer.Mode -eq "BuildPackageInstallation")
        {
            $installPackagesScriptLines += "echo ""Quit"" >>T:installpackagesmenu"
        }
        else
        {
            $installPackagesScriptLines += "echo ""Skip packages"" >>T:installpackagesmenu"
        }

        $installPackagesScriptLines += ""
        $installPackagesScriptLines += "set installpackagesmenu """""
        $installPackagesScriptLines += "set installpackagesmenu ""``ReqList CLONERT I=T:installpackagesmenu H=""Select packages to install"" PAGE=18``"""
        $installPackagesScriptLines += "delete >NIL: T:installpackagesmenu"

        # switch package options
        for($i = 0; $i -lt $installPackageScripts.Count; $i++)
        {
            $installPackageScript = $installPackageScripts[$i]

            $installPackagesScriptLines += ""
            $installPackagesScriptLines += ("; Install package menu '{0}' option" -f $package.PackageFullName)
            $installPackagesScriptLines += ("IF ""`$installpackagesmenu"" eq """ + ($i + 1) + """")
            $installPackagesScriptLines += "  ; deselect package, if it's selected. Otherwise select package"
            $installPackagesScriptLines += ("  IF EXISTS ""T:{0}""" -f $installPackageScript.Package.PackageId)

            $packageName = $installPackageScript.Package.Package.Name.ToLower()

            # show package dependency warning, if package has dependencies
            if ($dependencyPackageNamesIndex.ContainsKey($packageName))
            {
                $installPackagesScriptLines += "    set showdependencywarning ""0"""
                $installPackagesScriptLines += "    set dependencypackagenames """""
                
                # list selected package names that has dependencies to package
                $dependencyPackageNames = @()
                $dependencyPackageNames += $dependencyPackageNamesIndex.Get_Item($packageName) | Foreach-Object { $hstwb.Packages.Get_Item($_).Latest.Package.Name }

                foreach($dependencyPackageName in $dependencyPackageNames)
                {
                    $package = $hstwb.Packages.Get_Item($dependencyPackageName).Latest

                    # add script lines to set show dependency warning, if dependency package is selected
                    $installPackagesScriptLines += ("    ; Set show dependency warning, if package '{0}' is selected" -f $package.PackageFullName)
                    $installPackagesScriptLines += ("    IF EXISTS ""T:{0}""" -f $package.PackageId)
                    $installPackagesScriptLines += "      set showdependencywarning ""1"""
                    $installPackagesScriptLines += "      IF ""`$dependencypackagenames"" EQ """""
                    $installPackagesScriptLines += ("        set dependencypackagenames ""{0}""" -f $package.Package.Name)
                    $installPackagesScriptLines += "      ELSE"
                    $installPackagesScriptLines += ("        set dependencypackagenames ""`$dependencypackagenames, {0}""" -f $package.Package.Name)
                    $installPackagesScriptLines += "      ENDIF"
                    $installPackagesScriptLines += "    ENDIF"
                    
                }

                # add script lines to show package dependency warning, if selected packages has dependencies to it
                $installPackagesScriptLines += "    set deselectpackage ""1"""
                $installPackagesScriptLines += "    IF `$showdependencywarning EQ 1 VAL"
                $installPackagesScriptLines += ("      set deselectpackage ``RequestChoice ""Package dependency warning"" ""Warning! Package(s) '`$dependencypackagenames' has a*Ndependency to '{0}' and deselecting it*Nmay cause issues when installing packages.*N*NAre you sure you want to deselect*Npackage '{0}'?"" ""Yes|No""``" -f $installPackageScript.Package.Package.Name)
                $installPackagesScriptLines += "    ENDIF"
                $installPackagesScriptLines += "    IF `$deselectpackage EQ 1 VAL"
                $installPackagesScriptLines += ("      delete >NIL: ""T:{0}""" -f $installPackageScript.Package.PackageId)
                $installPackagesScriptLines += "    ENDIF"
            }
            else
            {
                # deselect package, if no other packages has dependencies to it
                $installPackagesScriptLines += ("    delete >NIL: ""T:{0}""" -f $installPackageScript.Package.PackageId)
            }

            $installPackagesScriptLines += "  ELSE"

            $dependencyPackageNames = GetDependencyPackageNames $hstwb $installPackageScript.Package

            foreach($dependencyPackageName in $dependencyPackageNames)
            {
                $dependencyPackage = $hstwb.Packages.Get_Item($dependencyPackageName).Latest

                $installPackagesScriptLines += ("    ; Select dependency package '{0}'" -f $dependencyPackage.PackageFullName)
                $installPackagesScriptLines += ("    echo """" NOLINE >""T:{0}""" -f $dependencyPackage.PackageId)
            }
            
            $installPackagesScriptLines += ("    ; Select package '{0}'" -f $installPackageScript.Package.PackageFullName)
            $installPackagesScriptLines += ("    echo """" NOLINE >""T:{0}""" -f $installPackageScript.Package.PackageId)
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
        $installPackagesScriptLines += "  set confirm ``RequestChoice ""Confirm"" ""Do you want to install selected packages?"" ""Yes|No""``"
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
            $installPackagesScriptLines += "  set confirm ``RequestChoice ""Confirm"" ""Do you want to skip package installation?"" ""Yes|No""``"
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
            $installPackagesScriptLines += ("echo ""{0}"" >>T:viewreadmemenu" -f $installPackageScript.Package.PackageFullName)
        }

        # add back option to view readme menu
        $installPackagesScriptLines += "echo ""========================================"" >>T:viewreadmemenu"
        $installPackagesScriptLines += "echo ""Back"" >>T:viewreadmemenu"

        $installPackagesScriptLines += "set viewreadmemenu """""
        $installPackagesScriptLines += "set viewreadmemenu ""``ReqList CLONERT I=T:viewreadmemenu H=""View Readme"" PAGE=18``"""
        $installPackagesScriptLines += "delete >NIL: T:viewreadmemenu"

        # switch package options
        for($i = 0; $i -lt $installPackageScripts.Count; $i++)
        {
            $installPackageScript = $installPackageScripts[$i]

            $installPackagesScriptLines += ""
            $installPackagesScriptLines += ("IF ""`$viewreadmemenu"" eq """ + ($i + 1) + """")
            $installPackagesScriptLines += ("  IF EXISTS ""PACKAGESDIR:{0}/README.guide""" -f $installPackageScript.Package.PackageDirName)
            $installPackagesScriptLines += ("    cd ""PACKAGESDIR:{0}""" -f $installPackageScript.Package.PackageDirName)
            $installPackagesScriptLines += "    multiview README.guide"
            $installPackagesScriptLines += "    cd ""PACKAGESDIR:"""
            $installPackagesScriptLines += "  ELSE"
            $installPackagesScriptLines += ("    REQUESTCHOICE ""No Readme"" ""Package '{0}' doesn't have a readme file!"" ""OK"" >NIL:" -f $installPackageScript.Package.PackageFullName)
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
        $installPackagesScriptLines += "echo ""========================================"" >>T:editassignsmenu"
        $installPackagesScriptLines += "echo ""Reset assigns"" >>T:editassignsmenu"
        $installPackagesScriptLines += "echo ""Default assigns"" >>T:editassignsmenu"
        $installPackagesScriptLines += "echo ""Back"" >>T:editassignsmenu"

        $installPackagesScriptLines += "set editassignsmenu """""
        $installPackagesScriptLines += "set editassignsmenu ""``ReqList CLONERT I=T:editassignsmenu H=""Edit assigns"" PAGE=18``"""
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
    $installPackagesScriptLines += '  ; Create env-archive directory, if it doesn''t exist and ini file set for package assign'
    $installPackagesScriptLines += '  IF NOT EXISTS "{0}"' -f $hstwb.Paths.EnvArcDir
    $installPackagesScriptLines += '    MakePath "{0}"' -f $hstwb.Paths.EnvArcDir
    $installPackagesScriptLines += '  ENDIF'
    $installPackagesScriptLines += "ELSE"
    $installPackagesScriptLines += "  echo ""Validating assigns for packages..."""
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
                $installPackagesScriptLines += ("  echo ""*e[1mError: Assign '{0}' is not defined for package '{1}'!*e[0m""" -f $assignName, $installPackageScript.Package.PackageFullName)
            }

            $installPackagesScriptLines += "  Set assignsvalid 0"
            $installPackagesScriptLines += "ENDIF"
            $installPackagesScriptLines += "; Get device name from assigndir by replacing colon with newline and get 1st line with device name"
            $installPackagesScriptLines += "echo ""`$assigndir"" >T:_assigndir1"
            $installPackagesScriptLines += "rep T:_assigndir1 "":"" """""
            $installPackagesScriptLines += "sed ""1q;d"" T:_assigndir1 >T:_assigndir2"
            $installPackagesScriptLines += "set devicename ""``type T:_assigndir2``"""
            $installPackagesScriptLines += "Assign >NIL: EXISTS ""`$devicename:"""
            $installPackagesScriptLines += "IF WARN"
            $installPackagesScriptLines += "  echo ""*e[1mError: Device name '`$devicename:' in assign dir '`$assigndir' doesn't exist for package '{0}'!*e[0m""" -f $installPackageScript.Package.PackageFullName
            $installPackagesScriptLines += "  Set assignsvalid 0"
            $installPackagesScriptLines += "ENDIF"
        }
    }

    $installPackagesScriptLines += ''
    $installPackagesScriptLines += "IF ""{validate}"" EQ """""
    $installPackagesScriptLines += "  IF `$assignsvalid EQ 0 VAL"
    $installPackagesScriptLines += ("   echo ""Error: Validate assigns failed"" >>SYS:HstWB-Installer.log" -f $assignName)
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
    $installPackagesScriptLines += ("   echo ""Error: Validate assigns failed"" >>SYS:HstWB-Installer.log" -f $assignName)
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
            $installPackagesScriptLines += ("IF EXISTS T:" + $installPackageScript.Package.PackageId)
            $installPackagesScriptLines += 'execute PACKAGESDIR:IniFileSet "{0}/{1}" "{2}" "{3}" "{4}"' -f $hstwb.Paths.EnvArcDir, 'HstWB-Installer.Packages.ini', $installPackageScript.Package.Package.Name, 'Version', $installPackageScript.Package.Package.Version
            $installPackageScript.Lines | ForEach-Object { $installPackagesScriptLines += ("  " + $_) }
            $installPackagesScriptLines += "ENDIF"
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
    # winuae image harddrives config file
    $winuaeImageHarddrivesUaeConfigFile = [System.IO.Path]::Combine($hstwb.Settings.Image.ImageDir, "harddrives.uae")

    # fail, if winuae image harddrives config file doesn't exist
    if (!(Test-Path -Path $winuaeImageHarddrivesUaeConfigFile))
    {
        Fail $hstwb ("Error: Image harddrives config file '" + $winuaeImageHarddrivesUaeConfigFile + "' doesn't exist!")
    }

    # read winuae image harddrives config text
    $winuaeImageHarddrivesConfigText = [System.IO.File]::ReadAllText($winuaeImageHarddrivesUaeConfigFile)

    # replace imagedir placeholders
    $winuaeImageHarddrivesConfigText = $winuaeImageHarddrivesConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir)
    $winuaeImageHarddrivesConfigText = $winuaeImageHarddrivesConfigText.Replace('[$ImageDirEscaped]', $hstwb.Settings.Image.ImageDir)
    $winuaeImageHarddrivesConfigText = $winuaeImageHarddrivesConfigText.Replace('\\', '\').Replace('\', '/')
    $winuaeImageHarddrivesConfigText = $winuaeImageHarddrivesConfigText.Trim()

    $uaehfs = @()
    $winuaeImageHarddrivesConfigText -split "`r`n" | ForEach-Object { $_ | Select-String -Pattern '^uaehf\d+=(.*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $uaehfs += $_.Groups[1].Value.Trim() } }
    $harddrives = @()
    
    foreach ($uaehf in $uaehfs)
    {
        $uaehf | Select-String -Pattern '^hdf,[^,]*,([^,:]*):"?([^"]*)"?,[^,]*,[^,]*,[^,]*,[^,]*,([^,]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $harddrives += @{ 'Label' = $_.Groups[1].Value.Trim(); 'Path' = $_.Groups[2].Value.Trim(); 'Priority' = $_.Groups[3].Value.Trim() } }
        $uaehf | Select-String -Pattern '^dir,[^,]*,([^,:]*):[^,:]*:([^,]*),([^,]*)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $harddrives += @{ 'Label' = $_.Groups[1].Value.Trim(); 'Path' = $_.Groups[2].Value.Trim(); 'Priority' = $_.Groups[3].Value.Trim() } }
    }

    $fsUaeImageHarddrives = @()
    
    for($i = 0; $i -lt $harddrives.Count; $i++)
    {
        $harddrive = $harddrives[$i]
        $fsUaeImageHarddrives += "hard_drive_{0} = {1}" -f $i, ($harddrive.Path.Replace('\', '/'))
        $fsUaeImageHarddrives += "hard_drive_{0}_label = {1}" -f $i, ($harddrive.Label)
        
        if ($disableBootableHarddrives)
        {
            $fsUaeImageHarddrives += "hard_drive_{0}_priority = -128" -f $i
        }
        else
        {
            $fsUaeImageHarddrives += "hard_drive_{0}_priority = {1}" -f $i, $harddrive.Priority
        }
    }

    return $fsUaeImageHarddrives -join "`r`n"
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
    # winuae image harddrives config file
    $winuaeImageHarddrivesUaeConfigFile = [System.IO.Path]::Combine($hstwb.Settings.Image.ImageDir, "harddrives.uae")

    # fail, if winuae image harddrives config file doesn't exist
    if (!(Test-Path -Path $winuaeImageHarddrivesUaeConfigFile))
    {
        Fail $hstwb ("Error: Image harddrives config file '" + $winuaeImageHarddrivesUaeConfigFile + "' doesn't exist!")
    }

    # read winuae image harddrives config text
    $winuaeImageHarddrivesConfigText = [System.IO.File]::ReadAllText($winuaeImageHarddrivesUaeConfigFile)

    # replace imagedir placeholders
    $winuaeImageHarddrivesConfigText = $winuaeImageHarddrivesConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir)
    $winuaeImageHarddrivesConfigText = $winuaeImageHarddrivesConfigText.Replace('[$ImageDirEscaped]', $hstwb.Settings.Image.ImageDir.Replace('\', '\\'))
    $winuaeImageHarddrivesConfigText = $winuaeImageHarddrivesConfigText.Trim()

    if ($disableBootableHarddrives)
    {
        $winuaeImageHarddrivesConfigText = ($winuaeImageHarddrivesConfigText -split "`r`n" | ForEach-Object { $_ -replace ',-?\d+$', ',-128' -replace ',-?\d+,,uae$', ',-128,,uae' }) -join "`r`n"
    }

    return $winuaeImageHarddrivesConfigText
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


# run test
function RunTest($hstwb)
{
    # Build and set emulator config file
    # ----------------------------------
    $emulatorArgs = ''
    if ($hstwb.Settings.Emulator.EmulatorFile -match 'fs-uae\.exe$')
    {
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


    # temp and image hstwb installer log files
    $tempHstwbInstallerLogFile = Join-Path $tempInstallDir -ChildPath 'HstWB-Installer.log'
    $imageHstwbInstallerLogFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath 'HstWB-Installer.log'
    

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
    Copy-Item -Path "$amigaPackagesDir\*" $tempPackagesDir -recurse -force

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
    if ($hstwb.Settings.Workbench.InstallWorkbench -eq 'Yes' -and $hstwb.WorkbenchAdfSetHashes.Count -gt 0)
    {
        # create install workbench prefs file
        $installWorkbenchFile = Join-Path $prefsDir -ChildPath 'Install-Workbench'
        Set-Content $installWorkbenchFile -Value ""
        

        # copy workbench adf set files to temp install dir
        Write-Host "Copying Workbench adf files to temp install dir"
        $hstwb.WorkbenchAdfSetHashes | Where-Object { $_.File } | ForEach-Object { [System.IO.File]::Copy($_.File, (Join-Path $tempWorkbenchDir -ChildPath $_.Filename), $true) }
    }


    # prepare install kickstart
    if ($hstwb.Settings.Kickstart.InstallKickstart -eq 'Yes' -and $hstwb.KickstartRomSetHashes.Count -gt 0)
    {
        # create install kickstart prefs file
        $installKickstartFile = Join-Path $prefsDir -ChildPath 'Install-Kickstart'
        Set-Content $installKickstartFile -Value ""
        

        # copy kickstart rom set files to temp install dir
        Write-Host "Copying Kickstart rom files to temp install dir"
        $hstwb.KickstartRomSetHashes | Where-Object { $_.File } | ForEach-Object { [System.IO.File]::Copy($_.File, (Join-Path $tempKickstartDir -ChildPath $_.Filename), $true) }


        # get first kickstart rom hash
        $installKickstartRomHash = $hstwb.KickstartRomSetHashes | Select-Object -First 1


        # kickstart rom key
        $installKickstartRomKeyFile = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($installKickstartRomHash.File), "rom.key")


        # copy kickstart rom key file to temp install dir, if kickstart roms are encrypted
        if ($installKickstartRomHash.Encrypted -eq 'Yes' -and (test-path -path $installKickstartRomKeyFile))
        {
            Copy-Item -Path $installKickstartRomKeyFile -Destination ([System.IO.Path]::Combine($tempKickstartDir, "rom.key"))
        }
    }


    # find packages to install
    $installPackages = FindPackagesToInstall $hstwb


    # build assign hstwb installers script lines
    $assignHstwbInstallerScriptLines = BuildAssignHstwbInstallerScriptLines $hstwb $true

    # write assign hstwb installer to install dir
    $userAssignFile = [System.IO.Path]::Combine($tempInstallDir, "S\Assign-HstWB-Installer")
    WriteAmigaTextLines $userAssignFile $assignHstwbInstallerScriptLines 


    $hstwbInstallerPackagesIni = @{}


    $installPackagesReboot = $false

    # extract packages and write install packages script, if there's packages to install
    if ($installPackages.Count -gt 0)
    {
        $installPackagesReboot = $true

        # create install packages prefs file
        $installPackagesFile = Join-Path $prefsDir -ChildPath 'Install-Packages'
        Set-Content $installPackagesFile -Value ""


        # extract packages to package directory
        foreach($installPackage in $installPackages)
        {
            $package = $hstwb.Packages.Get_Item($installPackage.ToLower()).Latest

            # extract package file to package directory
            Write-Host ("Extracting '" + $package.PackageFullName + "' package to temp install dir")
            $packageDir = [System.IO.Path]::Combine($tempPackagesDir, $package.PackageDirName)

            if(!(test-path -path $packageDir))
            {
                mkdir $packageDir | Out-Null
            }

            [System.IO.Compression.ZipFile]::ExtractToDirectory($package.PackageFile, $packageDir)

            $hstwbInstallerPackagesIni.Set_Item($package.Package.Name, @{ 'Version' = $package.Package.Version })
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


    $installBoingBagsReboot = $false

    if ($hstwb.Settings.AmigaOS39.InstallAmigaOS39 -eq 'Yes' -and $hstwb.Settings.AmigaOS39.AmigaOS39IsoFile)
    {
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
        $os39Dir = $tempInstallDir
        $isoFile = ''
    }


    # read mountlist
    $mountlistFile = Join-Path -Path $tempInstallDir -ChildPath "Devs\Mountlist"
    $mountlistText = [System.IO.File]::ReadAllText($mountlistFile)

    # update and write mountlist
    $mountlistText = $mountlistText.Replace('[$OS39IsoFileName]', $amigaOs39IsoFileName)
    $mountlistText = [System.IO.File]::WriteAllText($mountlistFile, $mountlistText)


    # write hstwb installer packages ini file
    $hstwbInstallerPackagesIniFile = Join-Path $tempInstallDir -ChildPath 'HstWB-Installer.Packages.ini'
    WriteIniFile $hstwbInstallerPackagesIniFile $hstwbInstallerPackagesIni


    # build hstwb installer assigns ini
    $hstwbInstallerAssignsIni = @{}

    foreach ($assignSectionName in $hstwb.Assigns.keys)
    {
        $sectionAssigns = $hstwb.Assigns[$assignSectionName]

        foreach ($assignName in ($sectionAssigns.keys | Sort-Object | Where-Object { $_ -notlike 'HstWBInstallerDir' }))
        {
            if ($hstwbInstallerAssignsIni.ContainsKey($assignSectionName))
            {
                $hstwbInstallerAssignsSection = $hstwbInstallerAssignsIni.Get_Item($assignSectionName)
            }
            else
            {
                $hstwbInstallerAssignsSection = @{}
            }

            $hstwbInstallerAssignsSection.Set_Item($assignName, $sectionAssigns.Get_Item($assignName))
            $hstwbInstallerAssignsIni.Set_Item($assignSectionName, $hstwbInstallerAssignsSection)
        }
    }


    # write hstwb installer assigns ini file
    $hstwbInstallerAssignsIniFile = Join-Path $tempInstallDir -ChildPath 'HstWB-Installer.Assigns.ini'
    WriteIniFile $hstwbInstallerAssignsIniFile $hstwbInstallerAssignsIni

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
    

    # copy install uae config to image dir
    $installUaeConfigDir = [System.IO.Path]::Combine($hstwb.Paths.SupportPath, "Install UAE Config")
    Copy-Item -Path "$installUaeConfigDir\*" $hstwb.Settings.Image.ImageDir -recurse -force
    

    #
    $emulatorArgs = ''
    if ($hstwb.Settings.Emulator.EmulatorFile -match 'fs-uae\.exe$')
    {
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

    
    if (!$installPackagesReboot -and !$installBoingBagsReboot)
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
    if ($installBoingBagsReboot)
    {
        $task = "boing bags"
    }
    if ($installPackagesReboot)
    {
        if ($task.Length -gt 0)
        {
            $task += " and "
        }
        $task += "packages"
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


    # create temp install path
    $tempInstallDir = [System.IO.Path]::Combine($hstwb.Paths.TempPath, "install")
    if(!(test-path -path $tempInstallDir))
    {
        mkdir $tempInstallDir | Out-Null
    }

    # create temp licenses path
    $tempLicensesDir = Join-Path $tempInstallDir -ChildPath "Licenses"
    if(!(test-path -path $tempLicensesDir))
    {
        mkdir $tempLicensesDir | Out-Null
    }

    # create temp packages path
    $tempPackagesDir = [System.IO.Path]::Combine($hstwb.Paths.TempPath, "packages")
    if(!(test-path -path $tempPackagesDir))
    {
        mkdir $tempPackagesDir | Out-Null
    }


    # create install prefs directory
    $prefsDir = [System.IO.Path]::Combine($tempInstallDir, "Prefs")
    if(!(test-path -path $prefsDir))
    {
        mkdir $prefsDir | Out-Null
    }


    # temp and image hstwb installer log files
    $tempHstwbInstallerLogFile = Join-Path $tempInstallDir -ChildPath 'HstWB-Installer.log'
    $imageHstwbInstallerLogFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath 'HstWB-Installer.log'


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
    Copy-Item -Path "$amigaOs39Dir\*" $tempInstallDir -recurse -force

    # copy workbench to install directory
    $amigaWorkbenchDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "workbench")
    Copy-Item -Path "$amigaWorkbenchDir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force

    # copy kickstart to install directory
    $amigaKickstartDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "kickstart")
    Copy-Item -Path "$amigaKickstartDir\*" "$tempInstallDir\Install-SelfInstall" -recurse -force
    
    # copy amiga packages dir
    $amigaPackagesDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "packages")
    Copy-Item -Path "$amigaPackagesDir\*" $tempPackagesDir -recurse -force

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


        # extract packages to package directory
        foreach($installPackage in $installPackages)
        {
            $package = $hstwb.Packages.Get_Item($installPackage.ToLower()).Latest
            
            # extract package file to package directory
            Write-Host ("Extracting '" + $package.PackageFullName + "' package to temp install dir")
            $packageDir = [System.IO.Path]::Combine($tempPackagesDir, $package.PackageDirName)

            if(!(test-path -path $packageDir))
            {
                mkdir $packageDir | Out-Null
            }

            [System.IO.Compression.ZipFile]::ExtractToDirectory($package.PackageFile, $packageDir)
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


    # copy install uae config to image dir
    $installUaeConfigDir = [System.IO.Path]::Combine($hstwb.Paths.SupportPath, "Install UAE Config")
    Copy-Item -Path "$installUaeConfigDir\*" $hstwb.Settings.Image.ImageDir -recurse -force


    # copy support user packages to image dir
    $supportUserPackagesDir = Join-Path $hstwb.Paths.SupportPath -ChildPath "User Packages"
    $imageUserPackagesDir = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "UserPackages"
    if (!(Test-Path -Path $imageUserPackagesDir))
    {
        mkdir $imageUserPackagesDir | Out-Null
    }
    Copy-Item -Path "$supportUserPackagesDir\*" $imageUserPackagesDir -recurse -force
    

    # read winuae hstwb installer config file
    $winuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "hstwb-installer.uae")
    $hstwbInstallerUaeWinuaeConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)

    # build winuae self install harddrives config
    $hstwbInstallerWinuaeSelfInstallHarddrivesConfigText = BuildWinuaeSelfInstallHarddrivesConfigText $hstwb $workbenchDir $kickstartDir $hstwb.Settings.Image.ImageDir $imageUserPackagesDir


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
    $hstwbInstallerFsUaeSelfInstallHarddrivesConfigText = BuildFsUaeSelfInstallHarddrivesConfigText $hstwb $workbenchDir $kickstartDir $hstwb.Settings.Image.ImageDir $imageUserPackagesDir
    
    # replace hstwb installer fs-uae configuration placeholders
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile.Replace('\', '/'))
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', '')
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $hstwbInstallerFsUaeSelfInstallHarddrivesConfigText)
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$IsoFile]', '')
    $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$ImageDir]', $hstwb.Settings.Image.ImageDir.Replace('\', '/'))
    
    # write hstwb installer fs-uae configuration file to image dir
    $hstwbInstallerFsUaeConfigFile = Join-Path $hstwb.Settings.Image.ImageDir -ChildPath "hstwb-installer.fs-uae"
    [System.IO.File]::WriteAllText($hstwbInstallerFsUaeConfigFile, $fsUaeHstwbInstallerConfigText)
    

    #
    $emulatorArgs = ''
    if ($hstwb.Settings.Emulator.EmulatorFile -match 'fs-uae\.exe$')
    {
        # build fs-uae install harddrives config
        $fsUaeInstallHarddrivesConfigText = BuildFsUaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $tempInstallDir '' $true

        # read fs-uae hstwb installer config file
        $fsUaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.FsUaePath, "hstwb-installer.fs-uae")
        $fsUaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($fsUaeHstwbInstallerConfigFile)

        # replace hstwb installer fs-uae configuration placeholders
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', $hstwb.Paths.WorkbenchAdfFile.Replace('\', '/'))
        $fsUaeHstwbInstallerConfigText = $fsUaeHstwbInstallerConfigText.Replace('[$Harddrives]', $fsUaeInstallHarddrivesConfigText)
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
        # build winuae install harddrives config
        $winuaeInstallHarddrivesConfigText = BuildWinuaeInstallHarddrivesConfigText $hstwb $tempInstallDir $tempPackagesDir $tempInstallDir '' $true
    
        # read winuae hstwb installer config file
        $winuaeHstwbInstallerConfigFile = [System.IO.Path]::Combine($hstwb.Paths.WinuaePath, "hstwb-installer.uae")
        $winuaeHstwbInstallerConfigText = [System.IO.File]::ReadAllText($winuaeHstwbInstallerConfigFile)
    
        # replace winuae hstwb installer config placeholders
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$KickstartRomFile]', $hstwb.Paths.KickstartRomFile)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$WorkbenchAdfFile]', $hstwb.Paths.WorkbenchAdfFile)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$Harddrives]', $winuaeInstallHarddrivesConfigText)
        $winuaeHstwbInstallerConfigText = $winuaeHstwbInstallerConfigText.Replace('[$IsoFile]', '')
        
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
    $installPackages = FindPackagesToInstall $hstwb


    # extract packages and write install packages script, if there's packages to install
    if ($installPackages.Count -gt 0)
    {
        foreach($installPackage in $installPackages)
        {
            $package = $hstwb.Packages.Get_Item($installPackage.ToLower()).Latest
            
            # extract package file to package directory
            Write-Host ("Extracting '" + $package.PackageFullName + "' package to temp install dir")
            $packageDir = [System.IO.Path]::Combine($outputPackageInstallationPath, $package.PackageDirName)

            if(!(test-path -path $packageDir))
            {
                mkdir $packageDir | Out-Null
            }

            [System.IO.Compression.ZipFile]::ExtractToDirectory($package.PackageFile, $packageDir)
        }
    }


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
    $packageInstallationScriptLines += "SetEnv Packages ""``CD``"""
    $packageInstallationScriptLines += "Assign PACKAGESDIR: ""`$Packages"""
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
    $packageInstallationScriptLines += "Assign PACKAGESDIR: ""`$Packages"" REMOVE"
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
    $installPackagesScriptFile = [System.IO.Path]::Combine($outputPackageInstallationPath, "Package Installation")
    WriteAmigaTextLines $installPackagesScriptFile $packageInstallationScriptLines 


    # copy amiga package installation files
    $amigaPackageInstallationDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "packageinstallation")
    Copy-Item -Path "$amigaPackageInstallationDir\*" $outputPackageInstallationPath -recurse -force


    # copy amiga packages dir
    $amigaPackagesDir = [System.IO.Path]::Combine($hstwb.Paths.AmigaPath, "packages")
    Copy-Item -Path "$amigaPackagesDir\*" $outputPackageInstallationPath -recurse -force
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
$settingsDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($settingsDir)
$supportPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("support")
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
            'SupportPath' = $supportPath;
            'EnvArcDir' = 'SYSTEMDIR:Prefs/Env-Archive'
        };
        'Images' = ReadImages $imagesPath;
        'Packages' = ReadPackages $packagesPath;
        'Settings' = ReadIniFile $settingsFile;
        'Assigns' = ReadIniFile $assignsFile
    }


    # upgrade settings and assigns
    UpgradeSettings $hstwb
    UpgradeAssigns $hstwb
    
    
    # detect user packages
    $hstwb.UserPackages = DetectUserPackages $hstwb
    
    
    # update packages and assigns
    UpdatePackages $hstwb
    UpdateUserPackages $hstwb
    UpdateAssigns $hstwb
    
    
    # save settings and assigns
    Save $hstwb


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
    

    # print title and settings 
    $versionPadding = new-object System.String('-', ($hstwb.Version.Length + 2))
    Write-Host ("-------------------{0}" -f $versionPadding) -foregroundcolor "Yellow"
    Write-Host ("HstWB Installer Run v{0}" -f $hstwb.Version) -foregroundcolor "Yellow"
    Write-Host ("-------------------{0}" -f $versionPadding) -foregroundcolor "Yellow"
    Write-Host ""
    PrintSettings $hstwb
    Write-Host ""


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


    # find workbench adf set hashes 
    $workbenchAdfSetHashes = FindWorkbenchAdfSetHashes $hstwb.Settings $hstwb.Paths.WorkbenchAdfHashesFile

    # find workbench 3.1 workbench disk
    $workbenchAdfHash = $workbenchAdfSetHashes | Where-Object { $_.Name -eq 'Workbench 3.1 Workbench Disk' -and $_.File } | Select-Object -First 1

    # fail, if workbench adf hash doesn't exist
    if (!$workbenchAdfHash)
    {
        Fail $hstwb ("Workbench set '" + $hstwb.Settings.Workbench.WorkbenchAdfSet + "' doesn't have Workbench 3.1 Workbench Disk!")
    }


    # set workbench adf set hashes workbench adf file
    $hstwb.WorkbenchAdfSetHashes = $workbenchAdfSetHashes
    $hstwb.Paths.WorkbenchAdfFile = $workbenchAdfHash.File


    # print workbench adf hash file
    Write-Host ("Using Workbench 3.1 Workbench Disk adf: '" + $workbenchAdfHash.File + "'")


    # find kickstart rom set hashes
    $kickstartRomSetHashes = FindKickstartRomSetHashes $hstwb.Settings $hstwb.Paths.KickstartRomHashesFile


    # find kickstart 3.1 a1200 rom
    $kickstartRomHash = $kickstartRomSetHashes | Where-Object { $_.Name -eq 'Kickstart 3.1 (40.068) (A1200) Rom' -and $_.File } | Select-Object -First 1


    # fail, if kickstart rom hash doesn't exist
    if (!$kickstartRomHash)
    {
        Fail $hstwb ("Kickstart set '" + $hstwb.Settings.Kickstart.KickstartRomSet + "' doesn't have Kickstart 3.1 (40.068) (A1200) rom!")
    }


    # set kickstart rom set hashes kickstart rom file
    $hstwb.KickstartRomSetHashes = $kickstartRomSetHashes
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