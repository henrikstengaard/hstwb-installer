# Build EAB WHDLoad Install
# -------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-05-14
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

# parse eab whdload entry name
function ParseEabWhdloadEntryName()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$eabWhdLoadEntryName
    )

    # patterns for parsing eab whdload entry name
    $idPattern = '([_&])(\d{4})$'
    $hardwarePattern = '_?(CD32|AGA|CDTV|CD)$'
    $languagePattern = '_?(En|De|Fr|It|Se|Pl|Es|Cz|Dk|Fi|Gr|CV)$'
    $memoryPattern = '_?(Slow|Fast|LowMem|Chip|1MB|1Mb|2MB|15MB|512k|512K|512kb|512Kb|512KB)$'
    $demoPattern = '_?(Rolling|Playable|Demo\d?|Demos|Preview|DemoLatest|DemoPlay|DemoRoll|Prerelease)$'
    $publisherDeveloperPattern = '_?(CoreDesign|Paradox|Rowan|Ratsoft|Spotlight|Empire|Impressions|Arcane|Mirrorsoft|Infogrames|Cinemaware|MagneticScrolls|System3|Mindscape|MicroValue|Ocean|MicroIllusions|DesktopDynamite|Infacto|Team17|ElectronicZoo|ReLINE|USGold|Epyx|Psygnosis|Palace|Kaiko|Audios|Sega|Activision|Arcadia|AmigaPower|AmigaFormat|AmigaAction|CUAmiga|TheOne)$'
    $otherPattern = '_?(AmigaStar|QuattroFighters|QuattroArcade|EarlyBuild|Oracle|Nomad|DOS|HighDensity|CompilationArcadeAction|_DizzyCollection|EasyPlay|Repacked|F1Licenceware|Alt|AltLevels|NoSpeech|NoMusic|NoSounds|NoVoice|NoMovie|Fix|Fixed|Aminet|ComicRelief|Util|Files|Image\d?|68060|060|Intro|NoIntro|NTSC|Censored|Kick31|Kick13|\dDisk|\(EasyPlay\)|Kernal1.1|Kernal_Version_1.1|Cracked|HiRes|LoRes|Crunched|Decrunched)$'
    #$compilationPattern = '_?(&EscapeFromSingesCastle|&Missions|&MissionDisk|&MissionDisks|&SceneryDisk\d*|&Hawaiian|&SceneryDisks|&CityDefense|&ExtraTime|&SpaceHarrier|&Missions|&ExtendedLevels|&CadaverThePayoff|&Planeteers|&ConstrSet|&ConstructionSet|&MstrTrcks|&DDisks|&DataDisks|&DataDisk\d?|&Profidisk|&Data|&TourDisk|&ChallengeGames|&VoyageBeyond|&RetrnFntZone|&RFantasyZone|&SummerGames2|&NewWorlds)'
    $versionPattern = '_?[vV]((\d+|\d+\.\d+|\d+\.\d+[\._]\d+)([\.\-_])?[a-zA-Z]?)$'

    # parsing results
	$idResults = New-Object System.Collections.Generic.List[System.Object]
	$hardwareResults = New-Object System.Collections.Generic.List[System.Object]
	$languageResults = New-Object System.Collections.Generic.List[System.Object]
	$memoryResults = New-Object System.Collections.Generic.List[System.Object]
	$demoResults = New-Object System.Collections.Generic.List[System.Object]
	$publisherDeveloperResults = New-Object System.Collections.Generic.List[System.Object]
	$otherResults = New-Object System.Collections.Generic.List[System.Object]
	#$compilationResults = New-Object System.Collections.Generic.List[System.Object]
	$versionResults = New-Object System.Collections.Generic.List[System.Object]

    # set entry name with filename extension
    $entryName = $eabWhdLoadEntryName -replace '\.(lha|lzx|zip)$', ''

    # parse entry name
	do
	{
        $patternMatch = $false

        # parse id from entry name
		if ($entryName -cmatch $idPattern)
		{
            $patternMatch = $true
            $id = ($entryName | Select-String -Pattern $idPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[2].Value } | Select-Object -First 1)
			$idResults.Add($id.ToLower())
			$entryName = $entryName -creplace $idPattern, ''
            continue
		}

        # parse hardware from entry name
		if ($entryName -cmatch $hardwarePattern)
		{
            $patternMatch = $true
            $hardware = ($entryName | Select-String -Pattern $hardwarePattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
			$hardwareResults.Add($hardware.ToLower())
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
				$languageResults.Add($language.ToLower())
			}

			$entryName = $entryName -creplace $languagePattern, ''
            continue
		}

        # parse memory from entry name
		if ($entryName -cmatch $memoryPattern)
		{
            $patternMatch = $true
            $memory = ($entryName | Select-String -Pattern $memoryPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
			$memoryResults.Add($memory.ToLower())
			$entryName = $entryName -creplace $memoryPattern, ''
            continue
		}
        
        # parse demo from entry name
		if ($entryName -cmatch $demoPattern)
		{
            $patternMatch = $true
            $demo = ($entryName | Select-String -Pattern $demoPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
			$demoResults.Add($demo.ToLower())
			$entryName = $entryName -creplace $demoPattern, ''
            continue
		}

        # parse developer publisher from entry name
		if ($entryName -cmatch $publisherDeveloperPattern)
		{
            $patternMatch = $true
            $publisherDeveloper = ($entryName | Select-String -Pattern $publisherDeveloperPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
			$publisherDeveloperResults.Add($publisherDeveloper.ToLower())
			$entryName = $entryName -creplace $publisherDeveloperPattern, ''
            continue
		}
        
        # parse other from entry name
		if ($entryName -cmatch $otherPattern)
		{
            $patternMatch = $true
            $other = ($entryName | Select-String -Pattern $otherPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1) 
            $otherResults.Add($other.ToLower())
            $entryName = $entryName -creplace $otherPattern, ''
            continue
		}

        # parse compilation from entry name
		# if ($entryName -cmatch $compilationPattern)
		# {
        #     $patternMatch = $true
		# 	$compilation = ($entryName | Select-String -Pattern $compilationPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
		# 	$compilationResults.Add(($compilation.ToLower() -replace '^&', ''))
		# 	$entryName = $entryName -creplace $compilationPattern, ''
        # }
        
        # parse version from entry name
		if ($entryName -cmatch $versionPattern)
		{
            $patternMatch = $true
            $version = ($entryName | Select-String -Pattern $versionPattern -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
			$versionResults.Add($version.ToLower())
			$entryName = $entryName -creplace $versionPattern, ''
            continue
		}
	} while ($patternMatch)

    # remove ambersand from entry name
	$entryName = $entryName -replace '&$', ''

    # add ocs hardware, if no hardware results exist
    if ($hardwareResults.Count -eq 0)
    {
        $hardwareResults.Add('ocs')
    }

    # add en language, if no language results exist
    if ($languageResults.Count -eq 0)
    {
        $languageResults.Add('en')
    }

    return @{
        'EntryName' = $entryName;
        'IdResults' = $idResults.ToArray();
        'HardwareResults' = $hardwareResults.ToArray();
        'LanguageResults' = $languageResults.ToArray();
        'MemoryResults' = $memoryResults.ToArray();
        'DemoResults' = $demoResults.ToArray();
        'PublisherDeveloperResults' = $publisherDeveloperResults.ToArray();
        'OtherResults' = $otherResults.ToArray();
        # 'CompilationResults' = $compilationResults.ToArray();
        'VersionResults' = $versionResults.ToArray()
    }
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

        $parsedEabWhdloadEntryName = ParseEabWhdloadEntryName $file.Name

        $eabWhdLoadEntries.Add(@{
            'File' = $file.FullName;
            'EabWhdLoadFile' = $eabWhdLoadFile;
            'Language' = $language;
            'Hardware' = $hardware;
            'EntryName' = $parsedEabWhdloadEntryName.entryName;
            'IdResults' = $parsedEabWhdloadEntryName.IdResults -join ',';
            'HardwareResults' = $parsedEabWhdloadEntryName.hardwareResults -join ',';
            'LanguageResults' = $parsedEabWhdloadEntryName.languageResults -join ',';
            'MemoryResults' = $parsedEabWhdloadEntryName.memoryResults -join ',';
            'DemoResults' = $parsedEabWhdloadEntryName.demoResults -join ',';
            'PublisherDeveloperResults' = $parsedEabWhdloadEntryName.PublisherDeveloperResults -join ',';
            'OtherResults' = $parsedEabWhdloadEntryName.otherResults -join ',';
            # 'CompilationResults' = $parsedEabWhdloadEntryName.compilationResults -join ',';
            'VersionResults' = $parsedEabWhdloadEntryName.VersionResults -join ','
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

    # build hardware and language indexes
    $languageIndex = @{}
    $hardwareIndex = @{}
    foreach($eabWhdLoadEntry in $eabWhdLoadEntries)
    {
        $hardware = $eabWhdLoadEntry.Hardware
        $language = $eabWhdLoadEntry.Language

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
    $eabWhdLoadInstallLines.Add("echo ""Install `$totalcount of {0} entries"" >>T:_eabwhdloadmenu" -f $eabWhdLoadEntries.Count)
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
    foreach($eabWhdLoadEntry in $eabWhdLoadEntries)
    {
        $indexName = $eabWhdLoadEntry.EabWhdLoadFile.Substring(0,1).ToUpper()
        $hardware = $eabWhdLoadEntry.Hardware
        $language = $eabWhdLoadEntry.Language

        if ($indexName -match "^(#|\d)")
        {
            $indexName = "0-9"
        }

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
        
        # replace \ with / and espace # with '#
        $eabWhdLoadFile = "USERPACKAGEDIR:{0}" -f $eabWhdLoadEntry.EabWhdLoadFile.Replace("\", "/")
        $eabWhdLoadFileEscaped = $eabWhdLoadFile.Replace("#", "'#")

        # extract eab whdload file
        $eabWhdLoadInstallEntryLines.Add("IF EXISTS ""{0}""" -f $eabWhdLoadFile)
        if ($eabWhdLoadFile -match '\.lha$')
        {
            $eabWhdLoadInstallEntryLines.Add(("  lha -m1 x ""{0}"" ""`$entrydir/""" -f $eabWhdLoadFileEscaped))
        }
        elseif ($eabWhdLoadFile -match '\.lzx$')
        {
            $eabWhdLoadInstallEntryLines.Add(("  unlzx -m e ""{0}"" ""`$entrydir/""" -f $eabWhdLoadFileEscaped))
        }
        $eabWhdLoadInstallEntryLines.Add("ENDIF")
    }

    # write eab whdload install entry files
    foreach($eabWhdLoadInstallEntryFilename in $eabWhdLoadInstallEntryFileIndex.keys)
    {
        $eabWhdLoadInstallEntryLines = $eabWhdLoadInstallEntryFileIndex[$eabWhdLoadInstallEntryFilename]
        $eabWhdLoadInstallEntryLines.Add("")

        $eabWhdLoadInstallEntryFile = Join-Path $eabWhdLoadInstallEntriesDir -ChildPath $eabWhdLoadInstallEntryFilename
        WriteTextLinesForAmiga $eabWhdLoadInstallEntryFile $eabWhdLoadInstallEntryLines.ToArray()
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
Write-Output "Date: 2018-05-14"
Write-Output ""

# resolve paths
$eabWhdLoadPacksDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($eabWhdLoadPacksDir)

# fail, if eab whdload packs directory doesn't exist
if (!(Test-Path $eabWhdLoadPacksDir))
{
    throw ("EAB WHDLoad Packs directory '{0}' doesn't exist" -f $eabWhdLoadPacksDir)
}

# write eab whdload packs directory
Write-Output ("EAB WHDLoad Packs directory: '{0}'" -f $eabWhdLoadPacksDir)
Write-Output ""
Write-Output "Building EAB WHDLoad Install scripts for user package directories:"

# find eab whdload directories
$eabWhdLoadPackDirs = @()
$eabWhdLoadPackDirs += Get-ChildItem -Path $eabWhdLoadPacksDir | Where-Object { $_.PSIsContainer -and $_ -match 'whdload' }

# exit, if eab whdload directories was not found
if ($eabWhdLoadPackDirs.Count -eq 0)
{
    Write-Output "No EAB WHDLoad Pack directories was not found!"
    exit
}

# unlzx file
$unlzxFile = Join-Path $eabWhdLoadPacksDir -ChildPath 'unlzx'

# build eab whdload install for eab whdload directories
foreach($eabWhdLoadPackDir in $eabWhdLoadPackDirs)
{
    # get eab whdload pack name
    $eabWhdLoadPackName = $eabWhdLoadPackDir.Name
    Write-Output $eabWhdLoadPackName
    Write-Output '- Scanning for entries...'

    # find eab whdload entries in eab whdload pack directory
    $eabWhdloadEntries = @()
    $eabWhdloadEntries += FindEabWhdloadEntries $eabWhdLoadPackDir.FullName
    Write-Output ("- Found {0} entries." -f $eabWhdloadEntries.Count)

    # skip eab whdload pack, if it's doesnt contain any entries
    if ($eabWhdloadEntries.Count -eq 0)
    {
        continue
    }

    # write entries list
    $entriesFile = Join-Path $eabWhdLoadPacksDir -ChildPath ("{0}_entries.csv" -f $eabWhdLoadPackName)
    $eabWhdloadEntries | ForEach-Object{ New-Object PSObject -Property $_ } | Export-Csv -Delimiter ';' -Path $entriesFile -NoTypeInformation -Encoding UTF8

    # copy unlzx to eab whdload pack directory, if unlzx file exists
    if (Test-Path $unlzxFile)
    {
        Copy-Item $unlzxFile $eabWhdLoadPackDir.FullName
    }

    # build eab whdload install in eab whdload pack directory
    Write-Output ("- Building EAB WHDLoad Install...")
    BuildEabWhdloadInstall $eabWhdloadEntries $eabWhdLoadPackName $eabWhdLoadPackDir.FullName

    # write entries list
    $eabWhdloadEntriesFile = Join-Path -Path $eabWhdLoadPackDir.FullName -ChildPath "entries.csv"
    $eabWhdloadEntries | `
        ForEach-Object { @{ "File" = $_.EabWhdLoadFile; "Hardware" = $_.Hardware; "Language" = $_.Language } } | `
        ForEach-Object{ New-Object PSObject -Property $_ } | `
        export-csv -delimiter ';' -path $eabWhdloadEntriesFile -NoTypeInformation -Encoding UTF8

    Write-Output ("- Done.")
}