# Build Release
# -------------
#
# A powershell script to build HstWB Installer portable zip and msi installer releases.
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-06-27

# Requirements:
# - Pandoc
# - WiX Toolset

# Pandoc is used to build html version of github markdown readme and can be downloaded here http://pandoc.org/installing.html.
# WiX Toolset is used to build a msi installer and can be downloaded here http://wixtoolset.org/releases/.

# Running msi installer with logging:
# msiexec /i hstwb-installer.msi /L*V "install.log"


Import-Module (Resolve-Path('..\modules\version.psm1')) -Force
Import-Module (Resolve-Path('..\modules\config.psm1')) -Force
Import-Module (Resolve-Path('..\modules\data.psm1')) -Force


# convert markdown to html
function ConvertMarkdownToHtml($pandocFile, $githubPandocFile, $markdownFile, $htmlFile)
{
	# build readme html from readme markdown using pandoc
	$pandocArgs = "-f markdown_github -c ""$githubPandocFile"" -t html5 ""$markdownFile"" -o ""$htmlFile"""
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
	$html = $html -replace '<style[^<>]+>(.*?)</style>', "<style type=""text/css"">`$1`r`n$githubPandocCss</style>" -replace '<link\s+rel="stylesheet"\s+href="github-pandoc.css">', ''
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
$components = @("Amiga", "Fonts", "Fs-Uae", "Images", "Kickstart", "Licenses", "Modules", "Readme", "Scripts", "Support", "Winuae", "Workbench" )


Write-Output "Build Release"
Write-Output "-------------"
Write-Output ""
Write-Output ("Release: 'HstWB Installer v{0}'"-f $hstwbInstallerVersion.ToLower())

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


# copy packages
Write-Output "- Copying packages files..."

$packagesPath = Join-Path -Path $rootDir -ChildPath 'Packages'
$packageFiles = @()
$packageFiles += Get-ChildItem $packagesPath\* -Include *.zip

$buildPackagesPath = Join-Path $buildDir -ChildPath 'Packages'
mkdir -Path $buildPackagesPath | Out-Null
$packageFiles | ForEach-Object { Copy-Item -Path $_.FullName -Destination $buildPackagesPath }


# build readme
Write-Output "- Building readme html files..."

$readmeMarkdownLines = @()
$readmeMarkdownLines += "# Readme"
$readmeMarkdownLines += ""
$readmeMarkdownLines += "This page gives an overview of readme for HstWB Installer and packages."
$readmeMarkdownLines += ""
$readmeMarkdownLines += "Readme for HstWB Installer:"
$readmeMarkdownLines += "* [HstWB Installer](HstWB Installer/readme.html)"

$readmeDir = Join-Path $buildDir -ChildPath 'Readme'
mkdir -Path $readmeDir | Out-Null

$hstwbInstallerReadmeDir = Join-Path $readmeDir -ChildPath 'HstWB Installer'
mkdir -Path $hstwbInstallerReadmeDir | Out-Null

# build readme html from readme markdown using pandoc
$hstwbInstallerReadmeMarkdownFile = Resolve-Path '..\README.md'
$hstwbInstallerReadmeHtmlFile = Join-Path $hstwbInstallerReadmeDir -ChildPath 'README.html'

# read github pandoc css and html
ConvertMarkdownToHtml $pandocFile $githubPandocFile $hstwbInstallerReadmeMarkdownFile $hstwbInstallerReadmeHtmlFile

# copy screenshots for readme
$screenshotsDir = Join-Path -Path $rootDir -ChildPath 'Screenshots'
Copy-Item $screenshotsDir -Destination $hstwbInstallerReadmeDir -Recurse


# extract read html files from packages
Write-Output "- Extracting readme html files from packages..."

# Copy packages readme and screenshots
$packagesReadmeDir = Join-Path $readmeDir -ChildPath 'Packages'
mkdir -Path $packagesReadmeDir | Out-Null

# add package readme line, if packages are present
if ($packageFiles.Count -gt 0)
{
	$readmeMarkdownLines += ""
	$readmeMarkdownLines += "Readme for package(s):"
}

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
	$packageName = $package.Name

	# create package readme directory
	$packageReadmeDir = Join-Path $packagesReadmeDir -ChildPath $packageName
	mkdir -Path $packageReadmeDir | Out-Null

	# extract readme and screenshot files from package
	ExtractFilesFromZipFile $packageFile.FullName '(readme.html|screenshots[\\/][^\.]+\.(png|jpg))' $packageReadmeDir

	# add package readme to readme markdown
	$packageReadmeDirIndex = $packageReadmeDir.IndexOf($readmeDir) + $readmeDir.Length + 1
	$packagesReadmeRelativeDir = $packageReadmeDir.Substring($packageReadmeDirIndex, $packageReadmeDir.Length - $packageReadmeDirIndex)
	$readmeMarkdownLines += "* [{0}]({1}/README.html)" -f $packageName, $packagesReadmeRelativeDir.Replace("\", "/")
}

# write readme markdown file
$readmeMarkdownFile = Join-Path $buildDir -ChildPath 'README.md'
Set-Content -path $readmeMarkdownFile -Value $readmeMarkdownLines -Encoding UTF8

# convert readme markdown file to html
$readmeHtmlFile = Join-Path $readmeDir -ChildPath 'README.html'
ConvertMarkdownToHtml $pandocFile $githubPandocFile $readmeMarkdownFile $readmeHtmlFile

Write-Output "Done."
Write-Output ("Successfully build HstWB Installer directory '{0}'." -f $buildDir)
Write-Output ""


# build portable release
# ----------------------

$portableZipFile = Join-Path $releaseDir -ChildPath ("hstwb-installer_{0}_portable.zip" -f $hstwbInstallerVersion.ToLower())

Write-Output "Build portable zip release"
Write-Output "--------------------------"
Write-Output "- Building portable zip release..."

# compress package directory
[System.IO.Compression.ZipFile]::CreateFromDirectory($buildDir, $portableZipFile, 'Optimal', $false)

Write-Output "Done."
Write-Output ("Successfully build portable zip release file '{0}'." -f $portableZipFile)
Write-Output ""


# build msi release
# -----------------
Write-Output "Build msi release"
Write-Output "-----------------"
Write-Output "- Building wxs components from directories..."

$components += "Packages"

$wixToolsetHeatArgsComponents = @()

# build heat args for each component
$components | ForEach-Object { $wixToolsetHeatArgsComponents += ("dir ""{0}"" -o ""{0}.wxs"" -sreg -var var.{1}Dir -dr {1}ComponentDir -cg {1}ComponentGroup -sfrag -gg -g1" -f (Join-Path -Path $buildDir -ChildPath $_), $_.Replace('-', '')) }

# run heat with args for each component
$wixToolsetHeatArgsComponents | ForEach-Object { Start-Process $wixToolsetHeatFile -ArgumentList $_ -WorkingDirectory $buildDir -Wait -NoNewWindow -PassThru }


# copy wix files
Write-Output "- Copying wix files..."

Copy-Item -Path (Resolve-Path '..\wix\*') -Recurse -Destination $buildDir

# update year in license rtf file
$licenseRtfFile = Join-Path $buildDir -ChildPath 'license.rtf'
$licenseRtfText = [System.IO.File]::ReadAllText($licenseRtfFile) -replace 'Copyright \(c\) \d+', ("Copyright (c) {0}" -f [System.DateTime]::Now.Year)
[System.IO.File]::WriteAllText($licenseRtfFile, $licenseRtfText)


# compile wxs files
Write-Output "- Compiling wxs files..."
Write-Output ""

$wixToolsetCandleArgs = ('-dVersion="' + ($hstwbInstallerVersion -replace '-[^\-]+$', '') + '" -dAmigaDir="Amiga" -dFontsDir="Fonts" -dFsUaeDir="Fs-Uae" -dImagesDir="Images" -dKickstartDir="Kickstart" -dLicensesDir="Licenses" -dModulesDir="Modules" -dPackagesDir="Packages" -dReadmeDir="Readme" -dScriptsDir="Scripts" -dSupportDir="Support" -dWinuaeDir="Winuae" -dWorkbenchDir="Workbench" "*.wxs"')
$candleProcess = Start-Process $wixToolsetCandleFile -ArgumentList $wixToolsetCandleArgs -WorkingDirectory $buildDir -Wait -NoNewWindow -PassThru

if ($candleProcess.ExitCode -ne 0)
{
	Write-Host ("Error: WiX Candle failed with exit code {0}!" -f $candleProcess.ExitCode) -ForegroundColor 'Red'
	exit 1
}


# link wixobj files
$msiFile = Join-Path $releaseDir -ChildPath ("hstwb-installer_{0}_setup.msi" -f $hstwbInstallerVersion.ToLower())
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