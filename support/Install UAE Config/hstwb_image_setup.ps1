# HstWB Image Setup
# -----------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-05-28
#
# A powershell script to install UAE config for HstWB images by patching hard drive
# directories to current directory and installing Workbench 3.1 adf and
# Kickstart rom files from Cloanto Amiga Forever, if installed.


Param(
	[Parameter(Mandatory=$false)]
    [string]$installDir,
	[Parameter(Mandatory=$false)]
    [string]$amigaForeverDataDir
)


# get md5 entries from dir
function GetMd5EntriesFromDir($dir)
{
    $md5Entries = New-Object System.Collections.Generic.List[System.Object]

    foreach($file in (Get-ChildItem $dir | Where-Object { ! $_.PSIsContainer }))
    {
        $md5Entries.Add(@{
            'Md5' = (Get-FileHash $file.FullName -Algorithm MD5).Hash.ToLower();
            'File' = $file.FullName
        })
    }

    return $md5Entries
}


# workbench 3.1 adf md5 hashes
$workbench31AdfMd5Entries = @(
    @{ 'Md5' = 'c1c673eba985e9ab0888c5762cfa3d8f' }, # Workbench 3.1 Extras Disk Cloanto Amiga Forever 2016
    @{ 'Md5' = '6fae8b94bde75497021a044bdbf51abc' }, # Workbench 3.1 Fonts Disk Cloanto Amiga Forever 2016
    @{ 'Md5' = 'd6aa4537586bf3f2687f30f8d3099c99' }, # Workbench 3.1 Install Disk Cloanto Amiga Forever 2016
    @{ 'Md5' = 'b53c9ff336e168643b10c4a9cfff4276' }, # Workbench 3.1 Locale Disk Cloanto Amiga Forever 2016
    @{ 'Md5' = '4fa1401aeb814d3ed138f93c54a5caef' }, # Workbench 3.1 Storage Disk Cloanto Amiga Forever 2016
    @{ 'Md5' = '590c42a69675d6970df350e200fe25dc' }, # Workbench 3.1 Workbench Disk Cloanto Amiga Forever 2016

    @{ 'Md5' = 'c5be06daf40d4c3ace4eac874d9b48b1' }, # Workbench 3.1 Install Disk Cloanto Amiga Forever 7
    @{ 'Md5' = 'e7b3a83df665a85e7ec27306a152b171' } # Workbench 3.1 Workbench Disk Cloanto Amiga Forever 7
)

# kickstart rom md5 hashes
$kickstartRomMd5Entries = @(
    @{ 'Md5' = 'c56ca2a3c644d53e780a7e4dbdc6b699'; 'Encrypted' = $true; 'Amiga' = 'A500' }, # Kickstart 1.2 (33.180) (A500) Rom Kickstart Cloanto Amiga Forever 7/2016
    @{ 'Md5' = '89160c06ef4f17094382fc09841557a6'; 'Encrypted' = $true; 'Amiga' = 'A500' }, # Kickstart 1.3 (34.5) (A500) Rom Kickstart Cloanto Amiga Forever 7/2016
    @{ 'Md5' = 'c3e114cd3b513dc0377a4f5d149e2dd9'; 'Encrypted' = $true; 'Amiga' = 'A600' }, # Kickstart 3.1 (40.063) (A600) Rom Kickstart Cloanto Amiga Forever 7/2016
    @{ 'Md5' = 'dc3f5e4698936da34186d596c53681ab'; 'Encrypted' = $true; 'Amiga' = 'A1200' }, # Kickstart 3.1 (40.068) (A1200) Rom Kickstart Cloanto Amiga Forever 7/2016
    @{ 'Md5' = '8b54c2c5786e9d856ce820476505367d'; 'Encrypted' = $true; 'Amiga' = 'A4000' }, # Kickstart 3.1 (40.068) (A4000) Rom Kickstart Cloanto Amiga Forever 7/2016

    @{ 'Md5' = '85ad74194e87c08904327de1a9443b7a'; 'Encrypted' = $false; 'Amiga' = 'A500' }, # Kickstart 1.2 (33.180) (A500) Rom Original
    @{ 'Md5' = '82a21c1890cae844b3df741f2762d48d'; 'Encrypted' = $false; 'Amiga' = 'A500' }, # Kickstart 1.3 (34.5) (A500) Rom Original
    @{ 'Md5' = 'e40a5dfb3d017ba8779faba30cbd1c8e'; 'Encrypted' = $false; 'Amiga' = 'A600' }, # Kickstart 3.1 (40.063) (A600) Rom Original
    @{ 'Md5' = '646773759326fbac3b2311fd8c8793ee'; 'Encrypted' = $false; 'Amiga' = 'A1200' }, # Kickstart 3.1 (40.068) (A1200) Rom Original
    @{ 'Md5' = '9bdedde6a4f33555b4a270c8ca53297d'; 'Encrypted' = $false; 'Amiga' = 'A4000' } # Kickstart 3.1 (40.068) (A4000) Rom Original
)

# set install directory to current directory, if not defined
if (!$installDir)
{
    $installDir = '.'
}

# set amiga forever data directory to amiga forever data environment variable, if not defined
if (!$amigaForeverDataDir -and ${Env:AMIGAFOREVERDATA} -ne $null)
{
    $amigaForeverDataDir = ${Env:AMIGAFOREVERDATA}
}

# cloanto amiga forever data directory
if (!$amigaForeverDataDir -or !(Test-Path -Path $amigaForeverDataDir))
{
    $amigaForeverDataDir = $null
}


# resolve paths
$installDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($installDir)

# self install directories
$workbenchDir = Join-Path $installDir -ChildPath "workbench"
$kickstartDir = Join-Path $installDir -ChildPath "kickstart"
$os39Dir = Join-Path $installDir -ChildPath "os39"
$userPackagesDir = Join-Path $installDir -ChildPath "userpackages"

# write hstwb image setup title
Write-Output "-----------------"
Write-Output "HstWB Image Setup"
Write-Output "-----------------"
Write-Output "Author: Henrik Noerfjand Stengaard"
Write-Output "Date: 2018-05-28"
Write-Output ""
Write-Output "Patch hard drives to use the following directories:"
Write-Output ("Install dir              : '{0}'" -f $installDir)
Write-Output ("Workbench dir            : '{0}'" -f $workbenchDir)
Write-Output ("Kickstart dir            : '{0}'" -f $kickstartDir)
Write-Output ("OS39 dir                 : '{0}'" -f $os39Dir)
Write-Output ("User packages dir        : '{0}'" -f $userPackagesDir)

# create self install directories, if they don't exist
foreach ($selfInstallDir in @($workbenchDir, $kickstartDir, $os39Dir, $userPackagesDir))
{
    if (!(Test-Path -Path $selfInstallDir))
    {
        mkdir $selfInstallDir | Out-Null
    }
}

# winuae config directory
$winuaeConfigDir = Get-ChildItem -Path ${Env:PUBLIC} -Recurse | `
    Where-Object { $_.PSIsContainer -and $_.FullName -match 'Amiga Files\\WinUAE\\Configurations$' } | `
    Select-Object -First 1

if ($winuaeConfigDir)
{
    Write-Output ("WinUAE config dir        : '{0}'" -f $winuaeConfigDir)
}


Write-Output ""
Write-Output ("Amiga Forever data dir   : '{0}'" -f $amigaForeverDataDir)
if ($amigaForeverDataDir -and (Test-Path -Path $amigaForeverDataDir))
{
    $sharedDir = Join-Path $amigaForeverDataDir -ChildPath 'Shared'
    
    # install workbench 3.1 adf rom files from cloanto amiga forever data directory, if shared adf directory exists
    $sharedAdfDir = Join-Path $sharedDir -ChildPath "adf"
    if (Test-Path -path $sharedAdfDir)
    {
        Write-Output ("- Installing Workbench 3.1 adf files from '{0}'..." -f $sharedAdfDir)

        $workbench31AdfMd5Index = @{}
        $workbench31AdfMd5Entries | `
            ForEach-Object { $workbench31AdfMd5Index[$_.Md5.ToLower()] = $_ }

        GetMd5EntriesFromDir $sharedAdfDir | `
            Where-Object { $workbench31AdfMd5Index.ContainsKey($_.Md5.ToLower()) } | `
            ForEach-Object { Copy-Item $_.File -Destination $workbenchDir -Force }
    }

    # install kickstart rom files from cloanto amiga forever data directory, if shared rom directory exists
    $sharedRomDir = Join-Path $sharedDir -ChildPath "rom"
    if (Test-Path -Path $sharedRomDir)
    {
        Write-Output ("- Installing Kickstart rom files from '{0}'..." -f $sharedRomDir)

        $kickstartRomMd5Index = @{}
        $kickstartRomMd5Entries | `
            Where-Object { $_.Encrypted } | `
            ForEach-Object { $kickstartRomMd5Index[$_.Md5.ToLower()] = $_ }

        $md5Entries = @()
        $md5Entries += GetMd5EntriesFromDir $sharedRomDir | `
            Where-Object { $kickstartRomMd5Index.ContainsKey($_.Md5.ToLower()) }

        if ($md5Entries.Count -gt 0)
        {
            $romKeyFile = Join-Path $sharedRomDir -ChildPath 'rom.key'
            if (!(Test-Path $romKeyFile))
            {
                throw ("Amiga Forever rom key file '{0}' doesn't exist" -f $romKeyFile)
            }

            Copy-Item $romKeyFile -Destination $kickstartDir -Force
        }
                
        $md5Entries | `
            ForEach-Object { Copy-Item $_.File -Destination $kickstartDir -Force }
    }
}
else
{
    Write-Output ("- Skip. Amiga Forever data directory doesn't exist")
}


$a1200KickstartRomMd5Entry = $kickstartRomMd5Entries | `
    Where-Object { $_.Amiga -eq 'A1200' } | `
    Select-Object -First 1

$a1200KickstartRomFile = $null
if ($a1200KickstartRomMd5Entry)
{
    $a1200KickstartRomMd5Entry = GetMd5EntriesFromDir $kickstartDir | `
        Where-Object { $_.Md5.ToLower() -eq $a1200KickstartRomMd5Entry.Md5.ToLower() } | `
        Select-Object -First 1

    if ($a1200KickstartRomMd5Entry)
    {
        $a1200KickstartRomFile = $a1200KickstartRomMd5Entry.File
    }
}

if ($a1200KickstartRomFile)
{
    Write-Output ("using a1200 kickstart rom file '{0}'" -f $a1200KickstartRomFile)
}


exit

# get a1200 kickstart 3.1 rom from a1200 kickstart rom dir
$a1200KickstartRomFile = FindA1200Kickstart31RomFile $a1200KickstartRomDir

# patch and install winuae config file, if it exists
Write-Output ""
if (Test-Path -Path $winuaeConfigFile)
{
    # patch winuae config file
    Write-Output ("WinUAE configuration file '{0}'" -f $winuaeConfigFile)
    Write-Output "- Patching hard drive directories, kickstart rom file and Amiga OS 3.9 iso file..."
    PatchWinuaeConfigFile $winuaeConfigFile $a1200KickstartRomFile $workbenchDir $kickstartDir $os39Dir $userPackagesDir
    

    # install winuae config file, if winuae config directory exists and patch only is not set
    if (!$patchOnly -and $winuaeConfigDir)
    {
        Write-Output ("- Installing in WinUAE configuration directory '{0}'..." -f $winuaeConfigDir.FullName)
        Copy-Item $winuaeConfigFile -Destination $winuaeConfigDir.FullName -Force
    }

    Write-Output "Done"
}
else
{
    Write-Output ("WinUAE configuration file '{0}' doesn't exist!" -f $winuaeConfigFile)
}

# patch and install fs-uae config file, if it exists
if (Test-Path -Path $fsuaeConfigFile)
{
    Write-Output ""
    Write-Output ("FS-UAE configuration file '{0}'" -f $fsuaeConfigFile)
    
    # patch fs-uae config file
    Write-Output "- Patching hard drive directories, kickstart rom file, Amiga OS 3.9 iso file and add Workbench adf files as swappable floppies..."
    PatchFsuaeConfigFile $fsuaeConfigFile $a1200KickstartRomFile $workbenchDir $kickstartDir $os39Dir $userPackagesDir

    # get fs-uae config directory from my documents directory
    $fsuaeConfigDir = Get-ChildItem -Path ([System.Environment]::GetFolderPath("MyDocuments")) -Recurse | Where-Object { $_.PSIsContainer -and $_.FullName -match 'FS-UAE\\Configurations$' } | Select-Object -First 1
    
    # install fs-uae config file, if fs-uae config directory exists and patch only is not set
    if (!$patchOnly -and $fsuaeConfigDir)
    {
        Write-Output ("- Installing in FS-UAE configuration directory '{0}'..." -f $fsuaeConfigDir.FullName)
        Copy-Item $fsuaeConfigFile -Destination $fsuaeConfigDir.FullName -Force
    }

    Write-Output "Done"
}
else
{
    Write-Output ("FS-UAE configuration file '{0}' doesn't exist!" -f $fsuaeConfigFile)
}