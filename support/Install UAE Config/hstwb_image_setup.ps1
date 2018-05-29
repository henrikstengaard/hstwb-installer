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


# get md5 files from dir
function GetMd5FilesFromDir($dir)
{
    $md5Files = New-Object System.Collections.Generic.List[System.Object]

    foreach($file in (Get-ChildItem $dir | Where-Object { ! $_.PSIsContainer }))
    {
        $md5Files.Add(@{
            'Md5' = (Get-FileHash $file.FullName -Algorithm MD5).Hash.ToLower();
            'File' = $file.FullName
        })
    }

    return $md5Files
}


# workbench 3.1 adf md5 entries
$workbench31AdfMd5Entries = @(
    @{ 'Md5' = 'c1c673eba985e9ab0888c5762cfa3d8f'; 'Filename' = 'workbench31extras.adf'; 'Name' = 'Workbench 3.1, Extras Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = '6fae8b94bde75497021a044bdbf51abc'; 'Filename' = 'workbench31fonts.adf'; 'Name' = 'Workbench 3.1, Fonts Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = 'd6aa4537586bf3f2687f30f8d3099c99'; 'Filename' = 'workbench31install.adf'; 'Name' = 'Workbench 3.1, Install Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = 'b53c9ff336e168643b10c4a9cfff4276'; 'Filename' = 'workbench31locale.adf'; 'Name' = 'Workbench 3.1, Locale Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = '4fa1401aeb814d3ed138f93c54a5caef'; 'Filename' = 'workbench31storage.adf'; 'Name' = 'Workbench 3.1, Storage Disk (Cloanto Amiga Forever 2016)' },
    @{ 'Md5' = '590c42a69675d6970df350e200fe25dc'; 'Filename' = 'workbench31workbench.adf'; 'Name' = 'Workbench 3.1, Workbench Disk (Cloanto Amiga Forever 2016)' },

    @{ 'Md5' = 'c5be06daf40d4c3ace4eac874d9b48b1'; 'Filename' = 'workbench31install.adf'; 'Name' = 'Workbench 3.1, Install Disk (Cloanto Amiga Forever 7)' },
    @{ 'Md5' = 'e7b3a83df665a85e7ec27306a152b171'; 'Filename' = 'workbench31workbench.adf'; 'Name' = 'Workbench 3.1, Workbench Disk (Cloanto Amiga Forever 7)' }
)

# kickstart rom md5 entries
$kickstartRomMd5Entries = @(
    @{ 'Md5' = 'c56ca2a3c644d53e780a7e4dbdc6b699'; 'Filename' = 'kick33180.A500'; 'Encrypted' = $true; 'Name' = 'Kickstart 1.2, 33.180, A500 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = '89160c06ef4f17094382fc09841557a6'; 'Filename' = 'kick34005.A500'; 'Encrypted' = $true; 'Name' = 'Kickstart 1.3, 34.5, A500 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = 'c3e114cd3b513dc0377a4f5d149e2dd9'; 'Filename' = 'kick40063.A600'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1, 40.063, A600 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = 'dc3f5e4698936da34186d596c53681ab'; 'Filename' = 'kick40068.A1200'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1, 40.068, A1200 Rom (Cloanto Amiga Forever 7/2016)' },
    @{ 'Md5' = '8b54c2c5786e9d856ce820476505367d'; 'Filename' = 'kick40068.A4000'; 'Encrypted' = $true; 'Name' = 'Kickstart 3.1, 40.068, A4000 Rom (Cloanto Amiga Forever 7/2016)' },

    @{ 'Md5' = '85ad74194e87c08904327de1a9443b7a'; 'Filename' = 'kick33180.A500'; 'Encrypted' = $false; 'Name' = 'Kickstart 1.2, 33.180, A500 Rom (Original)' },
    @{ 'Md5' = '82a21c1890cae844b3df741f2762d48d'; 'Filename' = 'kick34005.A500'; 'Encrypted' = $false; 'Name' = 'Kickstart 1.3, 34.5, A500 Rom (Original)' },
    @{ 'Md5' = 'e40a5dfb3d017ba8779faba30cbd1c8e'; 'Filename' = 'kick40063.A600'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1, 40.063, A600 Rom (Original)' },
    @{ 'Md5' = '646773759326fbac3b2311fd8c8793ee'; 'Filename' = 'kick40068.A1200'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1, 40.068, A1200 Rom (Original)' },
    @{ 'Md5' = '9bdedde6a4f33555b4a270c8ca53297d'; 'Filename' = 'kick40068.A4000'; 'Encrypted' = $false; 'Name' = 'Kickstart 3.1, 40.068, A4000 Rom (Original)' }
)

# os 39 md5 entries
$os39Md5Entries = @(
    @{ 'Md5' = '3cb96e77d922a4f8eb696e525a240448'; 'Filename' = 'amigaos3.9.iso'; 'Name' = 'Amiga OS 3.9 iso'; 'Size' = 490856448 },
    @{ 'Md5' = 'e32a107e68edfc9b28a2fe075e32e5f6'; 'Filename' = 'amigaos3.9.iso'; 'Name' = 'Amiga OS 3.9 iso'; 'Size' = 490686464 },
    @{ 'Md5' = '71353d4aeb9af1f129545618d013a8c8'; 'Filename' = 'boingbag39-1.lha'; 'Name' = 'Boing Bag 1 for Amiga OS 3.9'; 'Size' = 5254174 },
    @{ 'Md5' = 'fd45d24bb408203883a4c9a56e968e28'; 'Filename' = 'boingbag39-2.lha'; 'Name' = 'Boing Bag 2 for Amiga OS 3.9'; 'Size' = 2053444 }
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
Write-Output "Date: 2018-05-29"
Write-Output ""
Write-Output ("Install dir : '{0}'" -f $installDir)

# create self install directories, if they don't exist
foreach ($selfInstallDir in @($workbenchDir, $kickstartDir, $os39Dir, $userPackagesDir))
{
    if (!(Test-Path -Path $selfInstallDir))
    {
        mkdir $selfInstallDir | Out-Null
    }
}

# cloanto amiga forever
Write-Output ""
Write-Output "Cloanto Amiga Forever"
Write-Output "---------------------"
Write-Output ("Amiga Forever data dir : '{0}'" -f $amigaForeverDataDir)
if ($amigaForeverDataDir -and (Test-Path -Path $amigaForeverDataDir))
{
    $sharedDir = Join-Path $amigaForeverDataDir -ChildPath 'Shared'
    
    # install workbench 3.1 adf rom files from cloanto amiga forever data directory, if shared adf directory exists
    $sharedAdfDir = Join-Path $sharedDir -ChildPath "adf"
    if (Test-Path -path $sharedAdfDir)
    {
        Write-Output ("- Installing Workbench 3.1 adf files to Workbench directory '{0}'..." -f $workbenchDir)

        # index workbench 3.1 adf md5
        $workbench31AdfMd5Index = @{}
        $workbench31AdfMd5Entries | `
            ForEach-Object { $workbench31AdfMd5Index[$_.Md5.ToLower()] = $_ }

        # copy workbench 3.1 adf files from shared adf dir that matches workbench 3.1 md5
        GetMd5FilesFromDir $sharedAdfDir | `
            Where-Object { $workbench31AdfMd5Index.ContainsKey($_.Md5.ToLower()) } | `
            ForEach-Object { Copy-Item $_.File -Destination $workbenchDir -Force }
    }
    else
    {
        Write-Output ("- Amiga Forever data shared adf directory '{0}' doesn't exist!" -f $sharedAdfDir)
    }

    # install kickstart rom files from cloanto amiga forever data directory, if shared rom directory exists
    $sharedRomDir = Join-Path $sharedDir -ChildPath "rom"
    if (Test-Path -Path $sharedRomDir)
    {
        Write-Output ("- Installing Kickstart rom files to Kickstart directory '{0}'..." -f $kickstartDir)

        # index kickstart rom md5
        $kickstartRomMd5Index = @{}
        $kickstartRomMd5Entries | `
            Where-Object { $_.Encrypted } | `
            ForEach-Object { $kickstartRomMd5Index[$_.Md5.ToLower()] = $_ }

        # copy kickstart rom files from shared rom dir that matches kickstart rom md5
        GetMd5FilesFromDir $sharedRomDir | `
            Where-Object { $kickstartRomMd5Index.ContainsKey($_.Md5.ToLower()) } | `
            ForEach-Object { Copy-Item $_.File -Destination $kickstartDir -Force }

        # copy amiga forever rom key file, if it exists
        $romKeyFile = Join-Path $sharedRomDir -ChildPath 'rom.key'
        if (Test-Path $romKeyFile)
        {
            Copy-Item $romKeyFile -Destination $kickstartDir -Force
        }
    }
    else
    {
        Write-Output ("- Amiga Forever data shared rom directory '{0}' doesn't exist!" -f $sharedRomDir)
    }
}
else
{
    Write-Output ("- Amiga Forever data directory doesn't exist!")
}



Write-Output ""
Write-Output "Validating self install directories"
Write-Output "-----------------------------------"

# index workbench 3.1 adf md5
$workbench31AdfMd5Index = @{}
$workbench31AdfMd5Entries | `
    ForEach-Object { $workbench31AdfMd5Index[$_.Md5.ToLower()] = $_ }

# get workbench 3.1 adf files from workbench dir that matches workbench 3.1 md5
$workbench31AdfMd5Files = GetMd5FilesFromDir $workbenchDir | `
    Where-Object { $workbench31AdfMd5Index.ContainsKey($_.Md5.ToLower()) }

# workbench 3.1 adf filenames
$workbench31AdfFilenames = $workbench31AdfMd5Entries.Filename | `
    Sort-Object | `
    Get-Unique

# workbench 3.1 adf filenames detected
$workbench31AdfFilenamesDetected = $workbench31AdfMd5Files | `
    Where-Object { $workbench31AdfMd5Index.ContainsKey($_.Md5.ToLower()) } | `
    ForEach-Object { $workbench31AdfMd5Index[$_.Md5.ToLower()].Filename } | `
    Sort-Object | `
    Get-Unique

# write workbench directory
Write-Output ("Workbench dir : '{0}'" -f $workbenchDir)
Write-Output ("- {0} of {1} Workbench 3.1 adf files detected" -f $workbench31AdfFilenamesDetected.Count, $workbench31AdfFilenames.Count)
$workbench31AdfMd5Files | `
    ForEach-Object { Write-Output ("- {0} : '{1}'" -f $workbench31AdfMd5Index[$_.Md5.ToLower()].Name, $_.File) }

# index kickstart rom md5
$kickstartRomMd5Index = @{}
$kickstartRomMd5Entries | `
    ForEach-Object { $kickstartRomMd5Index[$_.Md5.ToLower()] = $_ }

# get kickstart rom files from kickstart dir that matches kickstart rom md5
$kickstartRomMd5Files = GetMd5FilesFromDir $kickstartDir | `
    Where-Object { $kickstartRomMd5Index.ContainsKey($_.Md5.ToLower()) }

# workbench 3.1 adf filenames
$kickstartRomFilenames = $kickstartRomMd5Entries.Filename | `
    Sort-Object | `
    Get-Unique

# workbench 3.1 adf filenames detected
$kickstartRomFilenamesDetected = $kickstartRomMd5Files | `
    Where-Object { $kickstartRomMd5Index.ContainsKey($_.Md5.ToLower()) } | `
    ForEach-Object { $kickstartRomMd5Index[$_.Md5.ToLower()].Filename } | `
    Sort-Object | `
    Get-Unique
    
# write kickstart directory
Write-Output ""
Write-Output ("Kickstart dir : '{0}'" -f $kickstartDir)
Write-Output ("- {0} of {1} Kickstart rom files detected" -f $kickstartRomFilenamesDetected.Count, $kickstartRomFilenames.Count)
$kickstartRomMd5Files | `
    ForEach-Object { Write-Output ("- {0} : '{1}'" -f $kickstartRomMd5Index[$_.Md5.ToLower()].Name, $_.File) }

# index os39 md5
$os39Md5Index = @{}
$os39Md5Entries | `
    ForEach-Object { $os39Md5Index[$_.Md5.ToLower()] = $_ }

# get os39 files from os39 dir
$os39Md5Files = GetMd5FilesFromDir $os39Dir

# os39 filenames
$os39Filenames = $os39Md5Entries.Filename | `
    Sort-Object | `
    Get-Unique

# os39 filenames detected
$os39FilenamesDetected = $os39Md5Files | `
    Where-Object { $os39Md5Index.ContainsKey($_.Md5.ToLower()) -or $os39Filenames -contains (Split-Path $_.File -Leaf) } | `
    ForEach-Object { $_.File }
    Sort-Object | `
    Get-Unique

# write os39 directory
Write-Output ""
Write-Output ("OS39 dir : '{0}'" -f $os39Dir)
Write-Output ("- {0} of {1} Amiga OS 3.9 files detected" -f $os39FilenamesDetected.Count, $os39Filenames.Count)

# write user packages directory
Write-Output ""
Write-Output ("User packages dir        : '{0}'" -f $userPackagesDir)



# find first a1200 kickstart 3.1 rom md5 entry
$a1200KickstartRomMd5Entry = $kickstartRomMd5Entries | `
    Where-Object { $_.Filename -match 'kick40068\.A1200' } | `
    Select-Object -First 1

# find a1200 kickstart 3.1 rom file
$a1200KickstartRomFile = $null
if ($a1200KickstartRomMd5Entry)
{
    # find first a1200 kickstart 3.1 rom md5 file from kickstart dir
    $a1200KickstartRomMd5File = GetMd5FilesFromDir $kickstartDir | `
        Where-Object { $_.Md5.ToLower() -eq $a1200KickstartRomMd5Entry.Md5.ToLower() } | `
        Select-Object -First 1

    # set a1200 kickstart rom file, if a1200 kickstart rom md5 file exists
    if ($a1200KickstartRomMd5File)
    {
        # fail, if a1200 kickstart rom entry is encrypted and rom key file doesn't exist
        $romKeyFile = Join-Path $kickstartDir -ChildPath 'rom.key'
        if ($a1200KickstartRomMd5Entry.Encrypted -and !(Test-Path $romKeyFile))
        {
            throw ("Amiga Forever rom key file '{0}' doesn't exist" -f $romKeyFile)
        }

        $a1200KickstartRomFile = $a1200KickstartRomMd5File.File
    }
}

if ($a1200KickstartRomFile)
{
    Write-Output ("using a1200 kickstart rom file '{0}'" -f $a1200KickstartRomFile)

}

# uae configuration
Write-Output ""
Write-Output "UAE configuration"
Write-Output "-----------------"

# winuae config directory
$winuaeConfigDir = Get-ChildItem -Path ${Env:PUBLIC} -Recurse | `
    Where-Object { $_.PSIsContainer -and $_.FullName -match 'Amiga Files\\WinUAE\\Configurations$' } | `
    Select-Object -First 1

# write winuae configuration dir, if it exists
if ($winuaeConfigDir)
{
    Write-Output ("WinUAE configuration dir : '{0}'" -f $winuaeConfigDir.FullName)
}

# get uae config files from install directory
$uaeConfigFiles = @()
$uaeConfigFiles += Get-ChildItem $installDir -Filter *.uae

# patch and install uae configuration files
Write-Output ("Patching and installing UAE configuration files from '{0}'..." -f $installDir)
if ($uaeConfigFiles.Count -gt 0)
{
    foreach($uaeConfigFile in $uaeConfigFiles)
    {
        Write-Output ("- UAE configuration file '{0}'..." -f $uaeConfigFile.FullName)
        
        #PatchWinuaeConfigFile $winuaeConfigFile $a1200KickstartRomFile $workbenchDir $kickstartDir $os39Dir $userPackagesDir

        # install winuae config file, if winuae config directory exists and patch only is not set
        if ($winuaeConfigDir)
        {
            #Copy-Item $winuaeConfigFile -Destination $winuaeConfigDir.FullName -Force
        }
    }
}
else
{
    Write-Output ("- No UAE configuration files detected")
}

# fs-uae configuration
Write-Output ""
Write-Output "FS-UAE configuration"
Write-Output "--------------------"

# get fs-uae config directory from my documents directory
$fsuaeConfigDir = Get-ChildItem -Path ([System.Environment]::GetFolderPath("MyDocuments")) -Recurse | `
    Where-Object { $_.PSIsContainer -and $_.FullName -match 'FS-UAE\\Configurations$' } | `
    Select-Object -First 1

# write fs-uae configuration dir, if it exists
if ($fsuaeConfigDir)
{
    Write-Output ("FS-UAE configuration dir : '{0}'" -f $fsuaeConfigDir.FullName)
}

# get fs-uae config files from install directory
$fsuaeConfigFiles = @()
$fsuaeConfigFiles += Get-ChildItem $installDir -Filter *.fs-uae

# patch and install fs-uae configuration files
Write-Output ("Patching and installing FS-UAE configuration files from '{0}'..." -f $installDir)
if ($fsuaeConfigFiles.Count -gt 0)
{
    foreach($fsuaeConfigFile in $fsuaeConfigFiles)
    {
        Write-Output ("- FS-UAE configuration file '{0}'" -f $fsuaeConfigFile.FullName)
        #PatchFsuaeConfigFile $fsuaeConfigFile $a1200KickstartRomFile $workbenchDir $kickstartDir $os39Dir $userPackagesDir

        # install fs-uae config file, if fs-uae config directory exists and patch only is not set
        if ($fsuaeConfigDir)
        {
            #Copy-Item $fsuaeConfigFile -Destination $fsuaeConfigDir.FullName -Force
        }
    }
    Write-Output ("- Done")
}
else
{
    Write-Output ("- No FS-UAE configuration files detected")
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