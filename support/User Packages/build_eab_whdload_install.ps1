# Build EAB WHDLoad Install
# -------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-05-15
#
# A powershell script to build EAB WHDLoad Packs install script for HstWB Installer user packages.


Param(
	[Parameter(Mandatory=$true)]
	[string]$eabWhdLoadPacksDir
)


# get index name from first character in name
function GetIndexName($name)
{
    if (!$name -or $name -match '^\s*$')
    {
        return "_";
    }
	elseif ($name -match '^(#|\d)')
	{
        return "0-9"
	}

	return $name.Substring(0,1).ToUpper()
}

# write text lines for amiga with iso 8859-1 character set encoding
function WriteTextLinesForAmiga($path, $lines)
{
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
	$utf8 = [System.Text.Encoding]::UTF8;

	$amigaTextBytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $utf8.GetBytes($lines -join "`n"))
	[System.IO.File]::WriteAllText($path, $iso88591.GetString($amigaTextBytes), $iso88591)
}

# parse entry
function ParseEntry()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$entryName
    )

    # patterns for parsing entry name
    $idPattern = '([_&])(\d{4})$'
    $hardwarePattern = '_(CD32|AGA|CDTV|CD)$'
    $languagePattern = '_?(En|De|Fr|It|Se|Pl|Es|Cz|Dk|Fi|Gr|CV|German|Spanish)$'
    $memoryPattern = '_?(Slow|Fast|LowMem|Chip|1MB|1Mb|2MB|15MB|512k|512K|512kb|512Kb|512KB)$'
    $releasePattern = '_?(Rolling|Playable|Demo\d?|Demos|Preview|DemoLatest|DemoPlay|DemoRoll|Prerelease|BETA)$'
    $publisherDeveloperPattern = '_?(CoreDesign|Paradox|Rowan|Ratsoft|Spotlight|Empire|Impressions|Arcane|Mirrorsoft|Infogrames|Cinemaware|System3|Mindscape|MicroValue|Ocean|MicroIllusions|DesktopDynamite|Infacto|Team17|ElectronicZoo|ReLINE|USGold|Epyx|Psygnosis|Palace|Kaiko|Audios|Sega|Activision|Arcadia|AmigaPower|AmigaFormat|AmigaAction|CUAmiga|TheOne)$'
    $otherPattern = '_?(A1200Version|NONAGA|HardNHeavyHack|[Ff]ix_by_[^_]+|[Hh]ack_by_[^_]+|AmigaStar|QuattroFighters|QuattroArcade|EarlyBuild|Oracle|Nomad|DOS|HighDensity|CompilationArcadeAction|_DizzyCollection|EasyPlay|Repacked|F1Licenceware|Alt|AltLevels|NoSpeech|NoMusic|NoSounds|NoVoice|NoMovie|Fix|Fixed|Aminet|ComicRelief|Util|Files|Image\d?|68060|060|Intro|NoIntro|NTSC|Censored|Kick31|Kick13|\dDisk|\(EasyPlay\)|Kernal1.1|Kernal_Version_1.1|Cracked|HiRes|LoRes|Crunched|Decrunched)$'
    $versionPattern = '_?[Vv]((\d+|\d+\.\d+|\d+\.\d+[\._]\d+)([\.\-_])?[a-zA-Z]?\d*)$'
    $unsupportedPattern = '[\.\-_](.*)$'

    # lists with parsing results
	$idList = New-Object System.Collections.Generic.List[System.Object]
	$hardwareList = New-Object System.Collections.Generic.List[System.Object]
	$languageList = New-Object System.Collections.Generic.List[System.Object]
	$memoryList = New-Object System.Collections.Generic.List[System.Object]
	$releaseList = New-Object System.Collections.Generic.List[System.Object]
	$publisherDeveloperList = New-Object System.Collections.Generic.List[System.Object]
	$otherList = New-Object System.Collections.Generic.List[System.Object]
	$versionList = New-Object System.Collections.Generic.List[System.Object]
	$unsupportedList = New-Object System.Collections.Generic.List[System.Object]

    # set entry name with filename extension
    $entryName = $entryName -replace '\.(lha|lzx)$', ''

    # parse id, hardware, language, memory, demo, publisher/developer, other and version and unsupported from entry name
    do
	{
        $patternMatch = $false

        # parse id from entry name
		if ($entryName -cmatch $idPattern)
		{
            $patternMatch = $true
            $id = ($entryName | Select-String -Pattern $idPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[2].Value } | Select-Object -First 1)
			$idList.Add($id.ToLower())
			$entryName = $entryName -creplace $idPattern, ''
            continue
		}

        # parse hardware from entry name
		if ($entryName -cmatch $hardwarePattern)
		{
            $patternMatch = $true
            $hardware = ($entryName | Select-String -Pattern $hardwarePattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
			$hardwareList.Add($hardware.ToLower())
			$entryName = $entryName -creplace $hardwarePattern, ''
            continue
		}

        # parse language from entry name
		if ($entryName -cmatch $languagePattern)
		{
            $patternMatch = $true
			$language = ($entryName | Select-String -Pattern $languagePattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)

			if ($language -notmatch 'En')
			{
                if ($language -match 'german')
                {
                    $language = 'De'
                }
                elseif ($language -match 'spanish')
                {
                    $language = 'Es'
                }

				$languageList.Add($language.ToLower())
			}

			$entryName = $entryName -creplace $languagePattern, ''
            continue
		}

        # parse memory from entry name
		if ($entryName -cmatch $memoryPattern)
		{
            $patternMatch = $true
            $memory = ($entryName | Select-String -Pattern $memoryPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
			$memoryList.Add($memory.ToLower())
			$entryName = $entryName -creplace $memoryPattern, ''
            continue
		}
        
        # parse release from entry name
		if ($entryName -cmatch $releasePattern)
		{
            $patternMatch = $true
            $demo = ($entryName | Select-String -Pattern $releasePattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
			$releaseList.Add($demo.ToLower())
			$entryName = $entryName -creplace $releasePattern, ''
            continue
		}

        # parse developer publisher from entry name
		if ($entryName -cmatch $publisherDeveloperPattern)
		{
            $patternMatch = $true
            $publisherDeveloper = ($entryName | Select-String -Pattern $publisherDeveloperPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
			$publisherDeveloperList.Add($publisherDeveloper.ToLower())
			$entryName = $entryName -creplace $publisherDeveloperPattern, ''
            continue
		}
        
        # parse other from entry name
		if ($entryName -cmatch $otherPattern)
		{
            $patternMatch = $true
            $other = ($entryName | Select-String -Pattern $otherPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1) 
            $otherList.Add($other.ToLower())
            $entryName = $entryName -creplace $otherPattern, ''
            continue
		}

        # parse version from entry name
		if ($entryName -cmatch $versionPattern)
		{
            $patternMatch = $true
            $version = ($entryName | Select-String -Pattern $versionPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
			$versionList.Add($version.ToLower())
			$entryName = $entryName -creplace $versionPattern, ''
            continue
        }
        
        # parse unsupported from entry name
        if ($entryName -match $unsupportedPattern)
        {
            $patternMatch = $true
            $unsupported = ($entryName | Select-String -Pattern $unsupportedPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
            $unsupportedList.Add($unsupported.ToLower())
            $entryName = $entryName -replace $unsupportedPattern, ''
            continue
        } 
	} while ($patternMatch)

    # remove ambersand from entry name
	$entryName = $entryName -replace '&$', ''

    # add ocs hardware, if no hardware results exist
    if ($hardwareList.Count -eq 0)
    {
        $hardwareList.Add('ocs')
    }

    # add en language, if no language results exist
    if ($languageList.Count -eq 0)
    {
        $languageList.Add('en')
    }

    return @{
        'Name' = $entryName;
        'Id' = $idList.ToArray();
        'Hardware' = $hardwareList.ToArray();
        'Language' = $languageList.ToArray() | Sort-Object | Get-Unique;
        'Memory' = $memoryList.ToArray();
        'Release' = $releaseList.ToArray();
        'PublisherDeveloper' = $publisherDeveloperList.ToArray();
        'Other' = $otherList.ToArray();
        'Version' = $versionList.ToArray();
        'Unsupported' = $unsupportedList.ToArray();
    }
}


function CalculateEntryRank()
{
    Param(
        [Parameter(Mandatory=$true)]
        [object]$entry
    )

    $normalRank = 100
	$normalRank -= ($entry.Language | Where-Object { $_ -notmatch 'en' }).Count * 10
	$normalRank -= $entry.Release.Count * 10
	$normalRank -= $entry.PublisherDeveloper.Count * 10
	$normalRank -= $entry.Other.Count * 10
	$normalRank -= $entry.Memory.Count * 10

    $lowMemRank = $normalRank

    # get lowest memory
    $lowestMemory = $entry.Memory | `
        Where-Object { $_ -match '^\d+(k|m)b?$' } | `
        ForEach-Object { $_ -replace 'mb$', '000000' -replace '(k|kb)$', '000' } | `
        Select-Object -First 1

    if ($lowestMemory -ge 512000)
    {
        $normalRank -= 10
        $lowMemRank += (10 / ($lowestMemory / 512000)) * 2
    }
    
    if ($entry.Memory -contains 'lowmem')
    {
        $lowMemRank += 10
    }

    if ($entry.Memory -contains 'chip')
    {
        $lowMemRank += 10
    }

    $entry.Rank = @{
        'NormalRank' = $normalRank;
        'LowMemRank' = $lowMemRank
    }
}

# find entries
function FindEntries()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$packDir
    )
    
    $files = @()
    $files += Get-ChildItem -Path $packDir -Recurse -Include *.lha, *.lzx | Sort-Object @{expression={$_.FullName};Ascending=$true}
    
    $entries = New-Object System.Collections.Generic.List[System.Object]
    
    foreach ($file in $files)
    {
        $packDirIndex = $packDir.Length + 1
        $userPackageFile = $file.FullName.Substring($packDirIndex, $file.FullName.Length - $packDirIndex)
    
        $entry = ParseEntry $file.Name
        $entry.File = $file.FullName
        $entry.UserPackageFile = $userPackageFile;

        CalculateEntryRank $entry

        $entries.Add($entry)
    }

    return $entries.ToArray()
}


# build install
function BuildInstall()
{
    Param(
        [Parameter(Mandatory=$true)]
        [array]$entries,
        [Parameter(Mandatory=$true)]
        [string]$title,
        [Parameter(Mandatory=$true)]
        [string]$installDir
    )

    # build hardware and language indexes
    $languageIndex = @{}
    $hardwareIndex = @{}
    foreach($entry in $entries)
    {
        $hardware = $entry.Hardware | Select-Object -First 1
        $language = $entry.Language | Select-Object -First 1

        if ($hardwareIndex[$hardware])
        {
            $hardwareIndex[$hardware]++;
        }
        else
        {
            $hardwareIndex[$hardware] = 1;
        }

        if (!$languageIndex[$language])
        {
            $languageIndex[$language] = @{}
        }
        
        if ($languageIndex[$language][$hardware])
        {
            $languageIndex[$language][$hardware]++;
        }
        else
        {
            $languageIndex[$language][$hardware] = 1;
        }
    }

    # get hardwares and languages sorted
    $hardwares = @()
    $hardwares += $hardwareIndex.keys | Sort-Object
    $languages = @()
    $languages += $languageIndex.keys | Sort-Object
    
    # build eab whdload install lines
    $eabWhdLoadInstallLines = New-Object System.Collections.Generic.List[System.Object]
    $eabWhdLoadInstallLines.Add("; {0}" -f $title)
    $eabWhdLoadInstallLines.Add(("; {0}" -f ("-" * $title.Length)))
    $eabWhdLoadInstallLines.Add("; Author: Henrik Noerfjand Stengaard")
    $eabWhdLoadInstallLines.Add("; Date: {0}" -f (Get-Date -format "yyyy-MM-dd"))
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; An AmigaDOS script for installing EAB WHDLoad pack '{0}'" -f $title)
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; Patch for HstWB Installer without unlzx")
    $eabWhdLoadInstallLines.Add("IF NOT EXISTS ""SYS:C/unlzx""")
    $eabWhdLoadInstallLines.Add("  IF EXISTS ""USERPACKAGEDIR:unlzx""")
    $eabWhdLoadInstallLines.Add("    Copy ""USERPACKAGEDIR:unlzx"" ""SYS:C/unlzx"" >NIL:")
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

        foreach($hardware in ($languageIndex[$language].keys | Sort-Object))
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
    $eabWhdLoadInstallLines.Add("echo ""Install `$totalcount of {0} entries"" >>T:_eabwhdloadmenu" -f $entries.Count)
    $eabWhdLoadInstallLines.Add("echo ""Skip all entries"" >>T:_eabwhdloadmenu")
    
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("set eabwhdloadoption """"")
    $eabWhdLoadInstallLines.Add("set eabwhdloadoption ``RequestList TITLE=""{0}"" LISTFILE=""T:_eabwhdloadmenu"" WIDTH=640 LINES=24``" -f $title)
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
    $eabWhdLoadInstallLines.Add("execute ""USERPACKAGEDIR:Install/Install-Entries""")
    $eabWhdLoadInstallLines.Add("")
    $eabWhdLoadInstallLines.Add("; End")
    $eabWhdLoadInstallLines.Add("; ---")
    $eabWhdLoadInstallLines.Add("LAB end")
    $eabWhdLoadInstallLines.Add("")

    # write eab whdload install file
    $eabWhdLoadInstallFile = Join-Path $installDir -ChildPath "_install"
    WriteTextLinesForAmiga $eabWhdLoadInstallFile $eabWhdLoadInstallLines.ToArray()

    # create eab whdload install directory, if it doesn't exist
    $eabWhdLoadInstallDir = Join-Path $installDir -ChildPath "Install"
    if (!(Test-Path -Path $eabWhdLoadInstallDir))
    {
        mkdir -Path $eabWhdLoadInstallDir | Out-Null
    }

    # create eab whdload install entries directory, if it doesn't exist
    $eabWhdLoadInstallEntriesDir = Join-Path $eabWhdLoadInstallDir -ChildPath "Entries"
    if (!(Test-Path -Path $eabWhdLoadInstallEntriesDir))
    {
        mkdir -Path $eabWhdLoadInstallEntriesDir | Out-Null
    }

    # build eab whdload install entry and file indexes
    $eabWhdLoadInstallEntryIndex = @{}
    $eabWhdLoadInstallEntryFileIndex = @{}
    foreach($entry in $entries)
    {
        $eabWhdloadFilename = Split-Path $entry.UserPackageFile -Leaf
        $indexName = GetIndexName $eabWhdloadFilename
        $hardware = $entry.Hardware | Select-Object -First 1
        $language = $entry.Language | Select-Object -First 1

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
        
        $installEntryLines = $eabWhdLoadInstallEntryFileIndex[$eabWhdLoadInstallEntryFile]
        
        # replace \ with / and espace # with '#
        $userPackageFile = "USERPACKAGEDIR:{0}" -f $entry.UserPackageFile.Replace("\", "/")
        $userPackageFileEscaped = $userPackageFile.Replace("#", "'#")

        # extract entry file
        $installEntryLines.Add("IF EXISTS ""{0}""" -f $userPackageFile)
        if ($userPackageFile -match '\.lha$')
        {
            $installEntryLines.Add(("  lha -m1 x ""{0}"" ""`$entrydir/""" -f $userPackageFileEscaped))
        }
        elseif ($userPackageFile -match '\.lzx$')
        {
            $installEntryLines.Add(("  unlzx -m e ""{0}"" ""`$entrydir/""" -f $userPackageFileEscaped))
        }
        $installEntryLines.Add("ENDIF")
    }

    # write install entry files
    foreach($eabWhdLoadInstallEntryFilename in $eabWhdLoadInstallEntryFileIndex.keys)
    {
        $installEntryLines = $eabWhdLoadInstallEntryFileIndex[$eabWhdLoadInstallEntryFilename]
        $installEntryLines.Add("")

        $eabWhdLoadInstallEntryFile = Join-Path $eabWhdLoadInstallEntriesDir -ChildPath $eabWhdLoadInstallEntryFilename
        WriteTextLinesForAmiga $eabWhdLoadInstallEntryFile $installEntryLines.ToArray()
    }

    # write eab whdload install entries file
    $eabWhdLoadInstallEntriesLines = New-Object System.Collections.Generic.List[System.Object]
    foreach($indexName in ($eabWhdLoadInstallEntryIndex.Keys | Sort-Object))
    {
        $eabWhdLoadInstallEntriesLines.Add("set entrydir ""``execute INSTALLDIR:S/CombinePath ""`$INSTALLDIR"" ""{0}""``""" -f $indexName)
        $eabWhdLoadInstallEntriesLines.Add("IF NOT EXISTS ""`$entrydir""")
        $eabWhdLoadInstallEntriesLines.Add("  MakePath ""`$entrydir"" >NIL:")
        $eabWhdLoadInstallEntriesLines.Add("ENDIF")

        foreach($hardware in ($eabWhdLoadInstallEntryIndex[$indexName].Keys | Sort-Object))
        {
            $eabWhdLoadInstallEntriesLines.Add("IF ""`$eabhardware{0}"" EQ 1 VAL" -f $hardware)

            foreach($language in ($eabWhdLoadInstallEntryIndex[$indexName][$hardware].Keys | Sort-Object))
            {
                $eabWhdLoadInstallEntriesLines.Add("  IF ""`$eablanguage{0}"" EQ 1 VAL" -f $language)
                $eabWhdLoadInstallEntriesLines.Add(("    echo ""*e[1mInstalling {0}, {1}, {2}...*e[0m""" -f $indexName, $hardware.ToUpper(), $language.ToUpper()))
                $eabWhdLoadInstallEntriesLines.Add("    wait 1")
                $eabWhdLoadInstallEntriesLines.Add("    Execute ""USERPACKAGEDIR:Install/Entries/{0}""" -f $eabWhdLoadInstallEntryIndex[$indexName][$hardware][$language])
                $eabWhdLoadInstallEntriesLines.Add("  ENDIF")
            }
                
            $eabWhdLoadInstallEntriesLines.Add("ENDIF")
        }
    }

    $eabWhdLoadInstallEntriesLines.Add("")
    
    $eabWhdLoadInstallEntriesFile = Join-Path $eabWhdLoadInstallDir -ChildPath 'Install-Entries'
    WriteTextLinesForAmiga $eabWhdLoadInstallEntriesFile $eabWhdLoadInstallEntriesLines.ToArray()
}


# write build eab whdload install title
Write-Output "-------------------------"
Write-Output "Build EAB WHDLoad Install"
Write-Output "-------------------------"
Write-Output "Author: Henrik Noerfjand Stengaard"
Write-Output "Date: 2018-05-15"
Write-Output ""

# resolve paths
$eabWhdLoadPacksDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($eabWhdLoadPacksDir)

# fail, if eab whdload packs directory doesn't exist
if (!(Test-Path $eabWhdLoadPacksDir))
{
    throw ("EAB WHDLoad Packs directory '{0}' doesn't exist" -f $eabWhdLoadPacksDir)
}

# write packs directory
Write-Output ("EAB WHDLoad Packs directory: '{0}'" -f $eabWhdLoadPacksDir)
Write-Output ""
Write-Output "Building EAB WHDLoad Install scripts for user package directories:"

# find pack directories
$packDirs = @()
$packDirs += Get-ChildItem -Path $eabWhdLoadPacksDir | Where-Object { $_.PSIsContainer }

# exit, if no pack directories was found
if ($packDirs.Count -eq 0)
{
    Write-Output "No EAB WHDLoad Pack directories was not found!"
    exit
}

# unlzx file
$unlzxFile = Join-Path $eabWhdLoadPacksDir -ChildPath 'unlzx'

# build install for pack directories
foreach($packDir in $packDirs)
{
    # get pack name
    $packName = $packDir.Name
    Write-Output $packName
    Write-Output '- Finding entries...'

    # find entries in pack directory
    $entries = @()
    $entries += FindEntries $packDir.FullName
    Write-Output ("- Found {0} entries." -f $entries.Count)

    # skip pack, if it's doesnt contain any entries
    if ($entries.Count -eq 0)
    {
        continue
    }

    # copy unlzx to pack directory, if unlzx file exists
    if (Test-Path $unlzxFile)
    {
        Copy-Item $unlzxFile $packDir.FullName
    }

    # build install in pack directory
    Write-Output ("- Building EAB WHDLoad Install...")
    BuildInstall $entries $packName $packDir.FullName

    # write entries list
    $entriesFile = Join-Path -Path $packDir.FullName -ChildPath "entries.csv"
    $entries | `
        ForEach-Object { @{ 
            "File" = $_.File;
            "UserPackageFile" = $_.UserPackageFile;
            "Name" = $_.Name;
            "Id" = ($_.Id -join ',');
            "Hardware" = ($_.Hardware -join ',');
            "Language" = ($_.Language -join ',');
            "Memory" = ($_.Memory -join ',');
            "Release" = ($_.Release -join ',');
            "PublisherDeveloper" = ($_.PublisherDeveloper -join ',');
            "Other" = ($_.Other -join ',');
            "Version" = ($_.Version -join ',');
            "Unsupported" = ($_.Unsupported -join ',');
            "NormalRank" = $_.Rank.NormalRank;
            "LowMemRank" = $_.Rank.LowMemRank;
        } } | `
        ForEach-Object{ New-Object PSObject -Property $_ } | `
        export-csv -delimiter ';' -path $entriesFile -NoTypeInformation -Encoding UTF8

    Write-Output ("- Done.")
}