#!/bin/bash

# Setup FS-UAE
# ------------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-26
#
# bash script to show setup fs-uae menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup FS-UAE" \
	--menu "Select option:" 0 0 0 \
        1 "Run FS-UAE emulator" \
	2 "Install FS-UAE" \
        3 "Select FS-UAE autostart" \
	4 "Disable FS-UAE autostart" \
	5 "Exit")

	clear

	# exit, if cancelled
	if [ -z $choices ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
                1)
                        ./run-fs-uae-emulator.sh
                        ;;
		2)
			./install-fs-uae.sh
			;;
		3)
			./select-fs-uae-autostart.sh
			;;
                4)
                        ./disable-fs-uae-autostart.sh
                        ;;
		5)
			exit
			;;
		esac
	done
done
