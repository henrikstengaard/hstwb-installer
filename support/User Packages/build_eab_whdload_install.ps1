# Build EAB WHDLoad Install
# -------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-04-13
#
# A powershell script to build EAB WHDLoad Packs install script for HstWB Installer user packages.


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
    $files += Get-ChildItem -Path $eabWhdLoadPackDir -Recurse -Include *.lha, *.lzx | Sort-Object @{expression={$_.FullName};Ascending=$true}
    
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


# build eab whdload install
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

    $eabWhdLoadInstallLines.Add("; {0}" -f $title)
    $eabWhdLoadInstallLines.Add(("; {0}" -f ("-" * $title.Length)))
    $eabWhdLoadInstallLines.Add("; Author: Henrik Noerfjand Stengaard")
    $eabWhdLoadInstallLines.Add("; Date: {0}" -f (Get-Date -format "yyyy-MM-dd"))
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; An AmigaDOS script for installing EAB WHDLoad pack '{0}'" -f $title)
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; Patch for HstWB Installer without unlzx")
    $eabWhdLoadInstallLines.Add("IF EXISTS ""USERPACKAGEDIR:unlzx""")
    $eabWhdLoadInstallLines.Add("  IF NOT EXISTS ""C:unlzx""")
    $eabWhdLoadInstallLines.Add("    Copy ""USERPACKAGEDIR:unlzx"" ""C:unlzx"" >NIL:")
    $eabWhdLoadInstallLines.Add("  ENDIF")
    $eabWhdLoadInstallLines.Add("ENDIF")
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
    $eabWhdLoadInstallLines.Add("; install entries option")
    $eabWhdLoadInstallLines.Add("IF ""`$eabwhdloadoption"" EQ {0} VAL" -f $eabWhdloadOption)
    $eabWhdLoadInstallLines.Add("  set confirm ``RequestChoice ""Install EAB WHDLoad"" ""Do you want to install `$totalcount EAB EHDLoad entries?"" ""Yes|No""``")
    $eabWhdLoadInstallLines.Add("  IF ""`$confirm"" EQ ""1""")
    $eabWhdLoadInstallLines.Add("    SKIP installentries")
    $eabWhdLoadInstallLines.Add("  ENDIF")
    $eabWhdLoadInstallLines.Add("ENDIF")

    $eabWhdloadOption++

    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; skip all entries option")
    $eabWhdLoadInstallLines.Add("IF ""`$eabwhdloadoption"" EQ {0} VAL" -f $eabWhdloadOption)
    $eabWhdLoadInstallLines.Add("  set confirm ``RequestChoice ""Skip all entries"" ""Do you want to skip all entries?"" ""Yes|No""``")
    $eabWhdLoadInstallLines.Add("  IF ""`$confirm"" EQ ""1""")
    $eabWhdLoadInstallLines.Add("    SKIP end")
    $eabWhdLoadInstallLines.Add("  ENDIF")
    $eabWhdLoadInstallLines.Add("ENDIF")
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("SKIP BACK eabwhdloadmenu")
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; install entries")
    $eabWhdLoadInstallLines.Add("LAB installentries")
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("echo ""*e[1mInstalling entries to '`$INSTALLDIR'*e[0m""")
    $eabWhdLoadInstallLines.Add("execute ""USERPACKAGEDIR:Install/Install-Entries""")
    $eabWhdLoadInstallLines.Add("echo ""Done""")
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; End")
    $eabWhdLoadInstallLines.Add("; ---")
    $eabWhdLoadInstallLines.Add("LAB end")
    $eabWhdLoadInstallLines.Add("")

    $eabWhdLoadInstallFile = Join-Path $installDir -ChildPath "_install"
    WriteTextLinesForAmiga $eabWhdLoadInstallFile $eabWhdLoadInstallLines.ToArray()



    $eabWhdLoadInstallDir = Join-Path $installDir -ChildPath "Install"

    # create eab whdload install directory, if it doesn't exist
    if (!(Test-Path -Path $eabWhdLoadInstallDir))
    {
        mkdir -Path $eabWhdLoadInstallDir | Out-Null
    }


    $eabWhdLoadInstallEntriesDir = Join-Path $eabWhdLoadInstallDir -ChildPath "Entries"

    # create eab whdload install entries directory, if it doesn't exist
    if (!(Test-Path -Path $eabWhdLoadInstallEntriesDir))
    {
        mkdir -Path $eabWhdLoadInstallEntriesDir | Out-Null
    }


    $eabWhdLoadInstallEntryIndex = @{}
    $eabWhdLoadInstallEntryFileIndex = @{}

    foreach($eabWhdLoadEntry in $eabWhdLoadEntries)
    {
        $indexName = $eabWhdLoadEntry.EabWhdLoadFile.Substring(0,1).ToUpper()
        $hardware = $eabWhdLoadEntry.Hardware
        $language = $eabWhdLoadEntry.Language

        $eabWhdLoadInstallEntryFile = "{0}-{1}-{2}" -f $indexName, $hardware.ToUpper(), $language.ToUpper()
        
        if (!$eabWhdLoadInstallEntryIndex.ContainsKey($indexName))
        {
            $eabWhdLoadInstallEntryIndex[$indexName] = @{}
        }

        if (!$eabWhdLoadInstallEntryIndex[$indexName].ContainsKey($hardware))
        {
            $eabWhdLoadInstallEntryIndex[$indexName][$hardware] = @{}
        }

        if (!$eabWhdLoadInstallEntryIndex[$indexName][$hardware].ContainsKey($language))
        {
            $eabWhdLoadInstallEntryIndex[$indexName][$hardware][$language] = $eabWhdLoadInstallEntryFile
        }
        
        if (!$eabWhdLoadInstallEntryFileIndex.ContainsKey($eabWhdLoadInstallEntryFile))
        {
            $eabWhdLoadInstallEntryFileIndex[$eabWhdLoadInstallEntryFile] = `
                New-Object System.Collections.Generic.List[System.Object]
        }
        
        $eabWhdLoadInstallEntryLines = $eabWhdLoadInstallEntryFileIndex[$eabWhdLoadInstallEntryFile]
        
        $eabWhdLoadFile = "USERPACKAGEDIR:{0}" -f $eabWhdLoadEntry.EabWhdLoadFile.Replace("\", "/")
        $eabWhdLoadInstallEntryLines.Add("IF EXISTS ""{0}""" -f $eabWhdLoadFile)

        if ($eabWhdLoadFile -match '\.lha$')
        {
            $eabWhdLoadInstallEntryLines.Add("  lha -q -m1 x ""{0}"" ""`$entrydir/""" -f $eabWhdLoadFile)
        }
        elseif ($eabWhdLoadFile -match '\.lzx$')
        {
            $eabWhdLoadInstallEntryLines.Add("  unlzx -q1 -m e ""{0}"" ""`$entrydir/""" -f $eabWhdLoadFile)
        }

        $eabWhdLoadInstallEntryLines.Add("  IF NOT `$RC EQ 0")
        $eabWhdLoadInstallEntryLines.Add("    echo ""Error: Failed to install entry file '{0}' to '`$entrydir'""" -f $eabWhdLoadFile)
        $eabWhdLoadInstallEntryLines.Add("  ENDIF")
        $eabWhdLoadInstallEntryLines.Add("ENDIF")
    }

    foreach($eabWhdLoadInstallEntryFilename in $eabWhdLoadInstallEntryFileIndex.keys)
    {
        $eabWhdLoadInstallEntryLines = $eabWhdLoadInstallEntryFileIndex[$eabWhdLoadInstallEntryFilename]
        $eabWhdLoadInstallEntryLines.Add("")

        $eabWhdLoadInstallEntryFile = Join-Path $eabWhdLoadInstallEntriesDir -ChildPath $eabWhdLoadInstallEntryFilename
        WriteTextLinesForAmiga $eabWhdLoadInstallEntryFile $eabWhdLoadInstallEntryLines.ToArray()
    }

    $eabWhdLoadInstallEntriesLines = New-Object System.Collections.Generic.List[System.Object]
    
    foreach($indexName in ($eabWhdLoadInstallEntryIndex.Keys | Sort-Object))
    {
        $eabWhdLoadInstallEntriesLines.Add("echo ""Installing {0}...""" -f $indexName)
        $eabWhdLoadInstallEntriesLines.Add("set entrydir ""``execute INSTALLDIR:S/CombinePath ""`$INSTALLDIR"" ""{0}""``" -f $indexName)

        foreach($hardware in ($eabWhdLoadInstallEntryIndex[$indexName].Keys | Sort-Object))
        {
            $eabWhdLoadInstallEntriesLines.Add("IF ""`$eabhardware{0}"" EQ 1 VAL" -f $hardware)

            foreach($language in ($eabWhdLoadInstallEntryIndex[$indexName][$hardware].Keys | Sort-Object))
            {
                $eabWhdLoadInstallEntriesLines.Add("  IF ""`$eablanguage{0}"" EQ 1 VAL" -f $language)
                $eabWhdLoadInstallEntriesLines.Add(("    echo ""Installing {0}, {1}, {2}...""" -f $indexName, $hardware.ToUpper(), $language.ToUpper()))
                $eabWhdLoadInstallEntriesLines.Add("    Execute ""USERPACKAGEDIR:Install/Entries/{0}"" EQ 1 VAL" -f $eabWhdLoadInstallEntryIndex[$indexName][$hardware][$language])
                $eabWhdLoadInstallEntriesLines.Add("  ENDIF")
            }
                
            $eabWhdLoadInstallEntriesLines.Add("ENDIF")
        }
    }

    $eabWhdLoadInstallEntriesLines.Add("")
    
    $eabWhdLoadInstallEntriesFile = Join-Path $eabWhdLoadInstallDir -ChildPath 'Install-Entries'
    WriteTextLinesForAmiga $eabWhdLoadInstallEntriesFile $eabWhdLoadInstallEntriesLines.ToArray()
}


# resolve paths
$eabWhdLoadPacksDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($eabWhdLoadPacksDir)

# write build eab whdload install title
Write-Output "-------------------------"
Write-Output "Build EAB WHDLoad Install"
Write-Output "-------------------------"
Write-Output "Author: Henrik Noerfjand Stengaard"
Write-Output "Date: 2018-04-14"
Write-Output ""
Write-Output ("EAB WHDLoad Packs directory: '{0}'" -f $eabWhdLoadPacksDir)
Write-Output ""
Write-Output "Building EAB WHDLoad Install scripts for user package directories:"

# get eab whdload pack directories
$eabWhdLoadPackDirs = @()
$eabWhdLoadPackDirs += Get-ChildItem -Path $eabWhdLoadPacksDir | `
    Where-Object { $_.PSIsContainer -and $_ -match 'whdload' }

$unlzxFile = Join-Path $eabWhdLoadPacksDir -ChildPath 'unlzx'

if (!(Test-Path $unlzxFile))
{
    throw ("Unlzx file '{0}' doesn't exist" -f $unlzxFile)
}

foreach($eabWhdLoadPackDir in $eabWhdLoadPackDirs)
{
    Write-Output ("- '{0}'" -f $eabWhdLoadPackDir.Name)

    # copy unlzx to eab whdload pack directory
    Copy-Item $unlzxFile $eabWhdLoadPackDir.FullName

    # find eab whdload entries in eab whdload pack directory
    $eabWhdloadEntries = @()
    $eabWhdloadEntries += FindEabWhdloadEntries $eabWhdLoadPackDir.FullName

    # write number of entries found
    Write-Output ("- {0} entries" -f $eabWhdloadEntries.Count)

    # skip eab whdload pack, if it's doesnt contain any entries
    if ($eabWhdloadEntries.Count -eq 0)
    {
        continue
    }

    # build eab whdload install in eab whdload pack directory
    BuildEabWhdloadInstall $eabWhdloadEntries $eabWhdLoadPackDir.Name $eabWhdLoadPackDir.FullName

    # write entries list
    $eabWhdloadEntriesFile = Join-Path -Path $eabWhdLoadPackDir.FullName -ChildPath "entries.csv"
    $eabWhdloadEntries | `
        ForEach-Object { @{ "File" = $_.EabWhdLoadFile; "Hardware" = $_.Hardware; "Language" = $_.Language } } | `
        ForEach-Object{ New-Object PSObject -Property $_ } | `
        export-csv -delimiter ';' -path $eabWhdloadEntriesFile -NoTypeInformation -Encoding UTF8
}

Write-Output "Done"