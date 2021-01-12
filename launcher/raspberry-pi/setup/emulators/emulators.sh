#!/bin/bash

# Setup Emulators
# ---------------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-12
#
# bash script to show setup emulators menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup Emulators" \
	--menu "Select option:" 0 0 0 \
	1 "Change Amiga emulator" \
        2 "Amiberry" \
	3 "UAE4ARM" \
	4 "Install Kickstart rom" \
	5 "Exit")

	clear

	# exit, if cancelled
	if [ -z $choices ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			./change-amiga-emulator.sh
			;;
		2)
                        pushd amiberry >/dev/null
                        ./amiberry.sh
                        popd >/dev/null
			;;
                3)
                        pushd uae4arm >/dev/null
                        ./uae4arm.sh
                        popd >/dev/null
                        ;;
		4)
			./install-kickstart-rom.sh
			;;
		5)
			exit
			;;
		esac
	done
done
