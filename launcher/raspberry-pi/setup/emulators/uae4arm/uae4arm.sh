#!/bin/bash

# Setup UAE4ARM
# -------------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-13
#
# bash script to show setup uae4arm menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup UAE4ARM" \
	--menu "Select option:" 0 0 0 \
	1 "Install UAE4ARM" \
        2 "Run UAE4ARM emulator" \
	3 "Disable UAE4ARM autostart" \
	4 "Exit")

	clear

	# exit, if cancelled
	if [ -z $choices ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			./install-uae4arm.sh
			;;
		2)
			./run-uae4arm-emulator.sh
			;;
                3)
                        ./disable-uae4arm-autostart.sh
                        ;;
		4)
			exit
			;;
		esac
	done
done
