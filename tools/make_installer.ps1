# Make Installer Script
# ---------------------
#
# A powershell script to make a msi installer for HstWB Installer.
#
# Author: Henrik Noerfjand Stengaard
# Date:   2017-09-19

# Requirements:
# - Pandoc
# - WiX Toolset

# Pandoc is used to build html version of github markdown readme and can be downloaded here http://pandoc.org/installing.html.
# WiX Toolset is used to build a msi installer and can be downloaded here http://wixtoolset.org/releases/.


Import-Module (Resolve-Path('..\modules\version.psm1')) -Force
Import-Module (Resolve-Path('..\modules\config.psm1')) -Force
Import-Module (Resolve-Path('..\modules\data.psm1')) -Force


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
$hstwbInstallerVersion = HstwbInstallerVersion
$pandocFile = Join-Path $env:LOCALAPPDATA -ChildPath 'Pandoc\pandoc.exe'
$wixToolsetDir = Join-Path ${Env:ProgramFiles(x86)} -ChildPath '\WiX Toolset v3.10\bin'
$wixToolsetHeatFile = Join-Path $wixToolsetDir -ChildPath 'heat.exe'
$wixToolsetCandleFile = Join-Path $wixToolsetDir -ChildPath 'candle.exe'
$wixToolsetLightFile = Join-Path $wixToolsetDir -ChildPath 'light.exe'
$rootDir = Resolve-Path '..'
$outputDir = Join-Path $rootDir -ChildPath '.output'


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

Write-Host "Building readme html from github markdown..."

$readmeDir = Join-Path $outputDir -ChildPath 'Readme'
mkdir -Path $readmeDir | Out-Null

$hstwbInstallerReadmeDir = Join-Path $readmeDir -ChildPath 'HstWB Installer'
mkdir -Path $hstwbInstallerReadmeDir | Out-Null

# build readme html from readme markdown using pandoc
$readmeMarkdownFile = Resolve-Path '..\README.md'
$readmeHtmlFile = Join-Path $hstwbInstallerReadmeDir -ChildPath 'README.html'
$pandocArgs = "-f markdown_github -c ""github-pandoc.css"" -t html5 ""$readmeMarkdownFile"" -o ""$readmeHtmlFile"""
StartProcess $pandocFile $pandocArgs $hstwbInstallerReadmeDir

# read github pandoc css and html
$githubPandocFile = Resolve-Path 'github-pandoc.css'
$githubPandocCss = [System.IO.File]::ReadAllText($githubPandocFile)
$readmeHtml = [System.IO.File]::ReadAllText($readmeHtmlFile)

# embed github pandoc css and remove stylesheet link
$readmeHtml = $readmeHtml -replace '<style[^<>]+>(.*?)</style>', "<style type=""text/css"">`$1`r`n$githubPandocCss</style>" -replace '<link\s+rel="stylesheet"\s+href="github-pandoc.css">', ''
[System.IO.File]::WriteAllText($readmeHtmlFile, $readmeHtml)

# copy screenshots for readme
$screenshotsDir = Join-Path -Path $rootDir -ChildPath 'Screenshots'
Copy-Item $screenshotsDir -Destination $hstwbInstallerReadmeDir -Recurse

Write-Host "Done."

# Copy packages component directory
# ---------------------------------

Write-Host "Copying packages component directory..."

$packagesPath = Join-Path -Path $rootDir -ChildPath 'Packages'
$packageFiles = @()
$packageFiles += Get-ChildItem $packagesPath\* -Include *.zip

$outputPackagesPath = Join-Path $outputDir -ChildPath 'Packages'
mkdir -Path $outputPackagesPath | Out-Null
$packageFiles | ForEach-Object { Copy-Item -Path $_.FullName -Destination $outputPackagesPath }

Write-Host "Done."


# Copy packages readme and screenshots

$packagesReadmeDir = Join-Path $readmeDir -ChildPath 'Packages'
mkdir -Path $packagesReadmeDir | Out-Null

foreach($packageFile in $packageFiles)
{
	# skip, if package doesn't a readme.html file
	if (!(ZipFileContains $packageFile.FullName 'readme.html'))
	{
		continue
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

	# create package readme directory
	$packageReadmeDir = Join-Path $packagesReadmeDir -ChildPath $packageName
	mkdir -Path $packageReadmeDir | Out-Null

	# extract readme and screenshot files from package
	ExtractFilesFromZipFile $packageFile.FullName '(readme.html|screenshots[\\/][^\.]+\.(png|jpg))' $packageReadmeDir
}


# Copy other component directories
# --------------------------------

Write-Host "Copying component directories..."

$components = @("Amiga", "Fonts", "Fs-Uae", "Images", "Kickstart", "Licenses", "Modules", "Readme", "Scripts", "Support", "Winuae", "Workbench" )

foreach($component in $components)
{
	$componentDir = Join-Path -Path $rootDir -ChildPath $component

	if (!(Test-Path $componentDir))
	{
		continue
	}

	Copy-Item -Path $componentDir -Recurse -Destination $outputDir
}

Write-Host "Done."

# Harvest component directories to build wxs using wix toolset heat
# -----------------------------------------------------------------

Write-Host "Building wxs components from directories..."

$components += "Packages"

$wixToolsetHeatArgsComponents = @()

# build heat args for each component
$components | ForEach-Object { $wixToolsetHeatArgsComponents += ("dir ""{0}"" -o ""{0}.wxs"" -var var.{1}Dir -dr {1}ComponentDir -cg {1}ComponentGroup -sfrag -gg -g1" -f (Join-Path -Path $outputDir -ChildPath $_), $_.Replace('-', '')) }

# run heat with args for each component
$wixToolsetHeatArgsComponents | ForEach-Object { StartProcess $wixToolsetHeatFile $_ $outputDir }

Write-Host "Done."


# Copy hstwb installer wix files
# ------------------------------

Write-Host "Copying HstWB Installer wix files..."

Copy-Item -Path (Resolve-Path '..\wix\*') -Recurse -Destination $outputDir
Copy-Item -Path (Resolve-Path '..\launcher.*') -Recurse -Destination $outputDir
Copy-Item -Path (Resolve-Path '..\setup.*') -Recurse -Destination $outputDir
Copy-Item -Path (Resolve-Path '..\run.*') -Recurse -Destination $outputDir
Copy-Item -Path (Resolve-Path '..\LICENSE.txt') -Recurse -Destination $outputDir
Copy-Item -Path (Resolve-Path '..\hstwb_installer.ico') -Recurse -Destination $outputDir

# Update year in license files
$licenseRtfFile = Join-Path $outputDir -ChildPath 'license.rtf'
$licenseRtfText = [System.IO.File]::ReadAllText($licenseRtfFile) -replace 'Copyright \(c\) \d+', ("Copyright (c) {0}" -f [System.DateTime]::Now.Year)
[System.IO.File]::WriteAllText($licenseRtfFile, $licenseRtfText)

$licenseTxtFile = Join-Path $outputDir -ChildPath 'LICENSE.txt'
$licenseTxtText = [System.IO.File]::ReadAllText($licenseTxtFile) -replace 'Copyright \(c\) \d+', ("Copyright (c) {0}" -f [System.DateTime]::Now.Year)
[System.IO.File]::WriteAllText($licenseTxtFile, $licenseTxtText)

Write-Host "Done."


# Compile wxs using wix toolset candle
# ------------------------------------

Write-Host "Compiling wxs files..."

$wixToolsetCandleArgs = ('-dVersion="' + ($hstwbInstallerVersion -replace '-[^\-]+$', '') + '" -dAmigaDir="Amiga" -dFontsDir="Fonts" -dFsUaeDir="Fs-Uae" -dImagesDir="Images" -dKickstartDir="Kickstart" -dLicensesDir="Licenses" -dModulesDir="Modules" -dPackagesDir="Packages" -dReadmeDir="Readme" -dScriptsDir="Scripts" -dSupportDir="Support" -dWinuaeDir="Winuae" -dWorkbenchDir="Workbench" "*.wxs"')
StartProcess $wixToolsetCandleFile $wixToolsetCandleArgs $outputDir

Write-Host "Done."


# Link wixobj using wix toolset light
# -----------------------------------

Write-Host "Linking wixobj files..."

$wixToolsetLightArgs = "-o ""hstwb-installer.{0}.msi"" -ext WixUIExtension ""*.wixobj""" -f ($hstwbInstallerVersion.ToLower())
StartProcess $wixToolsetLightFile $wixToolsetLightArgs $outputDir

Write-Host "Done."