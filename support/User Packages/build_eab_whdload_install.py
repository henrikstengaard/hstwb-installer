#!/usr/local/bin/python
# -*- coding: utf-8 -*-

# Build EAB WHDLoad Install
# -------------------------
#
# Author: Henrik Noerfjand Stengaard
# Date:   2018-04-15
#
# A python script to build EAB WHDLoad Packs install script for HstWB Installer user packages.


"""Build EAB WHDLoad Install"""

from __future__ import print_function
import os
import re
import shutil
from sys import argv
import codecs

# eab whdload entry
class EabWhdloadEntry:
    eab_whdload_file = ""
    language = ""
    hardware = ""

# write text lines for amiga
def write_text_lines_for_amiga(path, lines):
    """Write Text Lines for Amiga"""
    f = codecs.open(path, "w", "ISO-8859-1")
    for l in lines:
        f.write(l+'\n')
    f.close()

# find eab whdload entries
def find_eab_whdload_entries(eab_whdload_pack_dir):
    """Find EAB WHDLoad Entries"""

    eab_whdload_pack_dir_index = len(eab_whdload_pack_dir) + 1
    eab_whdload_entries = []

    for root, directories, filenames in os.walk(eab_whdload_pack_dir):
        for filename in filenames:
            # skip, if filename doesn't end with .lha or .lzx
            if not (filename.endswith(".lha") or filename.endswith(".lzx")):
                continue

            # get eab whdload file
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


# write build eab whdload install title
print("-------------------------")
print("Build EAB WHDLoad Install")
print("-------------------------")
print("Author: Henrik Noerfjand Stengaard")
print("Date: 2018-04-15")
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

print("EAB WHDLoad Packs directory: '{0}'".format(eab_whdload_packs_dir))
print("")
print("Building EAB WHDLoad Install scripts for user package directories:")

# find eab whdload directories
eab_whdload_pack_dirs = [os.path.join(eab_whdload_packs_dir, o) for o in os.listdir(eab_whdload_packs_dir) 
    if os.path.isdir(os.path.join(eab_whdload_packs_dir,o)) and re.search("whdload", o, re.I)]

# exit, if eab whdload directories was not found
if len(eab_whdload_pack_dirs) == 0:
    print("EAB WHDLoad Packs directories was not found!")
    exit(0)

# unlzx file
unlzx_file = os.path.join(eab_whdload_packs_dir, 'unlzx')

# build eab whdload install for eab whdload directories
for eab_whdload_pack_dir in eab_whdload_pack_dirs:
    print("- '{0}'".format(eab_whdload_pack_dir))

    # find eab whdload entries in eab whdload pack directory
    eab_whdload_entries = find_eab_whdload_entries(eab_whdload_pack_dir)
    print("  Found '{0}' entries".format(len(eab_whdload_entries)))

    # skip eab whdload pack, if it doesn't contain any entries
    if len(eab_whdload_entries) == 0:
        continue

    print("  Building EAB WHDLoad Install...")
    print("  Done.")

# get eab whdload pack directories
# $eabWhdLoadPackDirs = @()
# $eabWhdLoadPackDirs += Get-ChildItem -Path $eabWhdLoadPacksDir | `
#     Where-Object { $_.PSIsContainer -and $_ -match 'whdload' }

# $unlzxFile = Join-Path $eabWhdLoadPacksDir -ChildPath 'unlzx'


# lines = []
# lines.append(u'á')
# lines.append(u'amiga text here')
# lines.append(u'test')
#write_text_lines_for_amiga('amiga', lines)

