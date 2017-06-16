"""HstWB Installer Setup"""

# colorama installation
# ----------------------
# 1. sudo apt install python-pip.
# 2. pip install colorama

import os
import hashlib
import csv
from subprocess import Popen, PIPE
from sys import platform as _platform
from colorama import init, Style, Fore

def cls():
    """Clear screen"""
    os.system('cls' if os.name == 'nt' else 'clear')

def folder_dialog():
    """Show folder dialog"""
    if _platform == "linux" or _platform == "linux2":
        print "show linux dialog"
        cmd = ["/bin/bash", "./dialogs/linux_dialog.sh", "folder_dialog", "Select directory", ""]
        proc = Popen(cmd, stdout=PIPE)
        proc.wait()
        print "PATH=" + proc.stdout.read().strip()
    elif _platform == "darwin":
        print "show mac dialog"
    elif _platform == "win32":
        print "show windows dialog"
        cmd = "powershell -ExecutionPolicy Bypass -File \"dialogs\\win32_dialog.ps1\"" + \
            " -folderDialog -title \"Select directory\""
        proc = Popen(cmd, stdout=PIPE)
        proc.wait()
        print "PATH=" + proc.stdout.read().strip()

def calculate_md5_from_file(fname):
    """Calculate MD5 from file"""
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as _f:
        for chunk in iter(lambda: _f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def read_csv_file(fname):
    """Read CSV File"""
    reader = csv.DictReader(open(fname, 'rb'), delimiter=';', quotechar='"')
    rows = []
    for line in reader:
        rows.append(line)
    return rows

# clear screen
cls()

init()

print Style.BRIGHT + Fore.YELLOW + '----------------------------'
print 'HstWB Installer Setup v1.1.0'
print '----------------------------'
print Style.RESET_ALL

#folder_dialog()
print calculate_md5_from_file(
    'c:\\Users\\Public\\Documents\\Amiga Files\\Shared\\rom\\amiga-os-310-a1200.rom')

kickstartRomHashes = read_csv_file('kickstart\\kickstart-rom-hashes.csv') # pylint: disable=invalid-name

print kickstartRomHashes[0]['Name']
