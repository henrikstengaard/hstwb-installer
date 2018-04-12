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


# write text lines for amiga with iso 8859-1 character set encoding
function WriteTextLinesForAmiga($path, $lines)
{
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
	$utf8 = [System.Text.Encoding]::UTF8;

	$amigaTextBytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $utf8.GetBytes($lines -join "`n"))
	[System.IO.File]::WriteAllText($path, $iso88591.GetString($amigaTextBytes), $iso88591)
}


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
        [array]$eabWhdLoadEntries,
        [Parameter(Mandatory=$true)]
        [string]$title,
        [Parameter(Mandatory=$true)]
        [string]$installDir
    )

    $languageIndex = @{}
    $hardwareIndex = @{}

    foreach($eabWhdLoadEntry in $eabWhdLoadEntries)
    {
        if ($hardwareIndex[$eabWhdLoadEntry.Hardware])
        {
            $hardwareIndex[$eabWhdLoadEntry.Hardware]++;
        }
        else
        {
            $hardwareIndex[$eabWhdLoadEntry.Hardware] = 1;
        }

        if (!$languageIndex[$eabWhdLoadEntry.Language])
        {
            $languageIndex[$eabWhdLoadEntry.Language] = @{}
        }
        
        if ($languageIndex[$eabWhdLoadEntry.Language][$eabWhdLoadEntry.Hardware])
        {
            $languageIndex[$eabWhdLoadEntry.Language][$eabWhdLoadEntry.Hardware]++;
        }
        else
        {
            $languageIndex[$eabWhdLoadEntry.Language][$eabWhdLoadEntry.Hardware] = 1;
        }
    }

    
    $hardwares = @()
    $hardwares += $hardwareIndex.keys | Sort-Object

    $languages = @()
    $languages += $languageIndex.keys | Sort-Object
    
    $eabWhdLoadInstallLines = New-Object System.Collections.Generic.List[System.Object]

    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; reset")

    foreach($hardware in $hardwares)
    {
        $eabWhdLoadInstallLines.Add("set eabhardware{0} ""1""" -f $hardware)
    }

    foreach($language in $languages)
    {
        $eabWhdLoadInstallLines.Add("set eablanguage{0} ""1""" -f $language)
    }
    
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; eab whdload menu")
    $eabWhdLoadInstallLines.Add("LAB eabwhdloadmenu")
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("set totalcount ""0""")
    $eabWhdLoadInstallLines.Add("echo """" NOLINE >T:_eabwhdloadmenu")

    foreach($hardware in $hardwares)
    {
        $eabWhdLoadInstallLines.Add("")
        $eabWhdLoadInstallLines.Add("; '{0}' hardware menu" -f $hardware)

        $eabWhdLoadInstallLines.Add("IF ""`$eabhardware{0}"" EQ 1 VAL" -f $hardware)
        $eabWhdLoadInstallLines.Add("  echo ""Install"" NOLINE >>T:_eabwhdloadmenu")
        $eabWhdLoadInstallLines.Add("ELSE")
        $eabWhdLoadInstallLines.Add("  echo ""Skip   "" NOLINE >>T:_eabwhdloadmenu")
        $eabWhdLoadInstallLines.Add("ENDIF")
        $eabWhdLoadInstallLines.Add(("echo "" : {0} hardware ({1} entries)"" >>T:_eabwhdloadmenu" -f $hardware.ToUpper(), $hardwareIndex[$hardware]))
    }

    $eabWhdLoadInstallLines.Add("echo ""----------------------------------------"" >>T:_eabwhdloadmenu")
    
    foreach($language in $languages)
    {
        $eabWhdLoadInstallLines.Add("")
        $eabWhdLoadInstallLines.Add("; '{0}' language menu" -f $language)

        $eabWhdLoadInstallLines.Add("set languagecount ""0""")

        foreach($hardware in $languageIndex[$language].keys)
        {
            $eabWhdLoadInstallLines.Add("IF ""`$eabhardware{0}"" EQ 1 VAL" -f $hardware)
            $eabWhdLoadInstallLines.Add("  set languagecount ``eval `$languagecount + {0}``" -f $languageIndex[$language][$hardware])
            $eabWhdLoadInstallLines.Add("ENDIF")
        }

        $eabWhdLoadInstallLines.Add("IF ""`$eablanguage{0}"" EQ 1 VAL" -f $language)
        $eabWhdLoadInstallLines.Add("  set totalcount ``eval `$totalcount + `$languagecount``")
        $eabWhdLoadInstallLines.Add("  echo ""Install"" NOLINE >>T:_eabwhdloadmenu")
        $eabWhdLoadInstallLines.Add("ELSE")
        $eabWhdLoadInstallLines.Add("  echo ""Skip   "" NOLINE >>T:_eabwhdloadmenu")
        $eabWhdLoadInstallLines.Add("ENDIF")
        $eabWhdLoadInstallLines.Add("echo "" : {0} language (`$languagecount entries)"" >>T:_eabwhdloadmenu" -f $language.ToUpper())
    }

    $eabWhdLoadInstallLines.Add("echo ""----------------------------------------"" >>T:_eabwhdloadmenu")
    $eabWhdLoadInstallLines.Add("echo ""Install `$totalcount of {0} entries"" >>T:_eabwhdloadmenu" -f $eabWhdLoadEntries.Count)
    $eabWhdLoadInstallLines.Add("echo ""Skip all entries"" >>T:_eabwhdloadmenu")
    
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("set eabwhdloadoption """"")
    $eabWhdLoadInstallLines.Add("set eabwhdloadoption ""``RequestList TITLE=""{0}"" LISTFILE=""T:_eabwhdloadmenu"" WIDTH=640 LINES=24``""" -f $title)
    $eabWhdLoadInstallLines.Add("delete >NIL: T:_eabwhdloadmenu")

    $eabWhdloadOption = 0;

    foreach($hardware in $hardwares)
    {
        $eabWhdloadOption++

        $eabWhdLoadInstallLines.Add("")
        $eabWhdLoadInstallLines.Add("; '{0}' hardware option" -f $hardware)
        $eabWhdLoadInstallLines.Add("IF ""`$eabwhdloadoption"" EQ {0} VAL" -f $eabWhdloadOption)
        $eabWhdLoadInstallLines.Add("  IF ""`$eabhardware{0}"" EQ 1 VAL" -f $hardware)
        $eabWhdLoadInstallLines.Add("    set eabhardware{0} ""0""" -f $hardware)
        $eabWhdLoadInstallLines.Add("  ELSE")
        $eabWhdLoadInstallLines.Add("    set eabhardware{0} ""1""" -f $hardware)
        $eabWhdLoadInstallLines.Add("  ENDIF")
        $eabWhdLoadInstallLines.Add("  SKIP BACK eabwhdloadmenu")
        $eabWhdLoadInstallLines.Add("ENDIF")
    }

    $eabWhdloadOption++
    
    foreach($language in $languages)
    {
        $eabWhdloadOption++

        $eabWhdLoadInstallLines.Add("")
        $eabWhdLoadInstallLines.Add("; '{0}' language option" -f $language)
        $eabWhdLoadInstallLines.Add("IF ""`$eabwhdloadoption"" EQ {0} VAL" -f $eabWhdloadOption)
        $eabWhdLoadInstallLines.Add("  IF ""`$eablanguage{0}"" EQ 1 VAL" -f $language)
        $eabWhdLoadInstallLines.Add("    set eablanguage{0} ""0""" -f $language)
        $eabWhdLoadInstallLines.Add("  ELSE")
        $eabWhdLoadInstallLines.Add("    set eablanguage{0} ""1""" -f $language)
        $eabWhdLoadInstallLines.Add("  ENDIF")
        $eabWhdLoadInstallLines.Add("  SKIP BACK eabwhdloadmenu")
        $eabWhdLoadInstallLines.Add("ENDIF")
    }

    $eabWhdloadOption += 2

    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; Install entries option")
    $eabWhdLoadInstallLines.Add("IF ""`$eabwhdloadoption"" EQ {0} VAL" -f $eabWhdloadOption)
    $eabWhdLoadInstallLines.Add("  set confirm ``RequestChoice ""Install EAB WHDLoad"" ""Do you want to install `$totalcount EAB EHDLoad entries?"" ""Yes|No""``")
    $eabWhdLoadInstallLines.Add("  IF ""`$confirm"" EQ ""1""")
    $eabWhdLoadInstallLines.Add("    SKIP installentries")
    $eabWhdLoadInstallLines.Add("  ENDIF")
    $eabWhdLoadInstallLines.Add("ENDIF")

    $eabWhdloadOption++

    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; Skip all entries option")
    $eabWhdLoadInstallLines.Add("IF ""`$eabwhdloadoption"" EQ {0} VAL" -f $eabWhdloadOption)
    $eabWhdLoadInstallLines.Add("  SKIP end")
    $eabWhdLoadInstallLines.Add("ENDIF")

    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("SKIP BACK eabwhdloadmenu")

    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; install entries")
    $eabWhdLoadInstallLines.Add("LAB installentries")
    
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; End")
    $eabWhdLoadInstallLines.Add("; ---")
    $eabWhdLoadInstallLines.Add("LAB end")

    $eabWhdLoadInstallFile = Join-Path $installDir -ChildPath "EAB-WHDLoad-Install"
    WriteTextLinesForAmiga $eabWhdLoadInstallFile $eabWhdLoadInstallLines.ToArray()
    

    foreach($eabWhdLoadEntry in $eabWhdLoadEntries)
    {
        $eabWhdLoadInstallLines.Add(("; {0}, {1}" -f $eabWhdLoadEntry.Language, $eabWhdLoadEntry.Hardware))
        
        $eabWhdLoadFile = "EABWHDLOADDIR:{0}" -f $eabWhdLoadEntry.EabWhdLoadFile.Replace("\", "/")
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
}


# get eab whdload pack directories
$eabWhdLoadPackDirs = @()
$eabWhdLoadPackDirs += Get-ChildItem -Path $eabWhdLoadPacksDir | `
    Where-Object { $_.PSIsContainer -and $_ -match 'whdload' }

foreach($eabWhdLoadPackDir in $eabWhdLoadPackDirs)
{
    Write-Output $eabWhdLoadPackDir.FullName

    $eabWhdloadEntries = @()
    $eabWhdloadEntries += FindEabWhdloadEntries $eabWhdLoadPackDir.FullName

    BuildEabWhdloadInstall $eabWhdloadEntries $eabWhdLoadPackDir.Name $eabWhdLoadPacksDir
}