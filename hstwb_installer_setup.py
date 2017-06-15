"""HstWB Installer Setup"""

# colorama installation
# ----------------------
# 1. sudo apt install python-pip.
# 2. pip install colorama

import os
from colorama import init, Style, Fore

def cls():
    """Clear screen"""
    os.system('cls' if os.name == 'nt' else 'clear')

def folder_browser_dialog():
    """Show folder browser dialog"""
    print os.name

# clear screen
cls()

init()

print Style.BRIGHT + Fore.YELLOW + '----------------------------'
print Style.BRIGHT + Fore.YELLOW + 'HstWB Installer Setup v1.1.0'
print Style.BRIGHT + Fore.YELLOW + '----------------------------'

folder_browser_dialog()
