# Make Installer Script
# ---------------------
#
# A powershell script to make a msi installer for HstWB Installer.
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-02-14

# Requirements:
# - Pandoc
# - WiX Toolset

# Pandoc is used to build html version of github markdown readme and can be downloaded here http://pandoc.org/installing.html.
# WiX Toolset is used to build a msi installer and can be downloaded here http://wixtoolset.org/releases/.


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
	$processInfo.CreateNoWindow = $true

    # Creating string builders to store stdout and stderr.
    $oStdOutBuilder = New-Object -TypeName System.Text.StringBuilder
    $oStdErrBuilder = New-Object -TypeName System.Text.StringBuilder

	# run process
	$process = New-Object System.Diagnostics.Process
	$process.StartInfo = $processInfo

    $sScripBlock = {
        if (! [String]::IsNullOrEmpty($EventArgs.Data)) {
            $Event.MessageData.AppendLine($EventArgs.Data)
        }
    }
	
	$oStdOutEvent = Register-ObjectEvent -InputObject $process `
        -Action $sScripBlock -EventName 'OutputDataReceived' `
        -MessageData $oStdOutBuilder
    $oStdErrEvent = Register-ObjectEvent -InputObject $process `
        -Action $sScripBlock -EventName 'ErrorDataReceived' `
        -MessageData $oStdErrBuilder


	$process.Start() | Out-Null
    $process.BeginErrorReadLine()
    $process.BeginOutputReadLine()
	$process.WaitForExit()

    # Unregistering events to retrieve process output.
    Unregister-Event -SourceIdentifier $oStdOutEvent.Name
    Unregister-Event -SourceIdentifier $oStdErrEvent.Name

	if ($process.ExitCode -ne 0)
	{
		if ($oStdOutBuilder.Length -gt 0)
		{
			Write-Host $oStdOutBuilder.ToString()
		}

		if ($oStdErrBuilder.Length -gt 0)
		{
			Write-Host $oStdErrBuilder.ToString()
		}

        Write-Error ("Failed to run '" + $fileName + "' with arguments '$arguments' returned error code " + $process.ExitCode)

        exit 1
	}
}


# paths
$pandocFile = Join-Path $env:LOCALAPPDATA -ChildPath 'Pandoc\pandoc.exe'
$wixToolsetDir = Join-Path ${Env:ProgramFiles(x86)} -ChildPath '\WiX Toolset v3.10\bin'
$wixToolsetHeatFile = Join-Path $wixToolsetDir -ChildPath 'heat.exe'
$wixToolsetCandleFile = Join-Path $wixToolsetDir -ChildPath 'candle.exe'
$wixToolsetLightFile = Join-Path $wixToolsetDir -ChildPath 'light.exe'
$rootDir = Resolve-Path '..'
$outputDir = Join-Path $rootDir -ChildPath 'output'


# fail, if pandoc file doesn't exist
if (!(Test-Path -path $pandocFile))
{
	Write-Error "Error: Pandoc file '$pandocFile' doesn't exist!"
	exit 1
}

# fail, if wix toolset directory doesn't exist
if (!(Test-Path -path $wixToolsetDir))
{
	Write-Error "Error: WiX Toolset directory '$wixToolsetDir' doesn't exist!"
	exit 1
}


# remove output directory, if it exists
if (Test-Path -Path $outputDir)
{
    Remove-Item -Path $outputDir -Recurse -Force
}

# create output directory
mkdir -Path $outputDir | Out-Null


# Build readme files
# ------------------

# build readme html from readme markdown using pandoc
$readmeFile = Resolve-Path '..\README.md'
$pandocArgs = "-f markdown_github -c ""github-pandoc.css"" -t html5 ""$readmeFile"" -o ""$outputDir\README.html"""
StartProcess $pandocFile $pandocArgs $outputDir

# copy css and screenshots for readme html
Copy-Item -Path 'github-pandoc.css' -Destination $outputDir


# Copy packages component directory
# ---------------------------------
$packagesPath = Join-Path -Path $rootDir -ChildPath 'Packages'
$packageFiles = Get-ChildItem $packagesPath\* -Include BetterWB*.zip, HstWB*.zip, EAB.WHDLoad.Demos.AGA.Menu*.zip, EAB.WHDLoad.Demos.OCS.Menu*.zip, EAB.WHDLoad.Games.AGA.Menu*.zip, EAB.WHDLoad.Games.OCS.Menu*.zip

$outputPackagesPath = Join-Path $outputDir -ChildPath 'Packages'
mkdir -Path $outputPackagesPath | Out-Null
$packageFiles | ForEach-Object { Copy-Item -Path $_.FullName -Destination $outputPackagesPath }


# Copy other component directories
# --------------------------------

$components = @("Images", "Kickstart", "Licenses", "Modules", "Screenshots", "Winuae", "Workbench" )
$components | ForEach-Object { Copy-Item -Path (Join-Path -Path $rootDir -ChildPath $_) -Recurse -Destination $outputDir }


# Harvest component directories to build wxs using wix toolset heat
# -----------------------------------------------------------------

$components += "Packages"

$wixToolsetHeatArgsComponents = @()

# build heat args for each component
$components | ForEach-Object { $wixToolsetHeatArgsComponents += ("dir ""{0}"" -o ""{0}.wxs"" -var var.{1}Dir -dr {1}ComponentDir -cg {1}ComponentGroup -sfrag -gg -g1" -f (Join-Path -Path $outputDir -ChildPath $_), $_) }

# run heat with args for each component
$wixToolsetHeatArgsComponents | ForEach-Object { StartProcess $wixToolsetHeatFile $_ $outputDir }


# Copy hstwb installer wix files
# ------------------------------

Copy-Item -Path (Resolve-Path '..\wix\*') -Recurse -Destination $outputDir


# Compile wxs using wix toolset candle
# ------------------------------------

$wixToolsetCandleArgs = '-dImagesDir="Images" -dKickstartDir="Kickstart" -dLicensesDir="Licenses" -dModulesDir="Modules" -dPackagesDir="Packages" -dScreenshotsDir="Screenshots" -dWinuaeDir="Winuae" -dWorkbenchDir="Workbench" "*.wxs"'
StartProcess $wixToolsetCandleFile $wixToolsetCandleArgs $outputDir


# Link wixobj using wix toolset light
# -----------------------------------

$wixToolsetLightArgs = "-o ""hstwb-installer.1.0.0.msi"" -ext WixUIExtension ""*.wixobj"""
StartProcess $wixToolsetLightFile $wixToolsetLightArgs $outputDir