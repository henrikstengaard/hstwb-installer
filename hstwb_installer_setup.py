# https://github.com/Chiel92/unicurses

# UniCurses Installation
# ----------------------
# 1. sudo apt install python-pip.
# 2. pip install https://sourceforge.net/projects/pyunicurses/files/unicurses-1.2/UniCurses-1.2.zip/download

# import unicurses
from unicurses import *

# initializes and clears standard screen
initscr()
clear()

if not has_colors():
    endwin()
    print "Your terminal does not support color!"
    exit(1)

start_color()
init_pair(1, COLOR_YELLOW, COLOR_BLACK)

attron(A_BOLD)
attron(COLOR_PAIR(1))
addstr('----------------------------\n')
addstr('HstWB Installer Setup v1.1.0\n')
addstr('----------------------------\n')
attroff(COLOR_PAIR(1))
attroff(A_BOLD)

refresh()
