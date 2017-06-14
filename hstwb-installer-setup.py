# import unicurses
from unicurses import *

# initializes and clear standard screen
stdscr = initscr()
clear()

if has_colors() == False:
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
