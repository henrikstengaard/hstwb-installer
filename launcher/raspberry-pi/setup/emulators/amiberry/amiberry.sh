#!/bin/bash

# Setup Amiberry
# --------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-13
#
# bash script to show setup amiberry menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup Amiberry" \
	--menu "Select option:" 0 0 0 \
	1 "Install SDL2" \
	2 "Install Amiberry" \
        3 "Run Amiberry emulator" \
	4 "Disable Amiberry autostart" \
	5 "Exit")

	clear

	# exit, if cancelled
	if [ -z $choices ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
                1)
                        ./install-sdl2.sh
                        ;;
		2)
			./install-amiberry.sh
			;;
                3)
                        ./run-amiberry-emulator.sh
                        ;;
		4)
			./disable-amiberry-autostart.sh
			;;
		5)
			exit
			;;
		esac
	done
done
