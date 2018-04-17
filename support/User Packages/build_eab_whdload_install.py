#!/usr/local/bin/python
# -*- coding: utf-8 -*-

# Build EAB WHDLoad Install
# -------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-04-18
#
# A python script to build EAB WHDLoad Packs install script for HstWB Installer user packages.


"""Build EAB WHDLoad Install"""

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

# eab whdload entry
class EabWhdloadEntry:
    eab_whdload_file = ""
    language = ""
    hardware = ""

# write text lines for amiga
def write_text_lines_for_amiga(path, lines):
    """Write Text Lines for Amiga"""
    with codecs.open(path, "w", "iso-8859-1") as f:
        for l in lines:
            f.write(unicodedata.normalize('NFC', l)+"\n")

# find eab whdload entries
def find_eab_whdload_entries(eab_whdload_pack_dir):
    """Find EAB WHDLoad Entries"""

    eab_whdload_pack_dir_index = len(eab_whdload_pack_dir) + 1
    eab_whdload_entries = []

    for root, directories, filenames in os.walk(unicode(eab_whdload_pack_dir, 'utf-8')):
        for filename in filenames:
            # skip, if filename doesn't end with .lha or .lzx
            if not (filename.endswith(".lha") or filename.endswith(".lzx")):
                continue

            file_full_name = os.path.join(root, filename)
            eab_whdload_file = file_full_name[eab_whdload_pack_dir_index : len(file_full_name)]

            # detect language
            language = "en"
            language_match = re.search(
                r'_(de|fr|it|se|pl|es|cz|dk|fi|gr|cv)(_|\.)', filename, re.M|re.I)
            if language_match:
                language = language_match.group(1).lower()

            # detect hardware
            hardware = "ocs"
            hardware_match = re.search(
                r'_(aga|cd32|cdtv)(_|\.)', filename, re.M|re.I)
            if hardware_match:
                hardware = hardware_match.group(1).lower()

            # add eab whdload entry
            eab_whdload_entry = EabWhdloadEntry()
            eab_whdload_entry.eab_whdload_file = eab_whdload_file
            eab_whdload_entry.language = language
            eab_whdload_entry.hardware = hardware
            eab_whdload_entries.append(eab_whdload_entry)

    # sort eab whdload entries
    sorted(eab_whdload_entries, key=lambda entry: entry.eab_whdload_file)
    
    return eab_whdload_entries

# build eab whdload install
def build_eab_whdload_install(title, eab_whdload_entries, eab_whdload_pack_dir):
    """Build EAB Whdload Install"""

    # build hardware and language indexes
    hardware_index = {}
    language_index = {}
    for eab_whdload_entry in eab_whdload_entries:
        hardware = eab_whdload_entry.hardware
        language = eab_whdload_entry.language

        if hardware in hardware_index:
            hardware_index[hardware] += 1
        else:
            hardware_index[hardware] = 1

        if not language in language_index:
            language_index[language] = {}

        if hardware in language_index[language]:
            language_index[language][hardware] += 1
        else:
            language_index[language][hardware] = 1

    # get hardwares and languages sorted
    hardwares = hardware_index.keys()
    hardwares.sort()
    languages = language_index.keys()
    languages.sort()

    # build eab whdload install lines
    eab_whdload_install_lines = []
    eab_whdload_install_lines.append("; {0}".format(title))
    eab_whdload_install_lines.append(("; {0}".format("-" * len(title))))
    eab_whdload_install_lines.append("; Author: Henrik Noerfjand Stengaard")
    eab_whdload_install_lines.append("; Date: {0}".format(datetime.date.today().strftime('%Y-%m-%d')))
    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("; An AmigaDOS script for installing EAB WHDLoad pack '{0}'".format(title))
    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("; Patch for HstWB Installer without unlzx")
    eab_whdload_install_lines.append("IF NOT EXISTS \"SYS:C/unlzx\"")
    eab_whdload_install_lines.append("  IF EXISTS \"USERPACKAGEDIR:unlzx\"")
    eab_whdload_install_lines.append("    Copy \"USERPACKAGEDIR:unlzx\" \"SYS:C/unlzx\" >NIL:")
    eab_whdload_install_lines.append("  ENDIF")
    eab_whdload_install_lines.append("ENDIF")
    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("; reset")

    for hardware in hardwares:
        eab_whdload_install_lines.append("set eabhardware{0} \"1\"".format(hardware))

    for language in languages:
        eab_whdload_install_lines.append("set eablanguage{0} \"1\"".format(language))

    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("; eab whdload menu")
    eab_whdload_install_lines.append("LAB eabwhdloadmenu")
    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("set totalcount \"0\"")
    eab_whdload_install_lines.append("echo \"\" NOLINE >T:_eabwhdloadmenu")

    for hardware in hardwares:
        eab_whdload_install_lines.append("")
        eab_whdload_install_lines.append("; '{0}' hardware menu".format(hardware))
        eab_whdload_install_lines.append("IF \"$eabhardware{0}\" EQ 1 VAL".format(hardware))
        eab_whdload_install_lines.append("  echo \"Install\" NOLINE >>T:_eabwhdloadmenu")
        eab_whdload_install_lines.append("ELSE")
        eab_whdload_install_lines.append("  echo \"Skip   \" NOLINE >>T:_eabwhdloadmenu")
        eab_whdload_install_lines.append("ENDIF")
        eab_whdload_install_lines.append(("echo \" : {0} hardware ({1} entries)\" >>T:_eabwhdloadmenu".format(hardware.upper(), hardware_index[hardware])))

    eab_whdload_install_lines.append("echo \"----------------------------------------\" >>T:_eabwhdloadmenu")

    for language in languages:
        eab_whdload_install_lines.append("")
        eab_whdload_install_lines.append("; '{0}' language menu".format(language))
        eab_whdload_install_lines.append("set languagecount \"0\"")

        language_hardwares = language_index[language].keys()
        language_hardwares.sort()
        for hardware in language_hardwares:
            eab_whdload_install_lines.append("IF \"$eabhardware{0}\" EQ 1 VAL".format(hardware))
            eab_whdload_install_lines.append("  set languagecount `eval $languagecount + {0}`".format(language_index[language][hardware]))
            eab_whdload_install_lines.append("ENDIF")

        eab_whdload_install_lines.append("IF \"$eablanguage{0}\" EQ 1 VAL".format(language))
        eab_whdload_install_lines.append("  set totalcount `eval $totalcount + $languagecount`")
        eab_whdload_install_lines.append("  echo \"Install\" NOLINE >>T:_eabwhdloadmenu")
        eab_whdload_install_lines.append("ELSE")
        eab_whdload_install_lines.append("  echo \"Skip   \" NOLINE >>T:_eabwhdloadmenu")
        eab_whdload_install_lines.append("ENDIF")
        eab_whdload_install_lines.append("echo \" : {0} language ($languagecount entries)\" >>T:_eabwhdloadmenu".format(language.upper()))

    eab_whdload_install_lines.append("echo \"----------------------------------------\" >>T:_eabwhdloadmenu")
    eab_whdload_install_lines.append("echo \"Install $totalcount of {0} entries\" >>T:_eabwhdloadmenu".format(len(eab_whdload_entries)))
    eab_whdload_install_lines.append("echo \"Skip all entries\" >>T:_eabwhdloadmenu")
    
    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("set eabwhdloadoption \"\"")
    eab_whdload_install_lines.append("set eabwhdloadoption `RequestList TITLE=\"{0}\" LISTFILE=\"T:_eabwhdloadmenu\" WIDTH=640 LINES=24`".format(title))
    eab_whdload_install_lines.append("delete >NIL: T:_eabwhdloadmenu")

    eab_whdload_option = 0

    for hardware in hardwares:
        eab_whdload_option += 1

        eab_whdload_install_lines.append("")
        eab_whdload_install_lines.append("; '{0}' hardware option".format(hardware))
        eab_whdload_install_lines.append("IF \"$eabwhdloadoption\" EQ {0} VAL".format(eab_whdload_option))
        eab_whdload_install_lines.append("  IF \"$eabhardware{0}\" EQ 1 VAL".format(hardware))
        eab_whdload_install_lines.append("    set eabhardware{0} \"0\"".format(hardware))
        eab_whdload_install_lines.append("  ELSE")
        eab_whdload_install_lines.append("    set eabhardware{0} \"1\"".format(hardware))
        eab_whdload_install_lines.append("  ENDIF")
        eab_whdload_install_lines.append("  SKIP BACK eabwhdloadmenu")
        eab_whdload_install_lines.append("ENDIF")

    eab_whdload_option += 1
    
    for language in languages:
        eab_whdload_option += 1

        eab_whdload_install_lines.append("")
        eab_whdload_install_lines.append("; '{0}' language option".format(language))
        eab_whdload_install_lines.append("IF \"$eabwhdloadoption\" EQ {0} VAL".format(eab_whdload_option))
        eab_whdload_install_lines.append("  IF \"$eablanguage{0}\" EQ 1 VAL".format(language))
        eab_whdload_install_lines.append("    set eablanguage{0} \"0\"".format(language))
        eab_whdload_install_lines.append("  ELSE")
        eab_whdload_install_lines.append("    set eablanguage{0} \"1\"".format(language))
        eab_whdload_install_lines.append("  ENDIF")
        eab_whdload_install_lines.append("  SKIP BACK eabwhdloadmenu")
        eab_whdload_install_lines.append("ENDIF")

    eab_whdload_option += 2

    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("; install entries option")
    eab_whdload_install_lines.append("IF \"$eabwhdloadoption\" EQ {0} VAL".format(eab_whdload_option))
    eab_whdload_install_lines.append("  set confirm `RequestChoice \"Install EAB WHDLoad\" \"Do you want to install $totalcount EAB EHDLoad entries?\" \"Yes|No\"`")
    eab_whdload_install_lines.append("  IF \"$confirm\" EQ \"1\"")
    eab_whdload_install_lines.append("    SKIP installentries")
    eab_whdload_install_lines.append("  ENDIF")
    eab_whdload_install_lines.append("ENDIF")

    eab_whdload_option += 1

    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("; skip all entries option")
    eab_whdload_install_lines.append("IF \"$eabwhdloadoption\" EQ {0} VAL".format(eab_whdload_option))
    eab_whdload_install_lines.append("  set confirm `RequestChoice \"Skip all entries\" \"Do you want to skip all entries?\" \"Yes|No\"`")
    eab_whdload_install_lines.append("  IF \"$confirm\" EQ \"1\"")
    eab_whdload_install_lines.append("    SKIP end")
    eab_whdload_install_lines.append("  ENDIF")
    eab_whdload_install_lines.append("ENDIF")
    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("SKIP BACK eabwhdloadmenu")
    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("; install entries")
    eab_whdload_install_lines.append("LAB installentries")
    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("execute \"USERPACKAGEDIR:Install/Install-Entries\"")
    eab_whdload_install_lines.append("")
    eab_whdload_install_lines.append("; End")
    eab_whdload_install_lines.append("; ---")
    eab_whdload_install_lines.append("LAB end")

    # write eab whdload install file
    eab_whdload_install_file = os.path.join(eab_whdload_pack_dir, "_install")
    write_text_lines_for_amiga(eab_whdload_install_file, eab_whdload_install_lines)

    # create eab whdload pack install directory, if it doesn't exist
    eab_whdload_install_dir = os.path.join(eab_whdload_pack_dir, "Install")
    if not os.path.isdir(eab_whdload_install_dir):
        os.makedirs(eab_whdload_install_dir)

    # create eab whdload install entries directory, if it doesn't exist
    eab_whdload_install_entries_dir = os.path.join(eab_whdload_install_dir, "Entries")
    if not os.path.isdir(eab_whdload_install_entries_dir):
        os.makedirs(eab_whdload_install_entries_dir)

    # build eab whdload install entry and file indexes
    eab_whdload_install_entry_index = {}
    eab_whdload_install_entry_file_index = {}
    for eab_whdload_entry in eab_whdload_entries:
        index_name = eab_whdload_entry.eab_whdload_file[0:1].upper()
        hardware = eab_whdload_entry.hardware
        language = eab_whdload_entry.language

        if re.search(r'^(#|\d)', index_name, re.I):
            index_name = "0-9"
        
        eab_whdload_install_entry_file = "{0}-{1}-{2}".format(index_name, hardware.upper(), language.upper())

        if not index_name in eab_whdload_install_entry_index:
            eab_whdload_install_entry_index[index_name] = {}

        if not hardware in eab_whdload_install_entry_index[index_name]:
            eab_whdload_install_entry_index[index_name][hardware] = {}

        if not language in eab_whdload_install_entry_index[index_name][hardware]:
            eab_whdload_install_entry_index[index_name][hardware][language] = eab_whdload_install_entry_file
        
        if not eab_whdload_install_entry_file in eab_whdload_install_entry_file_index:
            eab_whdload_install_entry_file_index[eab_whdload_install_entry_file] = []

        eab_whdload_install_entry_lines = eab_whdload_install_entry_file_index[eab_whdload_install_entry_file]
        
        # replace \ with / and espace # with '#
        eab_whdload_file = eab_whdload_entry.eab_whdload_file.replace("\\", "/").replace("#", "'#")

        # convert eab whdload file to unicode, if it's string type
        if isinstance(eab_whdload_file, str):
            eab_whdload_file = unicode(eab_whdload_file, 'utf-8', 'replace')

        eab_whdload_file = u"USERPACKAGEDIR:{0}".format(eab_whdload_file)
        eab_whdload_install_entry_lines.append(u"IF EXISTS \"{0}\"".format(eab_whdload_file))

        if re.search(r'\.lha$', eab_whdload_file, re.I):
            eab_whdload_install_entry_lines.append(u"  lha -q -m1 x \"{0}\" \"$entrydir/\"".format(eab_whdload_file))

        if re.search(r'\.lzx$', eab_whdload_file, re.I):
            eab_whdload_install_entry_lines.append(u"  unlzx -q1 -m e \"{0}\" \"$entrydir/\"".format(eab_whdload_file))

        eab_whdload_install_entry_lines.append("  IF NOT $RC EQ 0")
        eab_whdload_install_entry_lines.append(u"    echo \"Error: Failed to install entry file '{0}' to '$entrydir'\"".format(eab_whdload_file))
        eab_whdload_install_entry_lines.append("  ENDIF")
        eab_whdload_install_entry_lines.append("ENDIF")

    # write eab whdload install entry files
    for eab_whdload_install_entry_filename in eab_whdload_install_entry_file_index.keys():
        eab_whdload_install_entry_lines = eab_whdload_install_entry_file_index[eab_whdload_install_entry_filename]

        eab_whdload_install_entry_file = os.path.join(eab_whdload_install_entries_dir, eab_whdload_install_entry_filename)
        write_text_lines_for_amiga(eab_whdload_install_entry_file, eab_whdload_install_entry_lines)

    # write eab whdload install entries file
    eab_whdload_install_entries_lines = []
    index_names = eab_whdload_install_entry_index.keys()
    index_names.sort()
    for index_name in index_names:
        eab_whdload_install_entries_lines.append("echo \"Installing {0}...\"".format(index_name))
        eab_whdload_install_entries_lines.append("set entrydir \"`execute INSTALLDIR:S/CombinePath \"$INSTALLDIR\" \"{0}\"`\"".format(index_name))
        eab_whdload_install_entries_lines.append("IF NOT EXISTS \"$entrydir\"")
        eab_whdload_install_entries_lines.append("  MakePath \"$entrydir\" >NIL:")
        eab_whdload_install_entries_lines.append("ENDIF")

        hardwares = eab_whdload_install_entry_index[index_name].keys()
        hardwares.sort()
        for hardware in hardwares:
            eab_whdload_install_entries_lines.append("IF \"$eabhardware{0}\" EQ 1 VAL".format(hardware))

            languages = eab_whdload_install_entry_index[index_name][hardware].keys()
            languages.sort()
            for language in languages:
                eab_whdload_install_entries_lines.append("  IF \"$eablanguage{0}\" EQ 1 VAL".format(language))
                eab_whdload_install_entries_lines.append("    echo \"Installing {0}, {1}, {2}...\"".format(index_name, hardware.upper(), language.upper()))
                eab_whdload_install_entries_lines.append("    Execute \"USERPACKAGEDIR:Install/Entries/{0}\"".format(eab_whdload_install_entry_index[index_name][hardware][language]))
                eab_whdload_install_entries_lines.append("  ENDIF")
                
            eab_whdload_install_entries_lines.append("ENDIF")
    
    eab_whdload_install_entries_file = os.path.join(eab_whdload_install_dir, "Install-Entries")
    write_text_lines_for_amiga(eab_whdload_install_entries_file, eab_whdload_install_entries_lines)


# write build eab whdload install title
print("-------------------------")
print("Build EAB WHDLoad Install")
print("-------------------------")
print("Author: Henrik Noerfjand Stengaard")
print("Date: 2018-04-18")
print("")

# print usage and exit, if arguments are not defined
if len(argv) <= 1:
    print("Usage: %s \"[PATH]\"" % argv[0])
    exit(1)

# get eab whdload packs directory argument
eab_whdload_packs_dir = argv[1].strip()

# fail, if eab whdload packs directory doesn't exist
if not os.path.isdir(eab_whdload_packs_dir):
    print("EAB WHDLoad Packs directory '{0}' doesn't exist".format(eab_whdload_packs_dir))
    exit(1)

# write eab whdload packs directory
print("EAB WHDLoad Packs directory: '{0}'".format(eab_whdload_packs_dir))
print("")
print("Building EAB WHDLoad Install scripts for user package directories:")

# find eab whdload directories
eab_whdload_pack_dirs = [os.path.join(eab_whdload_packs_dir, o) for o in os.listdir(eab_whdload_packs_dir) 
    if os.path.isdir(os.path.join(eab_whdload_packs_dir,o)) and re.search("whdload", o, re.I)]

# exit, if eab whdload directories was not found
if len(eab_whdload_pack_dirs) == 0:
    print("No EAB WHDLoad Pack directories was not found!")
    exit(0)

# unlzx file
unlzx_file = os.path.join(eab_whdload_packs_dir, 'unlzx')

# build eab whdload install for eab whdload directories
for eab_whdload_pack_dir in eab_whdload_pack_dirs:
    eab_whdload_pack_name = os.path.basename(eab_whdload_pack_dir)

    # find eab whdload entries in eab whdload pack directory
    eab_whdload_entries = find_eab_whdload_entries(eab_whdload_pack_dir)
    print(eab_whdload_pack_name)
    print("- Found {0} entries".format(len(eab_whdload_entries)))

    # skip eab whdload pack, if it doesn't contain any entries
    if len(eab_whdload_entries) == 0:
        continue

    # copy unlzx to eab whdload pack directory, if unlzx file exists
    if os.path.isfile(unlzx_file):
        eab_whdload_pack_unlzx_file = os.path.join(eab_whdload_pack_dir, 'unlzx')
        shutil.copyfile(unlzx_file, eab_whdload_pack_unlzx_file)

    # build eab whdload install for eab whdload directory
    print("- Building EAB WHDLoad Install...")
    build_eab_whdload_install(eab_whdload_pack_name, eab_whdload_entries, eab_whdload_pack_dir)

    # write entries list
    eab_whdload_entries_file = os.path.join(eab_whdload_pack_dir, "entries.csv")
    with open(eab_whdload_entries_file, 'wb') as csvfile:
        csvfile.write(codecs.BOM_UTF8)
        writer = csv.writer(csvfile, delimiter=str(u';'), quoting=csv.QUOTE_ALL)
        writer.writerow(["File", "Hardware", "Language"])
        for eab_whdload_entry in eab_whdload_entries:
            writer.writerow([eab_whdload_entry.eab_whdload_file.encode('utf-8'), eab_whdload_entry.hardware, eab_whdload_entry.language])

    print("- Done.")
