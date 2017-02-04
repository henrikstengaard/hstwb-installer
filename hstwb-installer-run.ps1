# HstWB Installer Run
# -------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-01-27
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


        # open package file and get first package ini file
        $zip = [System.IO.Compression.ZipFile]::Open($packageFile.FullName,"Read")
        $packageIniZipEntry = $zip.Entries | Where { $_.FullName -match 'package.ini$' }


        # return, if package file doesn't contain a package ini file 
        if (!$packageIniZipEntry)
        {
            Fail ("Package '" + $packageFile.FullName + "' doesn't contain a package.ini file")
        }


        # create package directory
        $packageDir = [System.IO.Path]::Combine($tempPackagesDir, $packageFileName)
        if(!(test-path -path $packageDir))
        {
            md $packageDir | Out-Null
        }


        # extract package ini file
        $packageIniFile = [System.IO.Path]::Combine($packageDir, "package.ini")
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($packageIniZipEntry, $packageIniFile, $true)


        # fail, if package doesn't contain package ini file
        if (!(test-path -path $packageIniFile))
        {
            Fail ("Package ini file '$packageIniFile' doesn't exist")
        }


        # read package ini file
        $packageIni = ReadIniFile $packageIniFile


        # package name
        $packageName = $packageIni.Package.Name 


        # fail, if package name doesn't exist
        if (!$packageName -or $packageName -eq '')
        {
            Fail ("Package '$packageFileName' doesn't contain name in package.ini file")
        }


        # delete package ini file
        Remove-Item -Path $packageIniFile -Force


        # add package details
        $packageDetails.Set_Item($packageName, @{ "Name" = $packageName; "Package" = $packageFileName; "PackageFile" = $packageFile.FullName; "PackageDir" = $packageDir })


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
function BuildUserAssignScriptLines()
{
    $hstwbInstallerAssigns = $assigns.Get_Item('HstWB Installer')
    return $hstwbInstallerAssigns.keys | ForEach-Object { ("makepath """ + $hstwbInstallerAssigns.Get_Item($_) + """`nAssign " + $_ + ": """ + $hstwbInstallerAssigns.Get_Item($_) + """") }
}


# build install packages script lines
function BuildInstallPackagesScriptLines($packageNames)
{
    $hstwbInstallerAssigns = $assigns.Get_Item("HstWB Installer")

    $installPackagesLines = @()

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


        # add package installation lines to install packages script
        $installPackagesLines += ("; Install package "+ $package.Package.Name + " v" + $package.Package.Version)
        $installPackagesLines += "echo """""
        $installPackagesLines += ("echo ""Package '" + $package.Package.Name + " v" + $package.Package.Version + "'""")

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
                $installPackagesLines += "; Add package assign for '$packageAssignName' to '$assignPath'"
                $installPackagesLines += "Assign >NIL: EXISTS ""$assignDrive"""
                $installPackagesLines += "IF WARN"
                $installPackagesLines += "  echo ""Error: '$assignDrive' doesn't exist and is required by package!"""
                $installPackagesLines += "  ask ask ""Press ENTER to continue"""
                $installPackagesLines += "ELSE"
                $installPackagesLines += ("  makepath """ + $assignPath + """")
                $installPackagesLines += ("  Assign " + $packageAssignName + ": """ + $assignPath + """")
                $installPackagesLines += "ENDIF"

                # remove package assign lines
                $removePackageAssignLines += ("Assign " + $packageAssignName + ": """ + $assignPath + """ REMOVE")
            }
        }


        # add assign package dir and execute package install
        $installPackagesLines += "; Assign package dir and execute install script"
        $installPackagesLines += ("Assign PACKAGEDIR: ""PACKAGES:" + $packageName + """")
        $installPackagesLines += "execute ""PACKAGEDIR:Install"""
        $installPackagesLines += ("Assign PACKAGEDIR: ""PACKAGES:" + $packageName + """ REMOVE")


        # add remove package assign lines, if there are any
        if ($removePackageAssignLines.Count -gt 0)
        {
            $installPackagesLines += "; Remove package assigns"
            $installPackagesLines += $removePackageAssignLines
        }


        $installPackagesLines += "echo ""Done."""
        $installPackagesLines += ""
    }

    return $installPackagesLines
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
    $userAssignScriptLines = BuildUserAssignScriptLines

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
            [System.IO.Compression.ZipFile]::ExtractToDirectory($installPackage.PackageFile, $installPackage.PackageDir)
        }

        # build install package script lines
        $installPackagesScriptLines = @()
        $installPackagesScriptLines += "echo """""
        $installPackagesScriptLines += "echo ""Package Installation"""
        $installPackagesScriptLines += "echo ""--------------------"""
        $installPackagesScriptLines += BuildInstallPackagesScriptLines ($installPackages | ForEach-Object { $_.Package })

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


# run self install
function RunSelfInstall()
{
    # print preparing self install message
    Write-Host ""
    Write-Host "Preparing self install..."


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
    $userAssignScriptLines += BuildUserAssignScriptLines

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
            [System.IO.Compression.ZipFile]::ExtractToDirectory($installPackage.PackageFile, $installPackage.PackageDir)
        }
    }


    # install packages title message
    $installPackagesScriptLines = @()
    $installPackagesScriptLines += "echo ""*ec"""
    $installPackagesScriptLines += "echo ""Package Installation"""
    $installPackagesScriptLines += "echo ""--------------------"""

    # build install package script lines
    $installPackagesScriptLines += BuildInstallPackagesScriptLines ($installPackages | ForEach-Object { $_.Package })

    # install packages complete message
    $installPackagesScriptLines += "echo """""
    $installPackagesScriptLines += "echo ""Package installation is complete."""
    $installPackagesScriptLines += "echo """""
    $installPackagesScriptLines += "ask ""Press ENTER to continue"""

    # write install packages script
    $installPackagesScriptFile = [System.IO.Path]::Combine($tempInstallDir, "HstWBInstaller\Install-Packages")
    WriteAmigaTextLines $installPackagesScriptFile $installPackagesScriptLines 


    # read winuae install config file
    $winuaeInstallConfigFile = [System.IO.Path]::Combine($winuaePath, "install.uae")
    $winuaeInstallConfig = [System.IO.File]::ReadAllText($winuaeInstallConfigFile)


    # replace winuae install config placeholders
    $winuaeInstallConfig = $winuaeInstallConfig.Replace('[$KICKSTARTROMFILE]', $kickstartRomHash.File).Replace('[$WORKBENCHADFFILE]', $workbenchAdfHash.File).Replace('[$IMAGEFILE]', $settings.Image.HdfImagePath).Replace('[$INSTALLDIR]', $tempInstallDir).Replace('[$PACKAGESDIR]', $tempPackagesDir)
    $tempWinuaeInstallConfigFile = [System.IO.Path]::Combine($tempPath, "install.uae")


    # write winuae install config file to temp install dir
    [System.IO.File]::WriteAllText($tempWinuaeInstallConfigFile, $winuaeInstallConfig)


    # write installing file in install dir. should be deleted by winuae and is used to verify if installation process succeeded
    $installingFile = [System.IO.Path]::Combine($tempInstallDir, "S\Installing")
    [System.IO.File]::WriteAllText($installingFile, "")


    # print preparing installation done message
    Write-Host "Done."


    # print launching winuae message
    Write-Host ""
    Write-Host "Launching WinUAE to install image..."


    # winuae args
    $winuaeArgs = "-f ""$tempWinuaeInstallConfigFile"""

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
    "Self-Install" { RunSelfInstall }
}


# remove temp path
Remove-Item -Recurse -Force $tempPath


# print done message 
Write-Host "Done."
Write-Host ""
Write-Host "Press enter to continue"
Read-Host
