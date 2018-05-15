# Build Install Entries
# ---------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-05-15
#
# A powershell script to build install entries script for HstWB Installer user packages.


Param(
	[Parameter(Mandatory=$true)]
	[string]$userPackagesDir
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
        [string]$userPackageDir
    )
    
    $files = @()
    $files += Get-ChildItem -Path $userPackageDir -Recurse -Include *.lha, *.lzx | Sort-Object @{expression={$_.FullName};Ascending=$true}
    
    $entries = New-Object System.Collections.Generic.List[System.Object]
    
    foreach ($file in $files)
    {
        $userPackageDirIndex = $userPackageDir.Length + 1
        $userPackageFile = $file.FullName.Substring($userPackageDirIndex, $file.FullName.Length - $userPackageDirIndex)
    
        $entry = ParseEntry $file.Name
        $entry.File = $file.FullName
        $entry.UserPackageFile = $userPackageFile;

        CalculateEntryRank $entry

        $entries.Add($entry)
    }

    return $entries.ToArray()
}


# build install entries
function BuildInstallEntries()
{
    Param(
        [Parameter(Mandatory=$true)]
        [array]$entries,
        [Parameter(Mandatory=$true)]
        [string]$userPackageName,
        [Parameter(Mandatory=$true)]
        [string]$entriesDir
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
    
    # build entries install lines
    $userPackageInstallLines = New-Object System.Collections.Generic.List[System.Object]
    $userPackageInstallLines.Add("; {0}" -f $userPackageName)
    $userPackageInstallLines.Add(("; {0}" -f ("-" * $userPackageName.Length)))
    $userPackageInstallLines.Add("; Author: Henrik Noerfjand Stengaard")
    $userPackageInstallLines.Add("; Date: {0}" -f (Get-Date -format "yyyy-MM-dd"))
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; An AmigaDOS script for installing entries in user package '{0}'" -f $userPackageName)
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; Patch for HstWB Installer without unlzx")
    $userPackageInstallLines.Add("IF NOT EXISTS ""SYS:C/unlzx""")
    $userPackageInstallLines.Add("  IF EXISTS ""USERPACKAGEDIR:unlzx""")
    $userPackageInstallLines.Add("    Copy ""USERPACKAGEDIR:unlzx"" ""SYS:C/unlzx"" >NIL:")
    $userPackageInstallLines.Add("  ENDIF")
    $userPackageInstallLines.Add("ENDIF")
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; reset")

    foreach($hardware in $hardwares)
    {
        $userPackageInstallLines.Add("set entrieshardware{0} ""1""" -f $hardware)
    }

    foreach($language in $languages)
    {
        $userPackageInstallLines.Add("set entrieslanguage{0} ""1""" -f $language)
    }
    
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; entries install menu")
    $userPackageInstallLines.Add("LAB entriesinstallmenu")
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("set totalcount ""0""")
    $userPackageInstallLines.Add("echo """" NOLINE >T:_entriesinstallmenu")

    foreach($hardware in $hardwares)
    {
        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("; '{0}' hardware menu" -f $hardware)

        $userPackageInstallLines.Add("IF ""`$entrieshardware{0}"" EQ 1 VAL" -f $hardware)
        $userPackageInstallLines.Add("  echo ""Install"" NOLINE >>T:_entriesinstallmenu")
        $userPackageInstallLines.Add("ELSE")
        $userPackageInstallLines.Add("  echo ""Skip   "" NOLINE >>T:_entriesinstallmenu")
        $userPackageInstallLines.Add("ENDIF")
        $userPackageInstallLines.Add(("echo "" : {0} hardware ({1} entries)"" >>T:_entriesinstallmenu" -f $hardware.ToUpper(), $hardwareIndex[$hardware]))
    }

    $userPackageInstallLines.Add("echo ""----------------------------------------"" >>T:_entriesinstallmenu")
    
    foreach($language in $languages)
    {
        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("; '{0}' language menu" -f $language)

        $userPackageInstallLines.Add("set languagecount ""0""")

        foreach($hardware in ($languageIndex[$language].keys | Sort-Object))
        {
            $userPackageInstallLines.Add("IF ""`$entrieshardware{0}"" EQ 1 VAL" -f $hardware)
            $userPackageInstallLines.Add("  set languagecount ``eval `$languagecount + {0}``" -f $languageIndex[$language][$hardware])
            $userPackageInstallLines.Add("ENDIF")
        }

        $userPackageInstallLines.Add("IF ""`$entrieslanguage{0}"" EQ 1 VAL" -f $language)
        $userPackageInstallLines.Add("  set totalcount ``eval `$totalcount + `$languagecount``")
        $userPackageInstallLines.Add("  echo ""Install"" NOLINE >>T:_entriesinstallmenu")
        $userPackageInstallLines.Add("ELSE")
        $userPackageInstallLines.Add("  echo ""Skip   "" NOLINE >>T:_entriesinstallmenu")
        $userPackageInstallLines.Add("ENDIF")
        $userPackageInstallLines.Add("echo "" : {0} language (`$languagecount entries)"" >>T:_entriesinstallmenu" -f $language.ToUpper())
    }

    $userPackageInstallLines.Add("echo ""----------------------------------------"" >>T:_entriesinstallmenu")
    $userPackageInstallLines.Add("echo ""Install `$totalcount of {0} entries"" >>T:_entriesinstallmenu" -f $entries.Count)
    $userPackageInstallLines.Add("echo ""Skip all entries"" >>T:_entriesinstallmenu")
    
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("set entriesinstalloption """"")
    $userPackageInstallLines.Add("set entriesinstalloption ``RequestList TITLE=""{0}"" LISTFILE=""T:_entriesinstallmenu"" WIDTH=640 LINES=24``" -f $userPackageName)
    $userPackageInstallLines.Add("delete >NIL: T:_entriesinstallmenu")

    $entriesinstalloption = 0;

    foreach($hardware in $hardwares)
    {
        $entriesinstalloption++

        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("; '{0}' hardware option" -f $hardware)
        $userPackageInstallLines.Add("IF ""`$entriesinstalloption"" EQ {0} VAL" -f $entriesinstalloption)
        $userPackageInstallLines.Add("  IF ""`$entrieshardware{0}"" EQ 1 VAL" -f $hardware)
        $userPackageInstallLines.Add("    set entrieshardware{0} ""0""" -f $hardware)
        $userPackageInstallLines.Add("  ELSE")
        $userPackageInstallLines.Add("    set entrieshardware{0} ""1""" -f $hardware)
        $userPackageInstallLines.Add("  ENDIF")
        $userPackageInstallLines.Add("  SKIP BACK entriesinstallmenu")
        $userPackageInstallLines.Add("ENDIF")
    }

    $entriesinstalloption++
    
    foreach($language in $languages)
    {
        $entriesinstalloption++

        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("; '{0}' language option" -f $language)
        $userPackageInstallLines.Add("IF ""`$entriesinstalloption"" EQ {0} VAL" -f $entriesinstalloption)
        $userPackageInstallLines.Add("  IF ""`$entrieslanguage{0}"" EQ 1 VAL" -f $language)
        $userPackageInstallLines.Add("    set entrieslanguage{0} ""0""" -f $language)
        $userPackageInstallLines.Add("  ELSE")
        $userPackageInstallLines.Add("    set entrieslanguage{0} ""1""" -f $language)
        $userPackageInstallLines.Add("  ENDIF")
        $userPackageInstallLines.Add("  SKIP BACK entriesinstallmenu")
        $userPackageInstallLines.Add("ENDIF")
    }

    $entriesinstalloption += 2

    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; install entries option")
    $userPackageInstallLines.Add("IF ""`$entriesinstalloption"" EQ {0} VAL" -f $entriesinstalloption)
    $userPackageInstallLines.Add("  set confirm ``RequestChoice ""Install entries"" ""Do you want to install `$totalcount entries?"" ""Yes|No""``")
    $userPackageInstallLines.Add("  IF ""`$confirm"" EQ ""1""")
    $userPackageInstallLines.Add("    SKIP installentries")
    $userPackageInstallLines.Add("  ENDIF")
    $userPackageInstallLines.Add("ENDIF")

    $entriesinstalloption++

    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; skip all entries option")
    $userPackageInstallLines.Add("IF ""`$entriesinstalloption"" EQ {0} VAL" -f $entriesinstalloption)
    $userPackageInstallLines.Add("  set confirm ``RequestChoice ""Skip all entries"" ""Do you want to skip all entries?"" ""Yes|No""``")
    $userPackageInstallLines.Add("  IF ""`$confirm"" EQ ""1""")
    $userPackageInstallLines.Add("    SKIP end")
    $userPackageInstallLines.Add("  ENDIF")
    $userPackageInstallLines.Add("ENDIF")
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("SKIP BACK entriesinstallmenu")
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; install entries")
    $userPackageInstallLines.Add("LAB installentries")
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("execute ""USERPACKAGEDIR:Install/Install-Entries""")
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; End")
    $userPackageInstallLines.Add("; ---")
    $userPackageInstallLines.Add("LAB end")
    $userPackageInstallLines.Add("")

    # write user package install file
    $userPackageInstallFile = Join-Path $entriesDir -ChildPath "_install"
    WriteTextLinesForAmiga $userPackageInstallFile $userPackageInstallLines.ToArray()

    # create entries install directory, if it doesn't exist
    $entriesInstallDir = Join-Path $entriesDir -ChildPath "Install"
    if (!(Test-Path -Path $entriesInstallDir))
    {
        mkdir -Path $entriesInstallDir | Out-Null
    }

    # create install entries directory, if it doesn't exist
    $installEntriesDir = Join-Path $entriesInstallDir -ChildPath "Entries"
    if (!(Test-Path -Path $installEntriesDir))
    {
        mkdir -Path $installEntriesDir | Out-Null
    }

    # build install entry and filename indexes
    $installEntryFilenameIndex = @{}
    $installEntryLinesIndex = @{}
    foreach($entry in $entries)
    {
        $entryFilename = Split-Path $entry.UserPackageFile -Leaf
        $indexName = GetIndexName $entryFilename
        $hardware = $entry.Hardware | Select-Object -First 1
        $language = $entry.Language | Select-Object -First 1

        $installEntryFilename = "{0}-{1}-{2}" -f $indexName, $hardware.ToUpper(), $language.ToUpper()
        
        if (!$installEntryFilenameIndex.ContainsKey($indexName))
        {
            $installEntryFilenameIndex[$indexName] = @{}
        }

        if (!$installEntryFilenameIndex[$indexName].ContainsKey($hardware))
        {
            $installEntryFilenameIndex[$indexName][$hardware] = @{}
        }

        if (!$installEntryFilenameIndex[$indexName][$hardware].ContainsKey($language))
        {
            $installEntryFilenameIndex[$indexName][$hardware][$language] = $installEntryFilename
        }
        
        if (!$installEntryLinesIndex.ContainsKey($installEntryFilename))
        {
            $installEntryLinesIndex[$installEntryFilename] = `
                New-Object System.Collections.Generic.List[System.Object]
        }
        
        $installEntryLines = $installEntryLinesIndex[$installEntryFilename]
        
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

    # write install entry lines files
    foreach($installEntryFilename in $installEntryLinesIndex.keys)
    {
        $installEntryLines = $installEntryLinesIndex[$installEntryFilename]
        $installEntryLines.Add("")

        $installEntryFile = Join-Path $installEntriesDir -ChildPath $installEntryFilename
        WriteTextLinesForAmiga $installEntryFile $installEntryLines.ToArray()
    }

    # write main install entries file
    $mainInstallEntriesLines = New-Object System.Collections.Generic.List[System.Object]
    foreach($indexName in ($installEntryFilenameIndex.Keys | Sort-Object))
    {
        $mainInstallEntriesLines.Add("set entrydir ""``execute INSTALLDIR:S/CombinePath ""`$INSTALLDIR"" ""{0}""``""" -f $indexName)
        $mainInstallEntriesLines.Add("IF NOT EXISTS ""`$entrydir""")
        $mainInstallEntriesLines.Add("  MakePath ""`$entrydir"" >NIL:")
        $mainInstallEntriesLines.Add("ENDIF")

        foreach($hardware in ($installEntryFilenameIndex[$indexName].Keys | Sort-Object))
        {
            $mainInstallEntriesLines.Add("IF ""`$entrieshardware{0}"" EQ 1 VAL" -f $hardware)

            foreach($language in ($installEntryFilenameIndex[$indexName][$hardware].Keys | Sort-Object))
            {
                $mainInstallEntriesLines.Add("  IF ""`$entrieslanguage{0}"" EQ 1 VAL" -f $language)
                $mainInstallEntriesLines.Add(("    echo ""*e[1mInstalling {0}, {1}, {2}...*e[0m""" -f $indexName, $hardware.ToUpper(), $language.ToUpper()))
                $mainInstallEntriesLines.Add("    wait 1")
                $mainInstallEntriesLines.Add("    Execute ""USERPACKAGEDIR:Install/Entries/{0}""" -f $installEntryFilenameIndex[$indexName][$hardware][$language])
                $mainInstallEntriesLines.Add("  ENDIF")
            }
                
            $mainInstallEntriesLines.Add("ENDIF")
        }
    }

    $mainInstallEntriesLines.Add("")
    
    # write main install entries file
    $mainInstallEntriesFile = Join-Path $entriesInstallDir -ChildPath 'Install-Entries'
    WriteTextLinesForAmiga $mainInstallEntriesFile $mainInstallEntriesLines.ToArray()
}


# write build install entries title
Write-Output "---------------------"
Write-Output "Build Install Entries"
Write-Output "---------------------"
Write-Output "Author: Henrik Noerfjand Stengaard"
Write-Output "Date: 2018-05-15"
Write-Output ""

# resolve paths
$userPackagesDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($userPackagesDir)

# fail, if user packages directory doesn't exist
if (!(Test-Path $userPackagesDir))
{
    throw ("User packages directory '{0}' doesn't exist" -f $userPackagesDir)
}

# write user packages directory
Write-Output ("User packages directory: '{0}'" -f $userPackagesDir)
Write-Output ""
Write-Output "Building install scripts for user package directories:"

# find user package directories
$userPackageDirs = @()
$userPackageDirs += Get-ChildItem -Path $userPackagesDir | Where-Object { $_.PSIsContainer -and (Test-Path (Join-Path $_.FullName -ChildPath '_installdir')) }

# exit, if no user package directories was found
if ($userPackageDirs.Count -eq 0)
{
    Write-Output "No user package directories was not found!"
    exit
}

# unlzx file
$unlzxFile = Join-Path $userPackagesDir -ChildPath 'unlzx'

# build install entries for user package directories
foreach($userPackageDir in $userPackageDirs)
{
    # get user package name
    $userPackageName = $userPackageDir.Name
    Write-Output $userPackageName
    Write-Output '- Finding entries...'

    # find entries in pack directory
    $entries = @()
    $entries += FindEntries $userPackageDir.FullName
    Write-Output ("- Found {0} entries." -f $entries.Count)

    # skip user package, if it's doesnt contain any entries
    if ($entries.Count -eq 0)
    {
        continue
    }

    # copy unlzx to pack directory, if unlzx file exists
    if (Test-Path $unlzxFile)
    {
        Copy-Item $unlzxFile $userPackageDir.FullName
    }

    # build install entries in user package directory
    Write-Output ("- Building install entries...")
    BuildInstallEntries $entries $userPackageName $userPackageDir.FullName

    # write entries list
    $entriesFile = Join-Path -Path $userPackageDir.FullName -ChildPath "entries.csv"
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