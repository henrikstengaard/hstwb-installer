# Build EAB WHDLoad Install
# -------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-04-12
#
# A powershell script to build EAB WHDLoad Packs install script.


Param(
	[Parameter(Mandatory=$true)]
	[string]$eabWhdLoadPacksDir
)


# find eab whdload entries
function FindEabWhdloadEntries()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$eabWhdLoadPackDir
    )
    
    $files = @()
    $files += Get-ChildItem -Path $eabWhdLoadPackDir -Recurse -Include *.lha, *.lzx
    
    $eabWhdLoadEntries = New-Object System.Collections.Generic.List[System.Object]
    
    foreach ($file in $files)
    {
        $eabWhdLoadPackDirIndex = $eabWhdLoadPackDir.Length + 1
        $eabWhdLoadFile = $file.FullName.Substring($eabWhdLoadPackDirIndex, $file.FullName.Length - $eabWhdLoadPackDirIndex)
    
        $language = $eabWhdLoadFile | Select-String -Pattern "_(de|fr|it|se|pl|es|cz|dk|fi|gr|cv)(_|\.)" -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.ToLower() } | Select-Object -First 1
    
        if (!$language)
        {
            $language = "en"
        }
        
        $hardware = $eabWhdLoadFile | Select-String -Pattern "_(aga|cd32|cdtv)(_|\.)" -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.ToLower() } | Select-Object -First 1
    
        if (!$hardware)
        {
            $hardware = "ocs"
        }

        $eabWhdLoadEntries.Add(@{
            "File" = $file.FullName;
            "EabWhdLoadFile" = $eabWhdLoadFile;
            "Language" = $language;
            "Hardware" = $hardware;
        })
    }

    return $eabWhdLoadEntries.ToArray()
}

function BuildEabWhdloadInstall()
{
    Param(
        [Parameter(Mandatory=$true)]
        [array]$eabWhdLoadEntries
    )
    
    $eabWhdLoadInstallLines = New-Object System.Collections.Generic.List[System.Object]

    foreach($eabWhdLoadEntry in $eabWhdLoadEntries)
    {
        $eabWhdLoadInstallLines.Add(("; {0}, {1}" -f $eabWhdLoadEntry.Language, $eabWhdLoadEntry.Hardware))
        
        $eabWhdLoadFile = "EABWHDLOADDIR:{0}" -f $eabWhdLoadEntry.EabWhdLoadFile
        $eabWhdLoadInstallLines.Add("IF EXISTS ""{0}""" -f $eabWhdLoadFile)
    
        if ($file.FullName -match '\.lha$')
        {
            $eabWhdLoadInstallLines.Add("  lha -m1 x ""{0}"" ""`$INSTALLDIR""" -f $eabWhdLoadFile)
        }
        elseif ($file.FullName -match '\.lzx$')
        {
            $eabWhdLoadInstallLines.Add("  lzx x ""{0}"" ""`$INSTALLDIR""" -f $eabWhdLoadFile)
        }
    
        $eabWhdLoadInstallLines.Add("ENDIF")
    }

    return $eabWhdLoadInstallLines.ToArray()
}

# get eab whdload pack directories
$eabWhdLoadPackDirs = @()
$eabWhdLoadPackDirs += Get-ChildItem -Path $eabWhdLoadPacksDir | `
    Where-Object { $_.PSIsContainer -and $_ -match 'whdload' }

foreach($eabWhdLoadPackDir in $eabWhdLoadPackDirs)
{
    $eabWhdloadEntries = @()
    $eabWhdloadEntries += FindEabWhdloadEntries $eabWhdLoadPackDir.FullName

    $eabWhdloadEntries |Select-Object -First 10
}