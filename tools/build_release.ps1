# Build Release
# -------------
#
# A powershell script to build HstWB Installer portable zip and msi installer releases.
#
# Author: Henrik Noerfjand Stengaard
# Date:   2019-03-29

# Requirements:
# - Pandoc
# - WiX Toolset

# Pandoc is used to build html version of github markdown readme and can be downloaded here http://pandoc.org/installing.html.
# WiX Toolset is used to build a msi installer and can be downloaded here http://wixtoolset.org/releases/.

# Running msi installer with logging:
# msiexec /i hstwb-installer.msi /L*V "install.log"


Param(
	[Parameter(Mandatory=$false)]
	[switch]$packages,
	[Parameter(Mandatory=$false)]
	[switch]$msi
)


Import-Module (Resolve-Path('..\modules\version.psm1')) -Force
Import-Module (Resolve-Path('..\modules\config.psm1')) -Force
Import-Module (Resolve-Path('..\modules\data.psm1')) -Force


# convert markdown to html
function ConvertMarkdownToHtml($pandocFile, $githubPandocFile, $title, $markdownFile, $htmlFile)
{
	# build readme html from readme markdown using pandoc
	#$pandocArgs = "-f markdown_github -c ""$githubPandocFile"" -t html5 ""$markdownFile"" -o ""$htmlFile"""
	$pandocArgs = "-s --metadata pagetitle=""$title"" -f gfm --css=""github-pandoc.css"" -t html5 ""$markdownFile"" -o ""$htmlFile"""
	$pandocProcess = Start-Process $pandocFile -ArgumentList $pandocArgs -WorkingDirectory (Split-Path $markdownFile -Parent) -Wait -NoNewWindow -PassThru
	
	if ($pandocProcess.ExitCode -ne 0)
	{
		Write-Host ("Error: Pandoc failed with exit code {0}!" -f $pandocProcess.ExitCode) -ForegroundColor 'Red'
		exit 1
	}
	
	# read github pandoc css and html
	$githubPandocCss = [System.IO.File]::ReadAllText($githubPandocFile)
	$html = [System.IO.File]::ReadAllText($htmlFile)

	# embed github pandoc css and remove stylesheet link
	$html = $html -replace '</head>', "<style type=""text/css"">$githubPandocCss</style>`r`n</head>" -replace '<link\s+rel="stylesheet"\s+href="github-pandoc.css"\s*/>', ''
	[System.IO.File]::WriteAllText($htmlFile, $html)	
}


# paths
$hstwbInstallerVersion = HstwbInstallerVersion
$pandocFile = Join-Path $env:LOCALAPPDATA -ChildPath 'Pandoc\pandoc.exe'
$githubPandocFile = Resolve-Path 'github-pandoc.css'
$wixToolsetDir = Join-Path ${Env:ProgramFiles(x86)} -ChildPath '\WiX Toolset v3.10\bin'
$wixToolsetHeatFile = Join-Path $wixToolsetDir -ChildPath 'heat.exe'
$wixToolsetCandleFile = Join-Path $wixToolsetDir -ChildPath 'candle.exe'
$wixToolsetLightFile = Join-Path $wixToolsetDir -ChildPath 'light.exe'
$rootDir = Resolve-Path '..'
$releaseDir = Join-Path $rootDir -ChildPath '.release'
$buildDir = Join-Path $releaseDir -ChildPath '.build'
$components = @("Amiga", "Data", "Fonts", "Fs-Uae", "Images", "Licenses", "Modules", "Readme", "Scripts", "Support", "Winuae")
$packagesText = if ($packages) { ' with packages' } else { '' }
$packagesFileName = if ($packages) { '_packages' } else { '' }


Write-Output "Build Release"
Write-Output "-------------"
Write-Output ""

Write-Output ("Release: 'HstWB Installer v{0}'{1}" -f $hstwbInstallerVersion.ToLower(), $packagesText)
		
# fail, if pandoc file doesn't exist
if (!(Test-Path -path $pandocFile))
{
	Write-Error "Error: Pandoc file '$pandocFile' doesn't exist!"
	exit 1
}

# fail, if wix toolset directory doesn't exist
if ($msi -and !(Test-Path -path $wixToolsetDir))
{
	Write-Error "Error: WiX Toolset directory '$wixToolsetDir' doesn't exist!"
	exit 1
}


# remove release directory, if it exists
if (Test-Path -Path $releaseDir)
{
    Remove-Item -Path $releaseDir -Recurse -Force
}

# create release directory
mkdir -Path $releaseDir | Out-Null

# create build directory
mkdir -Path $buildDir | Out-Null


# build hstwb installer
# ---------------------

Write-Output ""
Write-Output "Build HstWB Installer"
Write-Output "---------------------"

# copy application
Write-Output "- Copying application files..."

Copy-Item -Path (Resolve-Path '..\install.*') -Recurse -Destination $buildDir
Copy-Item -Path (Resolve-Path '..\launcher.*') -Recurse -Destination $buildDir
Copy-Item -Path (Resolve-Path '..\setup.*') -Recurse -Destination $buildDir
Copy-Item -Path (Resolve-Path '..\run.*') -Recurse -Destination $buildDir
Copy-Item -Path (Resolve-Path '..\LICENSE.txt') -Recurse -Destination $buildDir
Copy-Item -Path (Resolve-Path '..\hstwb_installer.ico') -Recurse -Destination $buildDir

# update year in license txt file
$licenseTxtFile = Join-Path $buildDir -ChildPath 'LICENSE.txt'
$licenseTxtText = [System.IO.File]::ReadAllText($licenseTxtFile) -replace 'Copyright \(c\) \d+', ("Copyright (c) {0}" -f [System.DateTime]::Now.Year)
[System.IO.File]::WriteAllText($licenseTxtFile, $licenseTxtText)

# copy componenet directories
foreach($component in $components)
{
	$componentDir = Join-Path -Path $rootDir -ChildPath $component

	if (!(Test-Path $componentDir))
	{
		continue
	}

	Copy-Item -Path $componentDir -Recurse -Destination $buildDir
}

# create packages build directory
$buildPackagesPath = Join-Path $buildDir -ChildPath 'Packages'
mkdir -Path $buildPackagesPath | Out-Null

# copy packages
if ($packages)
{
	Write-Output "- Copying packages files..."

	$packagesPath = Join-Path -Path $rootDir -ChildPath 'Packages'
	$packageFiles = @()
	$packageFiles += Get-ChildItem $packagesPath\* -Include *.zip

	$packageFiles | ForEach-Object { Copy-Item -Path $_.FullName -Destination $buildPackagesPath }
}


# build readme
Write-Output "- Building readme html files..."

$readmeMarkdownLines = @()
$readmeMarkdownLines += "# Readme"
$readmeMarkdownLines += ""
$readmeMarkdownLines += "This page gives an overview of readme for HstWB Installer and packages."
$readmeMarkdownLines += ""
$readmeMarkdownLines += "Readme for HstWB Installer:"
$readmeMarkdownLines += "* [HstWB Installer](hstwb-installer/readme.html)"

$readmeDir = Join-Path $buildDir -ChildPath 'Readme'
mkdir -Path $readmeDir | Out-Null

$hstwbInstallerReadmeDir = Join-Path $readmeDir -ChildPath 'hstwb-installer'
mkdir -Path $hstwbInstallerReadmeDir | Out-Null

# build readme html from readme markdown using pandoc
$hstwbInstallerReadmeMarkdownFile = Resolve-Path '..\readme.md'
$hstwbInstallerReadmeHtmlFile = Join-Path $hstwbInstallerReadmeDir -ChildPath 'readme.html'

# read github pandoc css and html
ConvertMarkdownToHtml $pandocFile $githubPandocFile 'HstWB Installer' $hstwbInstallerReadmeMarkdownFile $hstwbInstallerReadmeHtmlFile

# add package readme line, if packages are present
if ($packageFiles.Count -gt 0)
{
	# extract read html files from packages
	Write-Output "- Extracting readme html files from packages..."

	# Copy packages readme and screenshots
	$packagesReadmeDir = Join-Path $readmeDir -ChildPath 'packages'
	mkdir -Path $packagesReadmeDir | Out-Null

	$readmeMarkdownLines += ""
	$readmeMarkdownLines += "Readme for package(s):"

	foreach($packageFile in $packageFiles)
	{
		# skip, if package doesn't a readme.html file
		if (!(ZipFileContains $packageFile.FullName 'readme.html'))
		{
			continue
		}
	
		# read hstwb package json text file from package file
		$packageJsonText = ReadZipEntryTextFile $packageFile.FullName 'hstwb-package.json$'
	
		# return, if hstwb package json text file doesn't exist
		if (!$packageJsonText)
		{
			Fail ("Package '{0}' doesn't contain 'hstwb-package.json' file" -f $packageFile.FullName)
		}
	
		# read hstwb package json text
		$package = $packageJsonText | ConvertFrom-Json
		
		# fail, if package name doesn't exist
		if (!$package.Name -or $package.Name -eq '')
		{
			Fail ("Package '{0}' doesn't have a valid name" -f $packageFile.FullName)
		}
	
		# package name
		$packageName = $package.Name.ToLower() -replace ' ', '-'
	
		# create package readme directory
		$packageReadmeDir = Join-Path $packagesReadmeDir -ChildPath $packageName
		mkdir -Path $packageReadmeDir | Out-Null
	
		# extract readme and screenshot files from package
		ExtractFilesFromZipFile $packageFile.FullName '(readme.html|screenshots[\\/][^\.]+\.(png|jpg))' $packageReadmeDir

		# package readme file
		$packageReadmeFile = Get-ChildItem $packageReadmeDir -Filter 'readme.html' | Select-Object -First 1

		# add package readme to readme markdown
		$packageReadmeDirIndex = $packageReadmeDir.IndexOf($readmeDir) + $readmeDir.Length + 1
		$packagesReadmeRelativeDir = $packageReadmeDir.Substring($packageReadmeDirIndex, $packageReadmeDir.Length - $packageReadmeDirIndex)
		$readmeMarkdownLines += "* [{0}]({1}/{2})" -f $package.Name, $packagesReadmeRelativeDir.Replace("\", "/"), $packageReadmeFile.Name
	}
}

# write readme markdown file
$readmeMarkdownFile = Join-Path $buildDir -ChildPath 'readme.md'
Set-Content -path $readmeMarkdownFile -Value $readmeMarkdownLines -Encoding UTF8

# convert readme markdown file to html
$readmeHtmlFile = Join-Path $readmeDir -ChildPath 'readme.html'
ConvertMarkdownToHtml $pandocFile $githubPandocFile 'Readme' $readmeMarkdownFile $readmeHtmlFile

Write-Output "Done."
Write-Output ("Successfully build HstWB Installer directory '{0}'." -f $buildDir)
Write-Output ""


# build portable release
# ----------------------

$portableZipFile = Join-Path $releaseDir -ChildPath ("hstwb-installer_{0}{1}_portable.zip" -f $hstwbInstallerVersion.ToLower(), $packagesFileName)

Write-Output "Build portable zip release"
Write-Output "--------------------------"
Write-Output ("- Building portable zip release{0}..." -f $packagesText)

# compress package directory
[System.IO.Compression.ZipFile]::CreateFromDirectory($buildDir, $portableZipFile, 'Optimal', $false)

Write-Output "Done."
Write-Output ("Successfully build portable zip release file '{0}'." -f $portableZipFile)


if (!$msi)
{
	exit
}

# build msi release
# -----------------
Write-Output ""
Write-Output "Build msi release"
Write-Output "-----------------"
Write-Output "- Building wxs components from directories..."

if ($packages)
{
	$components += "Packages"
}

$wixToolsetHeatArgsComponents = @()

# build heat args for each component
$components | ForEach-Object { $wixToolsetHeatArgsComponents += ("dir ""{0}"" -o ""{0}.wxs"" -sreg -var var.{1}Dir -dr {1}ComponentDir -cg {1}ComponentGroup -sfrag -gg -g1" -f (Join-Path -Path $buildDir -ChildPath $_), $_.Replace('-', '')) }

# run heat with args for each component
$wixToolsetHeatArgsComponents | ForEach-Object { Start-Process $wixToolsetHeatFile -ArgumentList $_ -WorkingDirectory $buildDir -Wait -NoNewWindow -PassThru }


# copy wix files
Write-Output "- Copying wix files..."

Copy-Item -Path (Resolve-Path '..\wix\license.rtf') -Recurse -Destination $buildDir
Copy-Item -Path (Resolve-Path ('..\wix\hstwb-installer{0}.wxs' -f $packagesFileName)) -Recurse -Destination $buildDir

# update year in license rtf file
$licenseRtfFile = Join-Path $buildDir -ChildPath 'license.rtf'
$licenseRtfText = [System.IO.File]::ReadAllText($licenseRtfFile) -replace 'Copyright \(c\) \d+', ("Copyright (c) {0}" -f [System.DateTime]::Now.Year)
[System.IO.File]::WriteAllText($licenseRtfFile, $licenseRtfText)


# compile wxs files
Write-Output "- Compiling wxs files..."
Write-Output ""

$packagesDirectoryArg = if ($packages) { ' -dPackagesDir="Packages"' } else { '' }
$wixToolsetCandleArgs = ('-dVersion="{0}" -dAmigaDir="Amiga" -dDataDir="Data" -dFontsDir="Fonts" -dFsUaeDir="Fs-Uae" -dImagesDir="Images" -dLicensesDir="Licenses" -dModulesDir="Modules" -dReadmeDir="Readme" -dScriptsDir="Scripts" -dSupportDir="Support" -dWinuaeDir="Winuae"{1} "*.wxs"' -f ($hstwbInstallerVersion -replace '-[^\-]+$', ''), $packagesDirectoryArg)
$candleProcess = Start-Process $wixToolsetCandleFile -ArgumentList $wixToolsetCandleArgs -WorkingDirectory $buildDir -Wait -NoNewWindow -PassThru

if ($candleProcess.ExitCode -ne 0)
{
	Write-Host ("Error: WiX Candle failed with exit code {0}!" -f $candleProcess.ExitCode) -ForegroundColor 'Red'
	exit 1
}


# link wixobj files
$msiFile = Join-Path $releaseDir -ChildPath ("hstwb-installer_{0}{1}_setup.msi" -f $hstwbInstallerVersion.ToLower(), $packagesFileName)
Write-Output "- Linking wixobj files..."
Write-Output ""

$wixToolsetLightArgs = "-o ""{0}"" -ext WixUIExtension -ext WixUtilExtension ""*.wixobj""" -f $msiFile
$lightProcess = Start-Process $wixToolsetLightFile -ArgumentList $wixToolsetLightArgs -WorkingDirectory $buildDir -Wait -NoNewWindow -PassThru

if ($lightProcess.ExitCode -ne 0)
{
	Write-Host ("Error: WiX Light failed with exit code {0}!" -f $candleProcess.ExitCode) -ForegroundColor 'Red'
	exit
}

Write-Output ""
Write-Output "Done."
Write-Output ("Successfully build msi release file '{0}'." -f $msiFile)