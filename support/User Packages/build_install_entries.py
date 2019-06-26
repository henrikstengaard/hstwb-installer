#!/usr/local/bin/python
# -*- coding: utf-8 -*-

# Build Install Entries
# ---------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2019-06-26
#
# A powershell script to build install entries script for HstWB Installer user packages.


"""Build Install Entries"""

from __future__ import print_function
from __future__ import unicode_literals
import os
import re
import shutil
import datetime
from sys import argv
import io
import csv
import codecs
import unicodedata

# entry
class Entry:
    file_full_name = ""
    user_package_file = ""
    name = ""
    entry_id = []
    language = []
    hardware = []
    memory = []
    release = []
    publisher_developer = []
    other = []
    version = []
    unsupported = []
    best_version_rank = 0
    best_version_lowmem_rank = 0

# entries set
class EntriesSet:
    name = ""
    description = ""
    entries = ""

# get index name
def get_index_name(name):
    """Get Index Name"""
    if not name or re.search(r'^\s*$', name, re.I):
        return "_"
    elif re.search(r'^(#|\d)', name, re.I):
        return "0-9"
    
    return name[0:1].upper()

# write text lines for amiga
def write_text_lines_for_amiga(path, lines):
    """Write Text Lines for Amiga"""
    with codecs.open(path, "w", "iso-8859-1") as f:
        for l in lines:
            f.write(unicodedata.normalize('NFC', l)+"\n")

# parse entry
def parse_entry(entry_name):
    """Parse Entry"""

    # patterns for parsing entry name
    id_pattern = r'([_&])(\d{4})$'
    hardware_pattern = r'_(CD32|AGA|CDTV)$'
    language_pattern = r'_?(En|De|Fr|It|Se|Pl|Es|Cz|Dk|Fi|Gr|CV|German|Spanish)$'
    memory_pattern = r'_?(Slow|Fast|LowMem|Chip|1MB|1Mb|2MB|15MB|512k|512K|512kb|512Kb|512KB)$'
    release_pattern = r'_?(Rolling|Playable|Demo\d?|Demos|Preview|DemoLatest|DemoPlay|DemoRoll|Prerelease|BETA)$'
    publisher_developer_pattern = r'_?(CoreDesign|Paradox|Rowan|Ratsoft|Spotlight|Empire|Impressions|Arcane|Mirrorsoft|Infogrames|Cinemaware|System3|Mindscape|MicroValue|Ocean|MicroIllusions|DesktopDynamite|Infacto|Team17|ElectronicZoo|ReLINE|USGold|Epyx|Psygnosis|Palace|Kaiko|Audios|Sega|Activision|Arcadia|AmigaPower|AmigaFormat|AmigaAction|CUAmiga|TheOne)$'
    other_pattern = r'_?(CD|A1200Version|NONAGA|HardNHeavyHack|[Ff]ix_by_[^_]+|[Hh]ack_by_[^_]+|AmigaStar|QuattroFighters|QuattroArcade|EarlyBuild|Oracle|Nomad|DOS|HighDensity|CompilationArcadeAction|_DizzyCollection|EasyPlay|Repacked|F1Licenceware|Alt|AltLevels|NoSpeech|NoMusic|NoSounds|NoVoice|NoMovie|Fix|Fixed|Aminet|ComicRelief|Util|Files|Image\d?|68060|060|Intro|NoIntro|NTSC|Censored|Kick31|Kick13|\dDisk|\(EasyPlay\)|Kernal1.1|Kernal_Version_1.1|Cracked|HiRes|LoRes|Crunched|Decrunched)$'
    version_pattern = r'_?[Vv]((\d+|\d+\.\d+|\d+\.\d+[\._]\d+)([\.\-_])?[a-zA-Z]?\d*)$'
    unsupported_pattern = r'[\.\-_](.*)$'

    # lists with parsing results
    id_list = []
    language_list = []
    hardware_list = []
    memory_list = []
    release_list = []
    publisher_developer_list = []
    other_list = []
    version_list = []
    unsupported_list = []

    # set entry name with filename extension
    entry_name = re.sub(r'\.(lha|lzx|zip)$', '', entry_name, re.I)

    pattern_match = True
    while pattern_match:
        pattern_match = False

        # parse id from entry name
        id_match = re.search(id_pattern, entry_name)
        if id_match:
            pattern_match = True
            entry_id = id_match.group(2)
            id_list.append(entry_id.lower())
            entry_name = re.sub(id_pattern, '', entry_name)
            continue

        # parse hardware from entry name
        hardware_match = re.search(hardware_pattern, entry_name)
        if hardware_match:
            pattern_match = True
            hardware = hardware_match.group(1).lower()
            hardware_list.append(hardware.lower())
            entry_name = re.sub(hardware_pattern, '', entry_name)
            continue

        # parse language from entry name
        language_match = re.search(language_pattern, entry_name)
        if language_match:
            pattern_match = True
            language = language_match.group(1)

            if language is not u'En':
                if re.search(r'german', language, re.I):
                    language = u'De'
                if re.search(r'spanish', language, re.I):
                    language = u'Es'
                language_list.append(language.lower())

            entry_name = re.sub(language_pattern, '', entry_name)
            continue

        # parse memory from entry name
        memory_match = re.search(memory_pattern, entry_name)
        if memory_match:
            pattern_match = True
            memory = memory_match.group(1)
            memory_list.append(memory.lower())
            entry_name = re.sub(memory_pattern, '', entry_name)
            continue

        # parse release from entry name
        release_match = re.search(release_pattern, entry_name)
        if release_match:
            pattern_match = True
            release = release_match.group(1)
            release_list.append(release.lower())
            entry_name = re.sub(release_pattern, '', entry_name)
            continue

        # parse developer publisher from entry name
        publisher_developer_match = re.search(publisher_developer_pattern, entry_name)
        if publisher_developer_match:
            pattern_match = True
            publisher_developer = publisher_developer_match.group(1)
            publisher_developer_list.append(publisher_developer.lower())
            entry_name = re.sub(publisher_developer_pattern, '', entry_name)
            continue

        # parse other from entry name
        other_match = re.search(other_pattern, entry_name)
        if other_match:
            pattern_match = True
            other = other_match.group(1)
            other_list.append(other.lower())
            entry_name = re.sub(other_pattern, '', entry_name)
            continue

        # parse version from entry name
        version_match = re.search(version_pattern, entry_name)
        if version_match:
            pattern_match = True
            version = version_match.group(1)
            version_list.append(version.lower())
            entry_name = re.sub(version_pattern, '', entry_name)
            continue

        # parse unsupported from entry name
        unsupported_match = re.search(unsupported_pattern, entry_name, re.I)
        if unsupported_match:
            pattern_match = True
            unsupported = unsupported_match.group(1)
            unsupported_list.append(unsupported.lower())
            entry_name = re.sub(unsupported_pattern, '', entry_name, re.I)
            continue

    # add ocs hardware, if no hardware results exist
    if len(hardware_list) == 0:
        hardware_list.append(u'ocs')

    # add en language, if no language results exist
    if len(language_list) == 0:
        language_list.append(u'en')

    entry = Entry()
    entry.name = entry_name
    entry.entry_id = id_list
    entry.language = language_list
    entry.hardware = hardware_list
    entry.memory = memory_list
    entry.release = release_list
    entry.publisher_developer = publisher_developer_list
    entry.other = other_list
    entry.version = version_list
    entry.unsupported = unsupported_list

    return entry

# calculate best version rank
def calculate_best_version_rank(entry):
    rank = 100
    rank = rank - len([x for x in entry.language if not re.search(r'en', x, re.I)]) * 10
    rank = rank - len(entry.release) * 10
    rank = rank - len(entry.publisher_developer) * 10
    rank = rank - len(entry.other) * 10
    rank = rank - len(entry.memory) * 10

    lowmem_rank = rank

    lowest_memory_list = [x for x in entry.memory if re.search(r'^\d+(k|m)b?$', x, re.I)]

    for i in range(0, len(lowest_memory_list)):
        lowest_memory_list[i] = re.sub(r'mb$', '000000', lowest_memory_list[i], re.I)
        lowest_memory_list[i] = re.sub(r'(k|kb)$', '000', lowest_memory_list[i], re.I)

    if len(lowest_memory_list) > 0:
        lowest_memory_list = sorted(lowest_memory_list, key=lambda x: x.lower())

        lowest_memory = float(lowest_memory_list[0])

        rank = rank - 10
        lowmem_rank = lowmem_rank + (10 / (lowest_memory / 512000)) * 2

    if len([x for x in entry.memory if re.search(r'lowmem', x, re.I)]) > 0:
        lowmem_rank = lowmem_rank + 20

    if len([x for x in entry.memory if re.search(r'chip', x, re.I)]) > 0:
        lowmem_rank = lowmem_rank + 20

    entry.best_version_rank = rank
    entry.best_version_lowmem_rank = lowmem_rank

# find entries
def find_entries(user_package_dir):
    """Find Entries"""

    user_package_dir_index = len(user_package_dir) + 1
    entries = []

    for root, directories, filenames in os.walk(unicode(user_package_dir, 'utf-8')):
        for filename in filenames:
            # skip, if filename doesn't end with .lha, .lzx or .zip
            if not (filename.endswith(".lha") or filename.endswith(".lzx") or filename.endswith(".zip")):
                continue

            file_full_name = os.path.join(root, filename)
            user_package_file = file_full_name[user_package_dir_index : len(file_full_name)]

            # parse entry
            entry = parse_entry(filename)

            # add file full name and user package file
            entry.file_full_name = os.path.realpath(file_full_name)
            entry.user_package_file = user_package_file

            calculate_best_version_rank(entry)

            # add entry
            entries.append(entry)

    # sort entries
    entries = sorted(entries, key=lambda entry: entry.user_package_file.lower())
    
    return entries

# build entries best version
def build_entries_best_version(entries, lowmem):
    """Build Entries Best Version"""

    # build entry versions index
    entry_versions_index = {}
    for entry in entries:
        language_set = "multi" if len(entry.language) > 1 else "single-{0}".format(entry.language[0]) 
        entry_version_id = "{0}-{1}-{2}".format(entry.name, entry.hardware[0], language_set).lower()

        if not entry_version_id in entry_versions_index:
            entry_versions_index[entry_version_id] = []
        
        entry_versions_index[entry_version_id].append(entry)

    # build entries best version from highest ranking entry version
    best_version_entries = []
    for entry_version_id in entry_versions_index.keys():
        entry_versions_sorted_by_rank = entry_versions_index[entry_version_id]
        if lowmem:
            entry_versions_sorted_by_rank = sorted(entry_versions_sorted_by_rank, key=lambda entry: (-entry.best_version_lowmem_rank, entry.user_package_file.lower()))
        else:
            entry_versions_sorted_by_rank = sorted(entry_versions_sorted_by_rank, key=lambda entry: (-entry.best_version_rank, entry.user_package_file.lower()))

        entry_best_version = entry_versions_sorted_by_rank[0]
        best_version_entries.append(entry_best_version)

    best_version_entries = sorted(best_version_entries, key=lambda entry: entry.user_package_file.lower())

    return best_version_entries

# build user package install
def build_user_package_install(entries_sets, user_package_name, entries_dir):
    """Build User Package Install"""

    # build hardware and language indexes
    hardware_index = {}
    language_index = {}
    for entries_set in entries_sets:
        for entry in entries_set.entries:
            hardware = entry.hardware[0]

            if not entries_set.name in hardware_index:
                hardware_index[entries_set.name] = {}

            if hardware in hardware_index[entries_set.name]:
                hardware_index[entries_set.name][hardware] += 1
            else:
                hardware_index[entries_set.name][hardware] = 1

            language_set = "multi" if len(entry.language) > 1 else "single" 

            for language in entry.language:
                if not entries_set.name in language_index:
                    language_index[entries_set.name] = {}

                if not language_set in language_index[entries_set.name]:
                    language_index[entries_set.name][language_set] = {}

                if not language in language_index[entries_set.name][language_set]:
                    language_index[entries_set.name][language_set][language] = {}

                if hardware in language_index[entries_set.name][language_set][language]:
                    language_index[entries_set.name][language_set][language][hardware] += 1
                else:
                    language_index[entries_set.name][language_set][language][hardware] = 1

    # build entries install lines
    user_package_install_lines = []
    user_package_install_lines.append("; {0}".format(user_package_name))
    user_package_install_lines.append(("; {0}".format("-" * len(user_package_name))))
    user_package_install_lines.append("; Author: Henrik Noerfjand Stengaard")
    user_package_install_lines.append("; Date: {0}".format(datetime.date.today().strftime('%Y-%m-%d')))
    user_package_install_lines.append("")
    user_package_install_lines.append("; An AmigaDOS script for installing entries in user package '{0}' built by Build Install Entries script.".format(user_package_name))
    user_package_install_lines.append("")
    user_package_install_lines.append("; Patch for HstWB Installer without unlzx")
    user_package_install_lines.append("IF NOT EXISTS \"SYS:C/unlzx\"")
    user_package_install_lines.append("  IF EXISTS \"USERPACKAGEDIR:unlzx\"")
    user_package_install_lines.append("    Copy \"USERPACKAGEDIR:unlzx\" \"SYS:C/unlzx\" >NIL:")
    user_package_install_lines.append("  ENDIF")
    user_package_install_lines.append("ENDIF")
    user_package_install_lines.append("")
    user_package_install_lines.append("; reset")

    user_package_install_lines.append("set devicereqfreemb \"50\"")
    user_package_install_lines.append("set stopinstallation \"0\"")
    user_package_install_lines.append("set entriessetid \"1\"")

    all_hardwares = []
    for entries_set_name in hardware_index.keys():
        for hardware in hardware_index[entries_set_name].keys():
            all_hardwares.append(hardware)
    all_hardwares = list(set(all_hardwares))
    all_hardwares.sort()

    for hardware in all_hardwares:
        user_package_install_lines.append("set entrieshardware{0} \"1\"".format(hardware))

    all_languages = []
    for entries_set_name in language_index.keys():
        for language in language_index[entries_set_name]["single"].keys():
            all_languages.append(language)
    all_languages = list(set(all_languages))
    all_languages.sort()

    for language in all_languages:
        user_package_install_lines.append("set entrieslanguage{0} \"1\"".format(language))

    user_package_install_lines.append("")
    user_package_install_lines.append("; install entries menu")
    user_package_install_lines.append("LAB installentriesmenu")

    entries_set_names = []
    entries_set_description_lines = []
    
    entries_set_id = 0
    for entries_set in entries_sets:
        entries_set_name = entries_set.name.replace("-", " ")
        entries_set_names.append(entries_set_name)
        entries_set_description_lines.append("{0}:".format(entries_set_name))
        entries_set_description_lines.append("- {0}".format(entries_set.description))
        
        entries_set_id += 1
        user_package_install_lines.append("; show entries set '{0}' menu".format(entries_set_name))
        user_package_install_lines.append("IF \"$entriessetid\" EQ {0} VAL".format(entries_set_id))
        user_package_install_lines.append("  SKIP entriesset{0}menu".format(entries_set_id))
        user_package_install_lines.append("ENDIF")

    entries_set_id = 0
    for entries_set in entries_sets:
        entries_set_id += 1

        # get hardwares and languages sorted
        hardwares = hardware_index[entries_set.name].keys()
        hardwares.sort()
        languages = language_index[entries_set.name]["single"].keys()
        languages.sort()

        user_package_install_lines.append("")
        user_package_install_lines.append("; entries set '{0}' menu".format(entries_set.name))
        user_package_install_lines.append("LAB entriesset{0}menu".format(entries_set_id))
        user_package_install_lines.append("")
        user_package_install_lines.append("set totalcount \"0\"")
        user_package_install_lines.append("set totalmulticount \"0\"")
        user_package_install_lines.append("echo \"\" NOLINE >T:_entriessetmenu")
    
        user_package_install_lines.append("echo \"Selected entries set: {0}\" >>T:_entriessetmenu".format(entries_set.name.replace("-", " ")))
        user_package_install_lines.append("echo \"----------------------------------------\" >>T:_entriessetmenu")

        for hardware in hardwares:
            user_package_install_lines.append("")
            user_package_install_lines.append("; '{0}' hardware menu".format(hardware))
            user_package_install_lines.append("IF \"$entrieshardware{0}\" EQ 1 VAL".format(hardware))
            user_package_install_lines.append("  echo \"Install\" NOLINE >>T:_entriessetmenu")
            user_package_install_lines.append("ELSE")
            user_package_install_lines.append("  echo \"Skip   \" NOLINE >>T:_entriessetmenu")
            user_package_install_lines.append("ENDIF")
            user_package_install_lines.append(("echo \" : {0} hardware ({1} entries)\" >>T:_entriessetmenu".format(hardware.upper(), hardware_index[entries_set.name][hardware])))

        user_package_install_lines.append("echo \"----------------------------------------\" >>T:_entriessetmenu")

        for language in languages:
            user_package_install_lines.append("")
            user_package_install_lines.append("; '{0}' language menu".format(language))
            user_package_install_lines.append("set languagecount \"0\"")
            user_package_install_lines.append("set multicount \"0\"")

            language_hardwares = language_index[entries_set.name]["single"][language].keys()
            language_hardwares.sort()
            for hardware in language_hardwares:
                user_package_install_lines.append("IF \"$entrieshardware{0}\" EQ 1 VAL".format(hardware))
                user_package_install_lines.append("  set languagecount `eval $languagecount + {0}`".format(language_index[entries_set.name]["single"][language][hardware]))

                if "multi" in language_index[entries_set.name] and language in language_index[entries_set.name]["multi"] and hardware in language_index[entries_set.name]["multi"][language]:
                    user_package_install_lines.append("  set multicount `eval $multicount + {0}`".format(language_index[entries_set.name]["multi"][language][hardware]))

                user_package_install_lines.append("ENDIF")

            user_package_install_lines.append("IF \"$entrieslanguage{0}\" EQ 1 VAL".format(language))
            user_package_install_lines.append("  set totalcount `eval $totalcount + $languagecount`")
            user_package_install_lines.append("  IF \"$multicount\" GT \"$totalmulticount\" VAL")
            user_package_install_lines.append("    set totalmulticount \"$multicount\"")
            user_package_install_lines.append("  ENDIF")
            user_package_install_lines.append("  echo \"Install\" NOLINE >>T:_entriessetmenu")
            user_package_install_lines.append("ELSE")
            user_package_install_lines.append("  echo \"Skip   \" NOLINE >>T:_entriessetmenu")
            user_package_install_lines.append("ENDIF")
            user_package_install_lines.append("echo \" : {0} language ($languagecount entries\" NOLINE >>T:_entriessetmenu".format(language.upper()))
            user_package_install_lines.append("IF \"$multicount\" GT 0 VAL")
            user_package_install_lines.append("  echo \", $multicount multi\" NOLINE >>T:_entriessetmenu")
            user_package_install_lines.append("ENDIF")
            user_package_install_lines.append("echo \")\" >>T:_entriessetmenu")

        user_package_install_lines.append("echo \"----------------------------------------\" >>T:_entriessetmenu")
        user_package_install_lines.append("echo \"Install all entries\" >>T:_entriessetmenu")
        user_package_install_lines.append("echo \"Skip all entries\" >>T:_entriessetmenu")
        user_package_install_lines.append("echo \"Start entries installation ($totalcount of {0} entries\" NOLINE >>T:_entriessetmenu".format(len(entries_set.entries)))
        user_package_install_lines.append("IF \"$totalmulticount\" GT 1 VAL")
        user_package_install_lines.append("  echo \", 1-$totalmulticount multi\" NOLINE >>T:_entriessetmenu")
        user_package_install_lines.append("ENDIF")
        user_package_install_lines.append("IF \"$totalmulticount\" EQ 1 VAL")
        user_package_install_lines.append("  echo \", 1 multi\" NOLINE >>T:_entriessetmenu")
        user_package_install_lines.append("ENDIF")
        user_package_install_lines.append("echo \")\" >>T:_entriessetmenu")
        user_package_install_lines.append("echo \"Skip entries installation\" >>T:_entriessetmenu")

        user_package_install_lines.append("")
        user_package_install_lines.append("set entriesinstalloption \"\"")
        user_package_install_lines.append("set entriesinstalloption `RequestList TITLE=\"{0}\" LISTFILE=\"T:_entriessetmenu\" WIDTH=640 LINES=24`".format(user_package_name))
        user_package_install_lines.append("delete >NIL: T:_entriessetmenu")

        entries_install_option = 1

        user_package_install_lines.append("")
        user_package_install_lines.append("; select entries set option")
        user_package_install_lines.append("IF \"$entriesinstalloption\" EQ {0} VAL".format(entries_install_option))
        user_package_install_lines.append("  set entriessetindex `RequestChoice \"Select entries set\" \"Select entries set to install.*N*N{0}\" \"{1}\"`".format('*N'.join(entries_set_description_lines), '|'.join(entries_set_names)))

        for i in range(1, len(entries_sets) + 1):
            entries_set_index = i if i < len(entries_sets) else 0 
            user_package_install_lines.append("  IF $entriessetindex EQ {0} VAL".format(entries_set_index))
            user_package_install_lines.append("    set entriessetid \"{0}\"".format(i))
            user_package_install_lines.append("  ENDIF")

        user_package_install_lines.append("  SKIP BACK installentriesmenu")
        user_package_install_lines.append("ENDIF")

        entries_install_option += 1

        for hardware in hardwares:
            entries_install_option += 1

            user_package_install_lines.append("")
            user_package_install_lines.append("; '{0}' hardware option".format(hardware))
            user_package_install_lines.append("IF \"$entriesinstalloption\" EQ {0} VAL".format(entries_install_option))
            user_package_install_lines.append("  IF \"$entrieshardware{0}\" EQ 1 VAL".format(hardware))
            user_package_install_lines.append("    set entrieshardware{0} \"0\"".format(hardware))
            user_package_install_lines.append("  ELSE")
            user_package_install_lines.append("    set entrieshardware{0} \"1\"".format(hardware))
            user_package_install_lines.append("  ENDIF")
            user_package_install_lines.append("  SKIP BACK entriesset{0}menu".format(entries_set_id))
            user_package_install_lines.append("ENDIF")

        entries_install_option += 1
        
        for language in languages:
            entries_install_option += 1

            user_package_install_lines.append("")
            user_package_install_lines.append("; '{0}' language option".format(language))
            user_package_install_lines.append("IF \"$entriesinstalloption\" EQ {0} VAL".format(entries_install_option))
            user_package_install_lines.append("  IF \"$entrieslanguage{0}\" EQ 1 VAL".format(language))
            user_package_install_lines.append("    set entrieslanguage{0} \"0\"".format(language))
            user_package_install_lines.append("  ELSE")
            user_package_install_lines.append("    set entrieslanguage{0} \"1\"".format(language))
            user_package_install_lines.append("  ENDIF")
            user_package_install_lines.append("  SKIP BACK entriesset{0}menu".format(entries_set_id))
            user_package_install_lines.append("ENDIF")

        entries_install_option += 2

        user_package_install_lines.append("")
        user_package_install_lines.append("; install all entries option")
        user_package_install_lines.append("IF \"$entriesinstalloption\" EQ {0} VAL".format(entries_install_option))

        for hardware in all_hardwares:
            user_package_install_lines.append("  set entrieshardware{0} \"1\"".format(hardware))

        for language in all_languages:
            user_package_install_lines.append("  set entrieslanguage{0} \"1\"".format(language))
            
        user_package_install_lines.append("  SKIP BACK entriesset{0}menu".format(entries_set_id))
        user_package_install_lines.append("ENDIF")

        entries_install_option += 1

        user_package_install_lines.append("")
        user_package_install_lines.append("; skip all entries option")
        user_package_install_lines.append("IF \"$entriesinstalloption\" EQ {0} VAL".format(entries_install_option))

        for hardware in all_hardwares:
            user_package_install_lines.append("  set entrieshardware{0} \"0\"".format(hardware))

        for language in all_languages:
            user_package_install_lines.append("  set entrieslanguage{0} \"0\"".format(language))
            
        user_package_install_lines.append("  SKIP BACK entriesset{0}menu".format(entries_set_id))
        user_package_install_lines.append("ENDIF")

        entries_install_option += 1

        user_package_install_lines.append("")
        user_package_install_lines.append("; start entries installation option")
        user_package_install_lines.append("IF \"$entriesinstalloption\" EQ {0} VAL".format(entries_install_option))
        user_package_install_lines.append("  set confirm `RequestChoice \"Start entries installation\" \"Do you want to entries installation of $totalcount entries?\" \"Yes|No\"`")
        user_package_install_lines.append("  IF \"$confirm\" EQ \"1\"")
        user_package_install_lines.append("    execute \"USERPACKAGEDIR:Install/{0}/Install-Entries\"".format(entries_set.name))
        user_package_install_lines.append("    SKIP end")
        user_package_install_lines.append("  ENDIF")
        user_package_install_lines.append("ENDIF")

        entries_install_option += 1

        user_package_install_lines.append("")
        user_package_install_lines.append("; skip entries installation option")
        user_package_install_lines.append("IF \"$entriesinstalloption\" EQ {0} VAL".format(entries_install_option))
        user_package_install_lines.append("  set confirm `RequestChoice \"Skip entries installation\" \"Do you want to skip entries installation?\" \"Yes|No\"`")
        user_package_install_lines.append("  IF \"$confirm\" EQ \"1\"")
        user_package_install_lines.append("    SKIP end")
        user_package_install_lines.append("  ENDIF")
        user_package_install_lines.append("ENDIF")
        user_package_install_lines.append("")
        user_package_install_lines.append("SKIP BACK entriesset{0}menu".format(entries_set_id))

    user_package_install_lines.append("")
    user_package_install_lines.append("; End")
    user_package_install_lines.append("; ---")
    user_package_install_lines.append("LAB end")

    # write user package install file
    user_package_install_file = os.path.join(entries_dir, "_install")
    write_text_lines_for_amiga(user_package_install_file, user_package_install_lines)

# build install entries
def build_install_entries(user_package_name, entries, user_package_path, install_entries_dir):
    """Build Install Entries"""

    # build install entry and filename indexes
    install_entry_filename_index = {}
    install_entry_lines_index = {}
    for entry in entries:
        entry_filename = os.path.basename(entry.user_package_file)
        index_name = get_index_name(entry_filename)
        hardware = entry.hardware[0]
        has_multi_languages = len(entry.language) > 1
        language = "MULTI" if has_multi_languages else entry.language[0]
        
        install_entry_filename = "{0}-{1}-{2}".format(index_name, hardware.upper(), language.upper())

        if not index_name in install_entry_filename_index:
            install_entry_filename_index[index_name] = {}

        if not hardware in install_entry_filename_index[index_name]:
            install_entry_filename_index[index_name][hardware] = {}

        if not language in install_entry_filename_index[index_name][hardware]:
            install_entry_filename_index[index_name][hardware][language] = install_entry_filename
        
        if not install_entry_filename in install_entry_lines_index:
            install_entry_lines_index[install_entry_filename] = []

        install_entry_lines = install_entry_lines_index[install_entry_filename]
        
        # replace \ with / and espace # with '#
        user_package_file = u"USERPACKAGEDIR:{0}".format(entry.user_package_file.replace("\\", "/"))
        user_package_file_escaped = u"{0}".format(user_package_file.replace("#", "'#"))

        # extract entry file
        if has_multi_languages:
            install_entry_lines.append("set entriesmulti \"0\"")

            for language in entry.language:
                install_entry_lines.append("IF \"$entrieslanguage{0}\" EQ 1 VAL".format(language))
                install_entry_lines.append("  set entriesmulti \"1\"")
                install_entry_lines.append("ENDIF")

            install_entry_lines.append("IF $entriesmulti EQ 1 VAL")

        padding = 2 if has_multi_languages else 0
        padding_text = " " * padding

        install_entry_lines.append(u"{0}IF EXISTS \"{1}\"".format(padding_text, user_package_file))
        install_entry_lines.append("{0}  Execute INSTALLDIR:S/InstallEntry \"{1}\" \"{2}\" \"{3}\"".format(padding_text, user_package_name, index_name, user_package_file_escaped))
        install_entry_lines.append("{0}  IF \"$stopinstallation\" EQ 1 VAL".format(padding_text))
        install_entry_lines.append("{0}    SKIP end".format(padding_text))
        install_entry_lines.append("{0}  ENDIF".format(padding_text))
        install_entry_lines.append("{0}ENDIF".format(padding_text))
        # user_package_name

        if has_multi_languages:
            install_entry_lines.append("ENDIF")

    # write install entry lines files
    for install_entry_filename in install_entry_lines_index.keys():
        install_entry_lines = install_entry_lines_index[install_entry_filename]

        install_entry_lines.append("")
        install_entry_lines.append("; end")
        install_entry_lines.append("LAB end")        

        install_entry_file = os.path.join(install_entries_dir, install_entry_filename)
        write_text_lines_for_amiga(install_entry_file, install_entry_lines)

    # write install entries file
    install_entries_lines = []
    index_names = install_entry_filename_index.keys()
    index_names.sort()
    for index_name in index_names:
        install_entries_lines.append("set entrydir \"`execute INSTALLDIR:S/CombinePath \"$INSTALLDIR\" \"{0}\"`\"".format(index_name))
        install_entries_lines.append("IF NOT EXISTS \"$entrydir\"")
        install_entries_lines.append("  MakePath \"$entrydir\" >NIL:")
        install_entries_lines.append("ENDIF")

        hardwares = install_entry_filename_index[index_name].keys()
        hardwares = sorted(hardwares, key=lambda hardware: hardware.lower())
        for hardware in hardwares:
            install_entries_lines.append("IF \"$entrieshardware{0}\" EQ 1 VAL".format(hardware))

            languages = install_entry_filename_index[index_name][hardware].keys()
            languages = sorted(languages, key=lambda language: language.lower())
            for language in languages:
                if re.search(r'multi', language, re.I):
                    install_entries_lines.append("  Execute \"USERPACKAGEDIR:{0}/{1}\"".format(user_package_path, install_entry_filename_index[index_name][hardware][language]))
                else:
                    install_entries_lines.append("  IF \"$entrieslanguage{0}\" EQ 1 VAL".format(language))
                    install_entries_lines.append("    echo \"*e[1mInstalling {0}, {1}, {2}...*e[0m\"".format(index_name, hardware.upper(), language.upper()))
                    install_entries_lines.append("    wait 1")
                    install_entries_lines.append("    Execute \"USERPACKAGEDIR:{0}/{1}\"".format(user_package_path, install_entry_filename_index[index_name][hardware][language]))
                    install_entries_lines.append("    IF \"$stopinstallation\" EQ 1 VAL".format(padding_text))
                    install_entries_lines.append("      SKIP end".format(padding_text))
                    install_entries_lines.append("    ENDIF".format(padding_text))
                    install_entries_lines.append("  ENDIF")
                
            install_entries_lines.append("ENDIF")
    
    install_entries_lines.append("")
    install_entries_lines.append("; end")
    install_entries_lines.append("LAB end")        

    install_entries_file = os.path.join(install_entries_dir, "Install-Entries")
    write_text_lines_for_amiga(install_entries_file, install_entries_lines)

# write entries list
def write_entries_list(entries_file, entries):
    """Write entries list"""
    with open(entries_file, 'wb') as csvfile:
        csvfile.write(codecs.BOM_UTF8)
        writer = csv.writer(csvfile, delimiter=str(u';'), quoting=csv.QUOTE_ALL)
        writer.writerow([
            "File",
            "UserPackageFile",
            "Name",
            "Id",
            "Hardware",
            "Language",
            "Memory",
            "Release",
            "PublisherDeveloper",
            "Other",
            "Version",
            "Unsupported",
            "BestVersionRank",
            "BestVersionLowMemRank"])
        for entry in entries:
            writer.writerow([
                entry.file_full_name.encode('utf-8'),
                entry.user_package_file.encode('utf-8'),
                entry.name.encode('utf-8'),
                ','.join(entry.entry_id).encode('utf-8'),
                ','.join(entry.hardware).encode('utf-8'),
                ','.join(entry.language).encode('utf-8'),
                ','.join(entry.memory).encode('utf-8'),
                ','.join(entry.release).encode('utf-8'),
                ','.join(entry.publisher_developer).encode('utf-8'),
                ','.join(entry.other).encode('utf-8'),
                ','.join(entry.version).encode('utf-8'),
                ','.join(entry.unsupported).encode('utf-8'),
                entry.best_version_rank,
                entry.best_version_lowmem_rank])


# write build install entries title
print("---------------------")
print("Build Install Entries")
print("---------------------")
print("Author: Henrik Noerfjand Stengaard")
print("Date: 2019-06-26")
print("")

# print usage and exit, if arguments are not defined
if len(argv) <= 1:
    print("Usage: %s \"[PATH]\"" % argv[0])
    exit(1)

# get user packages directory argument
user_packages_dir = argv[1].strip()

# fail, if user packages directory doesn't exist
if not os.path.isdir(user_packages_dir):
    print("User packages directory '{0}' doesn't exist".format(user_packages_dir))
    exit(1)

# write user packages directory
print("User packages directory: '{0}'".format(user_packages_dir))
print("")
print("Building install scripts for user package directories:")

# find user package directories
dirs = [os.path.join(user_packages_dir, o) for o in os.listdir(user_packages_dir)]
user_package_dirs = [x for x in dirs if os.path.isfile(os.path.join(x,'_installdir'))]

# exit, if no user package directories was found
if len(user_package_dirs) == 0:
    print("No user package directories was not found!")
    exit(0)

# unlzx file
unlzx_file = os.path.join(user_packages_dir, 'unlzx')

# build install entries for user package directories
for user_package_dir in user_package_dirs:
    # get user package name
    user_package_name = os.path.basename(user_package_dir)
    print(user_package_name)
    print("- Finding entries...")

    # find entries in user package directory
    entries = find_entries(user_package_dir)
    print("- Found {0} entries".format(len(entries)))

    # skip user package directory, if it's doesnt contain any entries
    if len(entries) == 0:
        continue

    # copy unlzx to user package directory, if unlzx file exists
    if os.path.isfile(unlzx_file):
        user_package_unlzx_file = os.path.join(user_package_dir, 'unlzx')
        shutil.copyfile(unlzx_file, user_package_unlzx_file)

    # build install entries in user package directory
    print("- Building install entries...")

    # build best versions
    entries_best_version = build_entries_best_version(entries, False)
    entries_best_version_lowmem = build_entries_best_version(entries, True)

    # entries sets
    entries_sets = []

    entries_set_all = EntriesSet()
    entries_set_all.name = 'All'
    entries_set_all.description = 'Install all entries.'
    entries_set_all.entries = entries
    entries_sets.append(entries_set_all)

    entries_set_best_version = EntriesSet()
    entries_set_best_version.name = 'Best-Version'
    entries_set_best_version.description = 'Install best version of identical entries.'
    entries_set_best_version.entries = entries_best_version
    entries_sets.append(entries_set_best_version)

    entries_set_best_version_lowmem = EntriesSet()
    entries_set_best_version_lowmem.name = 'Best-Version-Lowmem'
    entries_set_best_version_lowmem.description = 'Install best version of identical entries for low mem Amigas.'
    entries_set_best_version_lowmem.entries = entries_best_version_lowmem
    entries_sets.append(entries_set_best_version_lowmem)

    # build user package install
    build_user_package_install(entries_sets, user_package_name, user_package_dir)

    # create user package install directory, if it doesn't exist
    user_package_install_dir = os.path.join(user_package_dir, "Install")
    if not os.path.isdir(user_package_install_dir):
        os.makedirs(user_package_install_dir)

    # build install entries for entries sets
    for entries_set in entries_sets:
        # create install entries directory, if it doesn't exist
        install_entries_dir = os.path.join(user_package_install_dir, entries_set.name)
        if not os.path.isdir(install_entries_dir):
            os.makedirs(install_entries_dir)

        # build install entries
        build_install_entries(user_package_name, entries_set.entries, "Install/{0}".format(entries_set.name), install_entries_dir)

        # write entries list
        entries_list_file = os.path.join(user_package_dir, "entries-{0}.csv".format(entries_set.name.lower()))
        write_entries_list(entries_list_file, entries_set.entries)

    print("- Done.")
