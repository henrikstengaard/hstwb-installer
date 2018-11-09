# Build Packages
# --------------
#
# A powershell script to build packages for HstWB Installer.
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-06-25


# paths
$currentDir = Resolve-Path '.'
$packagesDir = Resolve-Path '..\packages'

# create packages directory, if it doesn't exist
if (!(Test-Path $packagesDir))
{
    mkdir $packagesDir | Out-Null
}

# get package directories
$packageDirs = Get-ChildItem (Resolve-Path '..\..\') | `
    Where-Object { $_.PSIsContainer -and (Test-Path (Join-Path $_.FullName -ChildPath 'package\hstwb-package.json')) } | `
    Sort-Object

# update packages
foreach($packageDir in $packageDirs)
{
    Write-Host ("Updating package dir '{0}'..." -f $packageDir.FullName) -ForegroundColor Green

    Set-Location $packageDir.FullName

    # fail, if package has changes
    $changes = & "git" "status" "--porcelain"
    if ($changes -notmatch '^\s*$')
    {
        Write-Host ('Failed to update package dir ''{0}'': Package dir has changes' -f $packageDir.FullName) -ForegroundColor Red
        exit 1
    }

    # fail, if package has unpushed commits
    $unpushedCommits = & "git" "cherry" "-v"
    if ($unpushedCommits -notmatch '^\s*$')
    {
        Write-Host ('Failed to update package dir ''{0}'': Package dir has unpushed' -f $packageDir.FullName) -ForegroundColor Red
        exit 1
    }

    # fail, if package is not master branch
    $unpushedCommits = & "git" "rev-parse" "--abbrev-ref" "HEAD"
    if ($unpushedCommits -notmatch '^master$')
    {
        Write-Host ('Failed to update package dir ''{0}'': Package dir doesn''t not master branch' -f $packageDir.FullName) -ForegroundColor Red
        exit 1
    }

    # git pull latest changes
    & "git" "pull"
    if ($LASTEXITCODE -ne 0)
    {
        Write-Host ('Failed to update package dir ''{0}'': Git pull returned {1}' -f $packageDir.FullName, $LASTEXITCODE) -ForegroundColor Red
        exit 1
    }
}

# build packages
foreach($packageDir in $packageDirs)
{
    Write-Host ("Building package dir '{0}'..." -f $packageDir.FullName) -ForegroundColor Green

    try
    {
        # delete existing package zip files
        Get-ChildItem $packageDir.FullName -Filter *.zip | `
            ForEach-Object { Remove-Item $_.FullName -Force }

        # change directory to package tools directory
        $packageToolsDir = Join-Path $packageDir.FullName -ChildPath 'tools'
        Set-Location $packageToolsDir

        # build package
        & (Join-Path $packageToolsDir -ChildPath 'build_package.ps1')

        # copy package zip files to packages directory
        Get-ChildItem $packageDir.FullName -Filter *.zip | `
            ForEach-Object { Copy-Item $_.FullName -Destination $packagesDir -Force }
    }
    catch {
        Write-Error "Failed"
    }
}

# change directory to current directory
Set-Location $currentDir