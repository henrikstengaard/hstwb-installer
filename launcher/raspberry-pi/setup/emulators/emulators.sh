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
        1 "Amiberry" \
	2 "UAE4ARM" \
	3 "Install Kickstart rom" \
	4 "Exit")

	clear

	# exit, if cancelled
	if [ -z $choices ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
                        pushd amiberry >/dev/null
                        ./amiberry.sh
                        popd >/dev/null
			;;
                2)
                        pushd uae4arm >/dev/null
                        ./uae4arm.sh
                        popd >/dev/null
                        ;;
		3)
			./install-kickstart-rom.sh
			;;
		4)
			exit
			;;
		esac
	done
done
