# Build Install Entries
# ---------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-05-20
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
    $hardwarePattern = '_(CD32|AGA|CDTV)$'
    $languagePattern = '_?(En|De|Fr|It|Se|Pl|Es|Cz|Dk|Fi|Gr|CV|German|Spanish)$'
    $memoryPattern = '_?(Slow|Fast|LowMem|Chip|1MB|1Mb|2MB|15MB|512k|512K|512kb|512Kb|512KB)$'
    $releasePattern = '_?(Rolling|Playable|Demo\d?|Demos|Preview|DemoLatest|DemoPlay|DemoRoll|Prerelease|BETA)$'
    $publisherDeveloperPattern = '_?(CoreDesign|Paradox|Rowan|Ratsoft|Spotlight|Empire|Impressions|Arcane|Mirrorsoft|Infogrames|Cinemaware|System3|Mindscape|MicroValue|Ocean|MicroIllusions|DesktopDynamite|Infacto|Team17|ElectronicZoo|ReLINE|USGold|Epyx|Psygnosis|Palace|Kaiko|Audios|Sega|Activision|Arcadia|AmigaPower|AmigaFormat|AmigaAction|CUAmiga|TheOne)$'
    $otherPattern = '_?(CD|A1200Version|NONAGA|HardNHeavyHack|[Ff]ix_by_[^_]+|[Hh]ack_by_[^_]+|AmigaStar|QuattroFighters|QuattroArcade|EarlyBuild|Oracle|Nomad|DOS|HighDensity|CompilationArcadeAction|_DizzyCollection|EasyPlay|Repacked|F1Licenceware|Alt|AltLevels|NoSpeech|NoMusic|NoSounds|NoVoice|NoMovie|Fix|Fixed|Aminet|ComicRelief|Util|Files|Image\d?|68060|060|Intro|NoIntro|NTSC|Censored|Kick31|Kick13|\dDisk|\(EasyPlay\)|Kernal1.1|Kernal_Version_1.1|Cracked|HiRes|LoRes|Crunched|Decrunched)$'
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


# calculate best version rank
function CalculateBestVersionRank()
{
    Param(
        [Parameter(Mandatory=$true)]
        [object]$entry
    )

    $rank = 100
	$rank -= ($entry.Language | Where-Object { $_ -notmatch 'en' }).Count * 10
	$rank -= $entry.Release.Count * 10
	$rank -= $entry.PublisherDeveloper.Count * 10
	$rank -= $entry.Other.Count * 10
	$rank -= $entry.Memory.Count * 10

    $lowMemRank = $rank

    # get lowest memory
    $lowestMemory = $entry.Memory | `
        Where-Object { $_ -match '^\d+(k|m)b?$' } | `
        ForEach-Object { $_ -replace 'mb$', '000000' -replace '(k|kb)$', '000' } | `
        Select-Object -First 1

    if ($lowestMemory -ge 512000)
    {
        $rank -= 10
        $lowMemRank += (10 / ($lowestMemory / 512000)) * 2
    }
    
    if ($entry.Memory -contains 'lowmem')
    {
        $lowMemRank += 20
    }

    if ($entry.Memory -contains 'chip')
    {
        $lowMemRank += 20
    }

    $entry.BestVersionRank = $rank
    $entry.BestVersionLowMemRank = $lowMemRank
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

        CalculateBestVersionRank $entry

        $entries.Add($entry)
    }

    return $entries.ToArray()
}

# build entries best version
function BuildEntriesBestVersion()
{
    Param(
        [Parameter(Mandatory=$true)]
        [array]$entries,
        [Parameter(Mandatory=$true)]
        [bool]$lowMem
    )
    
    # build entry versions index
    $entryVersionsIndex = @{}
    foreach ($entry in $entries)
    {
        $languageSet = if ($entry.Language.Count -gt 1) { 'multi' } else { "single-{0}" -f $entry.Language | Select-Object -First 1 }
        $entryVersionId = ("{0}-{1}-{2}" -f $entry.Name, ($entry.Hardware | Select-Object -First 1), $languageSet).ToLower()

        if (!$entryVersionsIndex.ContainsKey($entryVersionId))
        {
            $entryVersionsIndex[$entryVersionId] = New-Object System.Collections.Generic.List[System.Object]
        }

        $entryVersionsIndex[$entryVersionId].Add($entry)
    }

    # build entries best version from highest ranking entry version
    $entriesBestVersion = New-Object System.Collections.Generic.List[System.Object]
    foreach($entryVersionId in $entryVersionsIndex.Keys)
    {
        $entryVersionsSortedByRank = if ($lowMem) { 
            $entryVersionsIndex[$entryVersionId] | Sort-Object @{expression={$_.BestVersionLowMemRank};Ascending=$false}, @{expression={$_.UserPackageFile};Ascending=$true}
        } else {
            $entryVersionsIndex[$entryVersionId] | Sort-Object @{expression={$_.BestVersionRank};Ascending=$false}, @{expression={$_.UserPackageFile};Ascending=$true}
        }

        $entryBestVersion = $entryVersionsSortedByRank | Select-Object -First 1

        $entriesBestVersion.Add($entryBestVersion)
    }

    return $entriesBestVersion | Sort-Object @{expression={$_.UserPackageFile};Ascending=$true}
}

# build user package install
function BuildUserPackageInstall()
{
    Param(
        [Parameter(Mandatory=$true)]
        [array]$entriesSets,
        [Parameter(Mandatory=$true)]
        [string]$userPackageName,
        [Parameter(Mandatory=$true)]
        [string]$entriesDir
    )

    # build hardware and language indexes
    $languageIndex = @{}
    $hardwareIndex = @{}

    foreach($entriesSet in $entriesSets)
    {
        foreach($entry in $entriesSet.Entries)
        {
            $hardware = $entry.Hardware | Select-Object -First 1

            if (!$hardwareIndex[$entriesSet.Name])
            {
                $hardwareIndex[$entriesSet.Name] = @{}
            }
        
            if ($hardwareIndex[$entriesSet.Name][$hardware])
            {
                $hardwareIndex[$entriesSet.Name][$hardware]++;
            }
            else
            {
                $hardwareIndex[$entriesSet.Name][$hardware] = 1;
            }

            $languageSet = if ($entry.Language.Count -gt 1) { 'multi' } else { 'single' }

            foreach($language in $entry.Language)
            {
                if (!$languageIndex[$entriesSet.Name])
                {
                    $languageIndex[$entriesSet.Name] = @{}
                }
                
                if (!$languageIndex[$entriesSet.Name][$languageSet])
                {
                    $languageIndex[$entriesSet.Name][$languageSet] = @{}
                }
                
                if (!$languageIndex[$entriesSet.Name][$languageSet][$language])
                {
                    $languageIndex[$entriesSet.Name][$languageSet][$language] = @{}
                }
                
                if ($languageIndex[$entriesSet.Name][$languageSet][$language][$hardware])
                {
                    $languageIndex[$entriesSet.Name][$languageSet][$language][$hardware]++;
                }
                else
                {
                    $languageIndex[$entriesSet.Name][$languageSet][$language][$hardware] = 1;
                }
            }
        }
    }

    # build entries install lines
    $userPackageInstallLines = New-Object System.Collections.Generic.List[System.Object]
    $userPackageInstallLines.Add("; {0}" -f $userPackageName)
    $userPackageInstallLines.Add(("; {0}" -f ("-" * $userPackageName.Length)))
    $userPackageInstallLines.Add("; Author: Henrik Noerfjand Stengaard")
    $userPackageInstallLines.Add("; Date: {0}" -f (Get-Date -format "yyyy-MM-dd"))
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; An AmigaDOS script for installing entries in user package '{0}' built by Build Install Entries script." -f $userPackageName)
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; Patch for HstWB Installer without unlzx")
    $userPackageInstallLines.Add("IF NOT EXISTS ""SYS:C/unlzx""")
    $userPackageInstallLines.Add("  IF EXISTS ""USERPACKAGEDIR:unlzx""")
    $userPackageInstallLines.Add("    Copy ""USERPACKAGEDIR:unlzx"" ""SYS:C/unlzx"" >NIL:")
    $userPackageInstallLines.Add("  ENDIF")
    $userPackageInstallLines.Add("ENDIF")
    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; reset")

    $userPackageInstallLines.Add("set entriessetid ""1""")

    $allHardwares = @()
    $allHardwares += $hardwareIndex.Keys | ForEach-Object { $hardwareIndex[$_].Keys } | Sort-Object | Get-Unique
    
    foreach($hardware in $allHardwares)
    {
        $userPackageInstallLines.Add("set entrieshardware{0} ""1""" -f $hardware)
    }

    $allLanguages = @()
    $allLanguages += $languageIndex.Keys | ForEach-Object { $languageIndex[$_]["single"].Keys } | Sort-Object | Get-Unique
    
    foreach($language in $allLanguages)
    {
        $userPackageInstallLines.Add("set entrieslanguage{0} ""1""" -f $language)
    }

    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; install entries menu")
    $userPackageInstallLines.Add("LAB installentriesmenu")

    $entriesSetNames = New-Object System.Collections.Generic.List[System.Object]
    $entriesSetDescriptionLines = New-Object System.Collections.Generic.List[System.Object]

    $entriesSetId = 0
    foreach($entriesSet in $entriesSets)
    {
        $entriesSetName = $entriesSet.Name.Replace("-", " ")
        $entriesSetNames.Add($entriesSetName)
        $entriesSetDescriptionLines.Add("{0}:" -f $entriesSetName)
        $entriesSetDescriptionLines.Add("- {0}" -f $entriesSet.Description)
    
        $entriesSetId++
        $userPackageInstallLines.Add("; show entries set '{0}' menu" -f $entriesSetName)
        $userPackageInstallLines.Add("IF ""`$entriessetid"" EQ {0} VAL" -f $entriesSetId)
        $userPackageInstallLines.Add("  SKIP entriesset{0}menu" -f $entriesSetId)
        $userPackageInstallLines.Add("ENDIF")
    }

    $entriesSetId = 0
    foreach($entriesSet in $entriesSets)
    {
        $entriesSetId++
        
        # get hardwares and languages sorted
        $hardwares = @()
        $hardwares += $hardwareIndex[$entriesSet.Name].keys | Sort-Object
        $languages = @()
        $languages += $languageIndex[$entriesSet.Name]["single"].keys | Sort-Object

        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("; entries set '{0}' menu" -f $entriesSet.Name)
        $userPackageInstallLines.Add("LAB entriesset{0}menu" -f $entriesSetId)
        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("set totalcount ""0""")
        $userPackageInstallLines.Add("set totalmulticount ""0""")
        $userPackageInstallLines.Add("echo """" NOLINE >T:_entriessetmenu")
    
        $userPackageInstallLines.Add("echo ""Selected entries set: {0}"" >>T:_entriessetmenu" -f $entriesSet.Name.Replace("-", " "))
        $userPackageInstallLines.Add("echo ""----------------------------------------"" >>T:_entriessetmenu")

        foreach($hardware in $hardwares)
        {
            $userPackageInstallLines.Add("")
            $userPackageInstallLines.Add("; '{0}' hardware menu" -f $hardware)
    
            $userPackageInstallLines.Add("IF ""`$entrieshardware{0}"" EQ 1 VAL" -f $hardware)
            $userPackageInstallLines.Add("  echo ""Install"" NOLINE >>T:_entriessetmenu")
            $userPackageInstallLines.Add("ELSE")
            $userPackageInstallLines.Add("  echo ""Skip   "" NOLINE >>T:_entriessetmenu")
            $userPackageInstallLines.Add("ENDIF")
            $userPackageInstallLines.Add(("echo "" : {0} hardware ({1} entries)"" >>T:_entriessetmenu" -f $hardware.ToUpper(), $hardwareIndex[$entriesSet.Name][$hardware]))
        }
    
        $userPackageInstallLines.Add("echo ""----------------------------------------"" >>T:_entriessetmenu")

        foreach($language in $languages)
        {
            $userPackageInstallLines.Add("")
            $userPackageInstallLines.Add("; '{0}' language menu" -f $language)
    
            $userPackageInstallLines.Add("set languagecount ""0""")
            $userPackageInstallLines.Add("set multicount ""0""")
    
            foreach($hardware in ($languageIndex[$entriesSet.Name]["single"][$language].keys | Sort-Object))
            {
                $userPackageInstallLines.Add("IF ""`$entrieshardware{0}"" EQ 1 VAL" -f $hardware)
                $userPackageInstallLines.Add("  set languagecount ``eval `$languagecount + {0}``" -f $languageIndex[$entriesSet.Name]["single"][$language][$hardware])
    
                if ($languageIndex[$entriesSet.Name].ContainsKey("multi") -and $languageIndex[$entriesSet.Name]["multi"].ContainsKey($language) -and $languageIndex[$entriesSet.Name]["multi"][$language].ContainsKey($hardware))
                {
                    $userPackageInstallLines.Add("  set multicount ``eval `$multicount + {0}``" -f $languageIndex[$entriesSet.Name]["multi"][$language][$hardware])
                }
    
                $userPackageInstallLines.Add("ENDIF")
            }
    
            $userPackageInstallLines.Add("IF ""`$entrieslanguage{0}"" EQ 1 VAL" -f $language)
            $userPackageInstallLines.Add("  set totalcount ``eval `$totalcount + `$languagecount``")
            $userPackageInstallLines.Add("  IF ""`$multicount"" GT ""`$totalmulticount"" VAL")
            $userPackageInstallLines.Add("    set totalmulticount ""`$multicount""")
            $userPackageInstallLines.Add("  ENDIF")
            $userPackageInstallLines.Add("  echo ""Install"" NOLINE >>T:_entriessetmenu")
            $userPackageInstallLines.Add("ELSE")
            $userPackageInstallLines.Add("  echo ""Skip   "" NOLINE >>T:_entriessetmenu")
            $userPackageInstallLines.Add("ENDIF")
            $userPackageInstallLines.Add("echo "" : {0} language (`$languagecount entries"" NOLINE >>T:_entriessetmenu" -f $language.ToUpper())
            $userPackageInstallLines.Add("IF ""`$multicount"" GT 0 VAL")
            $userPackageInstallLines.Add("  echo "", `$multicount multi"" NOLINE >>T:_entriessetmenu")
            $userPackageInstallLines.Add("ENDIF")
            $userPackageInstallLines.Add("echo "")"" >>T:_entriessetmenu")
        }

        $userPackageInstallLines.Add("echo ""----------------------------------------"" >>T:_entriessetmenu")
        $userPackageInstallLines.Add("echo ""Install all entries"" >>T:_entriessetmenu")
        $userPackageInstallLines.Add("echo ""Skip all entries"" >>T:_entriessetmenu")
        $userPackageInstallLines.Add("echo ""Start entries installation (`$totalcount of {0} entries"" NOLINE >>T:_entriessetmenu" -f $entriesSet.Entries.Count)
        $userPackageInstallLines.Add("IF ""`$totalmulticount"" GT 1 VAL")
        $userPackageInstallLines.Add("  echo "", 1-`$totalmulticount multi"" NOLINE >>T:_entriessetmenu")
        $userPackageInstallLines.Add("ENDIF")
        $userPackageInstallLines.Add("IF ""`$totalmulticount"" EQ 1 VAL")
        $userPackageInstallLines.Add("  echo "", 1 multi"" NOLINE >>T:_entriessetmenu")
        $userPackageInstallLines.Add("ENDIF")
        $userPackageInstallLines.Add("echo "")"" >>T:_entriessetmenu")
        $userPackageInstallLines.Add("echo ""Skip entries installation"" >>T:_entriessetmenu")
        
        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("set entriesinstalloption """"")
        $userPackageInstallLines.Add("set entriesinstalloption ``RequestList TITLE=""{0}"" LISTFILE=""T:_entriessetmenu"" WIDTH=640 LINES=24``" -f $userPackageName)
        $userPackageInstallLines.Add("delete >NIL: T:_entriessetmenu")
    
        $entriesInstallOption = 1;

        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("; select entries set option")
        $userPackageInstallLines.Add("IF ""`$entriesinstalloption"" EQ {0} VAL" -f $entriesInstallOption)
        $userPackageInstallLines.Add(("  set entriessetindex ``RequestChoice ""Select entries set"" ""Select entries set to install.*N*N{0}"" ""{1}""``" -f ($entriesSetDescriptionLines -join '*N'), ($entriesSetNames -join '|')))

        for ($i = 1; $i -le $entriesSets.Count; $i++)
        {
            $entriesSetIndex = if ($i -eq $entriesSets.Count) { 0 } else { $i } 
            $userPackageInstallLines.Add("  IF `$entriessetindex EQ {0} VAL" -f $entriesSetIndex)
            $userPackageInstallLines.Add("    set entriessetid ""{0}""" -f $i)
            $userPackageInstallLines.Add("  ENDIF")
        }

        $userPackageInstallLines.Add("  SKIP BACK installentriesmenu")
        $userPackageInstallLines.Add("ENDIF")

        $entriesInstallOption++
        
        foreach($hardware in $hardwares)
        {
            $entriesInstallOption++

            $userPackageInstallLines.Add("")
            $userPackageInstallLines.Add("; '{0}' hardware option" -f $hardware)
            $userPackageInstallLines.Add("IF ""`$entriesinstalloption"" EQ {0} VAL" -f $entriesInstallOption)
            $userPackageInstallLines.Add("  IF ""`$entrieshardware{0}"" EQ 1 VAL" -f $hardware)
            $userPackageInstallLines.Add("    set entrieshardware{0} ""0""" -f $hardware)
            $userPackageInstallLines.Add("  ELSE")
            $userPackageInstallLines.Add("    set entrieshardware{0} ""1""" -f $hardware)
            $userPackageInstallLines.Add("  ENDIF")
            $userPackageInstallLines.Add("  SKIP BACK entriesset{0}menu" -f $entriesSetId)
            $userPackageInstallLines.Add("ENDIF")
        }

        $entriesInstallOption++
        
        foreach($language in $languages)
        {
            $entriesInstallOption++

            $userPackageInstallLines.Add("")
            $userPackageInstallLines.Add("; '{0}' language option" -f $language)
            $userPackageInstallLines.Add("IF ""`$entriesinstalloption"" EQ {0} VAL" -f $entriesInstallOption)
            $userPackageInstallLines.Add("  IF ""`$entrieslanguage{0}"" EQ 1 VAL" -f $language)
            $userPackageInstallLines.Add("    set entrieslanguage{0} ""0""" -f $language)
            $userPackageInstallLines.Add("  ELSE")
            $userPackageInstallLines.Add("    set entrieslanguage{0} ""1""" -f $language)
            $userPackageInstallLines.Add("  ENDIF")
            $userPackageInstallLines.Add("  SKIP BACK entriesset{0}menu" -f $entriesSetId)
            $userPackageInstallLines.Add("ENDIF")
        }

        $entriesInstallOption += 2

        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("; install all entries option")
        $userPackageInstallLines.Add("IF ""`$entriesinstalloption"" EQ {0} VAL" -f $entriesInstallOption)

        foreach($hardware in $allHardwares)
        {
            $userPackageInstallLines.Add("  set entrieshardware{0} ""1""" -f $hardware)
        }

        foreach($language in $allLanguages)
        {
            $userPackageInstallLines.Add("  set entrieslanguage{0} ""1""" -f $language)
        }
            
        $userPackageInstallLines.Add("  SKIP BACK entriesset{0}menu" -f $entriesSetId)
        $userPackageInstallLines.Add("ENDIF")

        $entriesInstallOption++
        
        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("; skip all entries option")
        $userPackageInstallLines.Add("IF ""`$entriesinstalloption"" EQ {0} VAL" -f $entriesInstallOption)

        foreach($hardware in $allHardwares)
        {
            $userPackageInstallLines.Add("  set entrieshardware{0} ""0""" -f $hardware)
        }

        foreach($language in $allLanguages)
        {
            $userPackageInstallLines.Add("  set entrieslanguage{0} ""0""" -f $language)
        }
            
        $userPackageInstallLines.Add("  SKIP BACK entriesset{0}menu" -f $entriesSetId)
        $userPackageInstallLines.Add("ENDIF")

        $entriesInstallOption++
        
        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("; start entries installation option")
        $userPackageInstallLines.Add("IF ""`$entriesinstalloption"" EQ {0} VAL" -f $entriesInstallOption)
        $userPackageInstallLines.Add("  set confirm ``RequestChoice ""Start entries installation"" ""Do you want to entries installation of `$totalcount entries?"" ""Yes|No""``")
        $userPackageInstallLines.Add("  IF ""`$confirm"" EQ ""1""")
        $userPackageInstallLines.Add("    execute ""USERPACKAGEDIR:Install/{0}/Install-Entries""" -f $entriesSet.Name)
        $userPackageInstallLines.Add("    SKIP end")
        $userPackageInstallLines.Add("  ENDIF")
        $userPackageInstallLines.Add("ENDIF")

        $entriesInstallOption++

        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("; skip entries installation option")
        $userPackageInstallLines.Add("IF ""`$entriesinstalloption"" EQ {0} VAL" -f $entriesInstallOption)
        $userPackageInstallLines.Add("  set confirm ``RequestChoice ""Skip entries installation"" ""Do you want to skip entries installation?"" ""Yes|No""``")
        $userPackageInstallLines.Add("  IF ""`$confirm"" EQ ""1""")
        $userPackageInstallLines.Add("    SKIP end")
        $userPackageInstallLines.Add("  ENDIF")
        $userPackageInstallLines.Add("ENDIF")
        $userPackageInstallLines.Add("")
        $userPackageInstallLines.Add("SKIP BACK entriesset{0}menu" -f $entriesSetId)
    }

    $userPackageInstallLines.Add("")
    $userPackageInstallLines.Add("; End")
    $userPackageInstallLines.Add("; ---")
    $userPackageInstallLines.Add("LAB end")
    $userPackageInstallLines.Add("")

    # write user package install file
    $userPackageInstallFile = Join-Path $entriesDir -ChildPath "_install"
    WriteTextLinesForAmiga $userPackageInstallFile $userPackageInstallLines.ToArray()
}

# build install entries
function BuildInstallEntries()
{
    Param(
        [Parameter(Mandatory=$true)]
        [array]$entries,
        [Parameter(Mandatory=$true)]
        [string]$userPackagePath,
        [Parameter(Mandatory=$true)]
        [string]$installEntriesDir
    )
        
    # build install entry and filename indexes
    $installEntryFilenameIndex = @{}
    $installEntryLinesIndex = @{}
    foreach($entry in $entries)
    {
        $entryFilename = Split-Path $entry.UserPackageFile -Leaf
        $indexName = GetIndexName $entryFilename
        $hardware = $entry.Hardware | Select-Object -First 1
        $multiLanguages = $entry.Language.Count -gt 1

        $language = if ($multiLanguages) { "MULTI" } else { $entry.Language | Select-Object -First 1 }

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
        if ($multiLanguages)
        {
            $installEntryLines.Add("set entriesmulti ""0""")

            foreach ($language in $entry.Language)
            {
                $installEntryLines.Add("IF ""`$entrieslanguage{0}"" EQ 1 VAL" -f $language)
                $installEntryLines.Add("  set entriesmulti ""1""")
                $installEntryLines.Add("ENDIF")
            }

            $installEntryLines.Add("IF `$entriesmulti EQ 1 VAL")
        }

        $padding = if ($multiLanguages) { 2 } else { 0 }
        $paddingText = " " * $padding

        $installEntryLines.Add(("{0}IF EXISTS ""{1}""" -f $paddingText, $userPackageFile))
        if ($userPackageFile -match '\.lha$')
        {
            $installEntryLines.Add(("{0}  lha -m1 x ""{1}"" ""`$entrydir/""" -f $paddingText, $userPackageFileEscaped))
        }
        elseif ($userPackageFile -match '\.lzx$')
        {
            $installEntryLines.Add(("{0}  unlzx -m e ""{1}"" ""`$entrydir/""" -f $paddingText, $userPackageFileEscaped))
        }
        $installEntryLines.Add("{0}ENDIF" -f $paddingText)

        if ($multiLanguages)
        {
            $installEntryLines.Add("ENDIF")
        }
    }

    # write install entry lines files
    foreach($installEntryFilename in $installEntryLinesIndex.keys)
    {
        $installEntryLines = $installEntryLinesIndex[$installEntryFilename]
        $installEntryLines.Add("")

        $installEntryFile = Join-Path $installEntriesDir -ChildPath $installEntryFilename
        WriteTextLinesForAmiga $installEntryFile $installEntryLines.ToArray()
    }

    # write install entries file
    $installEntriesLines = New-Object System.Collections.Generic.List[System.Object]
    foreach($indexName in ($installEntryFilenameIndex.Keys | Sort-Object))
    {
        $installEntriesLines.Add("set entrydir ""``execute INSTALLDIR:S/CombinePath ""`$INSTALLDIR"" ""{0}""``""" -f $indexName)
        $installEntriesLines.Add("IF NOT EXISTS ""`$entrydir""")
        $installEntriesLines.Add("  MakePath ""`$entrydir"" >NIL:")
        $installEntriesLines.Add("ENDIF")

        foreach($hardware in ($installEntryFilenameIndex[$indexName].Keys | Sort-Object))
        {
            $installEntriesLines.Add("IF ""`$entrieshardware{0}"" EQ 1 VAL" -f $hardware)

            foreach($language in ($installEntryFilenameIndex[$indexName][$hardware].Keys | Sort-Object))
            {
                if ($language -match 'MULTI')
                {
                    $installEntriesLines.Add(("  Execute ""USERPACKAGEDIR:{0}/{1}""" -f $userPackagePath, $installEntryFilenameIndex[$indexName][$hardware][$language]))
                }
                else
                {
                    $installEntriesLines.Add("  IF ""`$entrieslanguage{0}"" EQ 1 VAL" -f $language)
                    $installEntriesLines.Add(("    echo ""*e[1mInstalling {0}, {1}, {2}...*e[0m""" -f $indexName, $hardware.ToUpper(), $language.ToUpper()))
                    $installEntriesLines.Add("    wait 1")
                    $installEntriesLines.Add(("    Execute ""USERPACKAGEDIR:{0}/{1}""" -f $userPackagePath, $installEntryFilenameIndex[$indexName][$hardware][$language]))
                    $installEntriesLines.Add("  ENDIF")
                }
            }

            $installEntriesLines.Add("ENDIF")
        }
    }

    $installEntriesLines.Add("")
    
    # write install entries file
    $installEntriesFile = Join-Path $installEntriesDir -ChildPath 'Install-Entries'
    WriteTextLinesForAmiga $installEntriesFile $installEntriesLines.ToArray()
}

# write entries list
function WriteEntriesList()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$entriesFile,
        [Parameter(Mandatory=$true)]
        [array]$entries
    )

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
            "BestVersionRank" = $_.BestVersionRank;
            "BestVersionLowMemRank" = $_.BestVersionLowMemRank;
        } } | `
        ForEach-Object{ New-Object PSObject -Property $_ } | `
        export-csv -delimiter ';' -path $entriesFile -NoTypeInformation -Encoding UTF8
}

# write build install entries title
Write-Output "---------------------"
Write-Output "Build Install Entries"
Write-Output "---------------------"
Write-Output "Author: Henrik Noerfjand Stengaard"
Write-Output "Date: 2018-05-20"
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

    # skip user package directory, if it's doesnt contain any entries
    if ($entries.Count -eq 0)
    {
        continue
    }

    # copy unlzx to user package directory, if unlzx file exists
    if (Test-Path $unlzxFile)
    {
        Copy-Item $unlzxFile $userPackageDir.FullName
    }

    # build install entries in user package directory
    Write-Output ("- Building install entries...")

    # build best versions
    $entriesBestVersion = BuildEntriesBestVersion $entries $false
    $entriesBestVersionLowMem = BuildEntriesBestVersion $entries $true

    # entries sets
    $entriesSets = @(
        @{
            'Name' = 'All';
            'Description' = 'Install all entries.';
            'Entries' = $entries
        },
        @{
            'Name' = 'Best-Version';
            'Description' = 'Install best version of identical entries.';
            'Entries' = $entriesBestVersion
        },
        @{
            'Name' = 'Best-Version-Lowmem';
            'Description' = 'Install best version of identical entries for low mem Amigas.';
            'Entries' = $entriesBestVersionLowMem
        })

    # build user package install
    BuildUserPackageInstall $entriesSets $userPackageName $userPackageDir.FullName

    # create user package install directory, if it doesn't exist
    $userPackageInstallDir = Join-Path $userPackageDir.FullName -ChildPath "Install"
    if (!(Test-Path -Path $userPackageInstallDir))
    {
        mkdir -Path $userPackageInstallDir | Out-Null
    }

    # build install entries for entries sets
    foreach ($entriesSet in $entriesSets)
    {
        # create install entries directory, if it doesn't exist
        $installEntriesDir = Join-Path $userPackageInstallDir -ChildPath $entriesSet.Name
        if (!(Test-Path -Path $installEntriesDir))
        {
            mkdir -Path $installEntriesDir | Out-Null
        }

        # build install entries
        BuildInstallEntries $entriesSet.Entries ("Install/{0}" -f $entriesSet.Name) $installEntriesDir

        # write entries list
        $entriesListFile = Join-Path -Path $userPackageDir.FullName -ChildPath ("entries-{0}.csv" -f $entriesSet.Name.ToLower())
        WriteEntriesList $entriesListFile $entriesSet.Entries
    }

    Write-Output ("- Done.")
}