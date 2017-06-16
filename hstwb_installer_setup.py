"""HstWB Installer Setup"""

# colorama installation
# ----------------------
# 1. sudo apt install python-pip.
# 2. pip install colorama

import os
from subprocess import Popen, PIPE
from sys import platform as _platform
from colorama import init, Style, Fore
from modules import hstwbinstallerdata

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

# clear screen
cls()

init()

print Style.BRIGHT + Fore.YELLOW + '----------------------------'
print 'HstWB Installer Setup v1.1.0'
print '----------------------------'
print Style.RESET_ALL

#folder_dialog()
print hstwbinstallerdata.calculate_md5_from_file(
    'c:\\Users\\Public\\Documents\\Amiga Files\\Shared\\rom\\amiga-os-310-a1200.rom')

kickstartRomHashes = hstwbinstallerdata.read_csv_file('kickstart\\kickstart-rom-hashes.csv') # pylint: disable=invalid-name

print kickstartRomHashes[0]['Name']
