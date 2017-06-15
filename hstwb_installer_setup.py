"""HstWB Installer Setup"""

# colorama installation
# ----------------------
# 1. sudo apt install python-pip.
# 2. pip install colorama

import os
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
        proc = Popen(
            "bash dialogs/linux_dialog.sh \"folder_dialog\" \"Select directory\" \"\"",
            stdout=PIPE)
        proc.wait()
        print "PATH=" + proc.stdout.read()
    elif _platform == "darwin":
        print "show mac dialog"
    elif _platform == "win32":
        print "show windows dialog"
        proc = Popen(
            "powershell -ExecutionPolicy Bypass -File dialogs\\win32_dialog.ps1" +
            " -folderDialog -title \"Select directory\"",
            stdout=PIPE)
        proc.wait()
        print "PATH=" + proc.stdout.read()

# clear screen
cls()

init()

print Style.BRIGHT + Fore.YELLOW + '----------------------------'
print Style.BRIGHT + Fore.YELLOW + 'HstWB Installer Setup v1.1.0'
print Style.BRIGHT + Fore.YELLOW + '----------------------------'

folder_dialog()
