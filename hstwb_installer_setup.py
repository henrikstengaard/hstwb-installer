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

# clear screen
cls()

init()

print Style.BRIGHT + Fore.YELLOW + '----------------------------\n'
print Style.BRIGHT + Fore.YELLOW + 'HstWB Installer Setup v1.1.0\n'
print Style.BRIGHT + Fore.YELLOW + '----------------------------\n'
